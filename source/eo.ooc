/* eo.ooc */

import io/File
import structs/[ArrayList, HashMap, Stack]
import text/[EscapeSequence, Regexp, StringTokenizer]
import patch
import namespace, eotypes, stackstack
import builtins

EO_VERSION := "0.0.40"

/*****/

/* XXX there can be interpreter settings as well... is there a clear
 * difference between debug settings and interpreter settings? If not, we can
 * just use the same class. Or a dictionary... */
DebugSettings: class {
    showCallStack := false
    countCycles := false

    cycles := 0  /* will be incremented if countCycles is true */

    init: func
}

// comment | string | word
re_word := Regexp compile("(--.*?(\\n|$))|(\"(?:\\\\\"|[^\"])*?\")|(\\S+)")
/* Fixed string regex; see: http://stackoverflow.com/a/18551774/27426
*/

tokenize: func (data: String) -> ArrayList<String> {
    results := re_word split(data)
    return results filter(|token| !(token startsWith?("--"))) as ArrayList<String>
}

expandMacros: func (tokens: ArrayList<String>) -> ArrayList<String> {
    newTokens := ArrayList<String> new()
    for (token in tokens) {
        if (token startsWith?("\"") && token endsWith?("\"")) {
            /* we don't need to inspect strings */
            newTokens add(token)
        }
        else if (token startsWith?("!$") && token length() > 2) {
            newTokens add("\"%s\"" format(token substring(1)))
            newTokens add("defvar")
        }
        else if (token startsWith?("!>$") && token length() > 3) {
            newTokens add("\"%s\"" format(token substring(2)))
            newTokens add("update")
        }
        else if (token startsWith?("!") && token length() > 1) {
            newTokens add("\"%s\"" format(token substring(1)))
            newTokens add("def")
        }
        else if (token contains?(":") && !(token startsWith?(":")) \
                 && !(token endsWith?(":")) && !(token startsWith?("\""))) {
            /* split foo:bar and replace with `foo "bar" execns` */
            parts := token split(":")
            newTokens add(parts[0])
            for (part in parts[1..-1]) {
                newTokens add("\"%s\"" format(part))
                newTokens add("execns")
            }
        }
        else if (token startsWith?("\\") && token length() > 1) {
            newTokens add("\"%s\"" format(token substring(1)))
            newTokens add("lookup-here")
        }
        else if (token indexOf("\\") > 0 && 
                 token indexOf("\\") < token length() - 1 &&
                 !token startsWith?("\"")) {
            parts := token split("\\")
            assert (parts size == 2)
            newTokens add("\"%s\"" format(parts[0]))
            newTokens add("lookup-here")
            newTokens add("swap")
            newTokens add(parts[1])
        }
        else if (token startsWith?("?") && token length() > 1) {
            newTokens add("\"%s\"" format(token substring(1)))
            newTokens add("lookup-here")
            newTokens add("doc")
            newTokens add("println")
        }
        else
            newTokens add(token)
    }
    return newTokens
}

/* NOTE: Regular expressions must match the whole token, not part of it;
 * therefore they should start with '^' and end with '$'. */
re_number := Regexp compile("^-?\\d+$")
re_hex_number := Regexp compile("^-?0[xX][0-9a-fA-F]+$")
re_octal_number := Regexp compile("^-?0[oO][0-7]+$")
re_binary_number := Regexp compile("^-?0[bB][01]+$")

parseToken: func(token: String) -> EoType {
    if (re_number matches(token)) {
        return EoInteger new(token toInt())
    }
    if (re_hex_number matches(token)) {
        return EoInteger fromHexString(token)
    }
    if (re_octal_number matches(token)) {
        return EoInteger fromOctalString(token)
    }
    if (re_binary_number matches(token))
        return EoInteger fromBinaryString(token)
    if (token startsWith?("\"") && token endsWith?("\"")) {
        s := EscapeSequence unescape(token[1..-2])
        return EoString new(s)
        /* NOTE: ooc slicing != Python slicing. */
    }
    /* true and false are special symbols that evaluate to themselves */
    if (token == "true") return EoTrue
    if (token == "false") return EoFalse

    return EoSymbol new(token)
    /* NOTE: symbols include variables. */
}

EoStackFrame: class {
    /* called EoStackFrame so it doesn't collide with ooc's built-in
     * StackFrame. */
    code: EoType
    counter := 0
    namespace: Namespace
    init: func (=code, =namespace)
}

EoInterpreter: class {
    stack := StackStack new()
    rootNamespace := Namespace new()
    userNamespace := Namespace new(rootNamespace)
    debugSettings := DebugSettings new()

    rootDir := "."
    /* can/must be overridden to contain the directory where the executable
       is located */
    libRootDir := rootDir + "/lib" 

    /* stack to deal with nested word definitions */
    currentWordStack := Stack<ArrayList<EoType>> new()

    /* call stack to execute code */
    callStack := Stack<EoStackFrame> new()
    _oldStderr: FStream

    init: func {
        /* redirect ooc's borked stderr */
        _oldStderr = stderr
        stderr = FStream open("/dev/null", "w")

        /* if we have a fully qualified root dir (and we should), determine
         * the stdlib dir */
        libRootDir = File join(rootDir, "lib")

        clear()
        /* true and false are special names that evaluate to themselves */
        rootNamespace add("true", EoTrue)
        rootNamespace add("false", EoFalse)
        loadBuiltinWords(this)
        autoload()
    }

    init: func ~withRoot (=rootDir) {
        init()
    }

    parse: func (data: String) -> Bool {
        // NOTE: assumes that currentWordStack is non-empty.
        tokens := tokenize(data)
        tokens = expandMacros(tokens)
        for (token in tokens) {
            match (token) {
                case "{" =>
                    currentWordStack push(ArrayList<EoType> new())
                case "}" =>
                    code: ArrayList<EoType> = currentWordStack pop()
                    blk := EoCodeBlock new(code)
                    currentWordStack peek() add(blk)
                    /* namespace is added later, when the code block goes on
                     * the stack */
                case =>
                    x := parseToken(token)
                    currentWordStack peek() add(x)
            }
        }
        /* if the stack has more than 1 list on it, we're still inside a word
         * definition. */
        return currentWordStack size == 1  /* done? */
    }

    /*** execution using call stack ***/

    executeStep: func {
        if (debugSettings countCycles)
            debugSettings cycles += 1
        if (debugSettings showCallStack)
            showCallStack()
        frame := callStack peek()
        match (frame code) {
            case sym: EoSymbol =>
                value := frame namespace lookup(sym value)
                /* the value found must be a variable or a word */
                callStack pop()  /* always remove in this case */
                match (value) {
                    case null =>
                        Exception new("Symbol not found: %s" \
                          format(sym toString())) throw()
                    /* NOTE: anything in this block should be an "executable",
                     * i.e. a word or a variable. */
                    case (v: EoVariable) =>
                        stack push(v value)
                    case (bw: EoBuiltinWord) =>
                        /* does not need to go on the call stack; built-in
                         * words are (expected to be) atomic, and if they're
                         * not, they can manipulate the call stack themselves.
                         * */
                        bw f(this, frame namespace)
                    case (uw: EoUserDefWord) =>
                        /* user-defined words go on the call stack. */
                        newFrame := EoStackFrame new(uw, frame namespace)
                        /* not sure about the namespace... */
                        callStack push(newFrame)
                    case =>
                        "Symbol cannot be executed: %s with value %s" \
                         printfln(frame code class name, frame code toString())
                }
            case blk: EoCodeBlock =>
                /* every time we process a code block via the call stack, we
                 * create a fresh copy and push that, to avoid having the same
                 * namespace every time */
                newblk := blk clone()
                newns := Namespace new(frame namespace)
                newblk namespace = newns
                stack push(newblk)
                callStack pop()
            case bw: EoBuiltinWord =>
                /* REDUNDANT? yet this will execute things like `str:upper` */
                callStack pop()
                bw f(this, frame namespace)  /* is this the right namespace? */
            case v: EoVariable =>  // XXX EXPERIMENTAL
                callStack pop()
                stack push(v value)
            case uw: EoUserDefWord =>
                /* next step in executing user-defined word */
                if (frame counter >= uw code words size)
                    callStack pop()  /* done */
                    /* ^ does this still happen? */
                else {
                    /* if we are at the last instruction of the code, we can
                     * remove the existing top frame (tail call optimization)
                     * to prevent the call stack from growing too much when
                     * recursion is used. */
                    if (frame counter >= uw code words size - 1)
                        callStack pop()  /* TCO */
                    wordTBE := uw code words[frame counter]
                    frame counter += 1
                    newFrame := EoStackFrame new(wordTBE, uw code namespace)
                    callStack push(newFrame)
                }
            case =>
                stack push(frame code)
                callStack pop()
        }
    }

    executeAll: func {
        if (debugSettings countCycles)
            debugSettings cycles = 0
        while (!(callStack empty?())) {
            try {
                executeStep()
            } catch (e: Exception) {
                "Error: %s" printfln(e message)
                callStack clear()
                return
            }
        }
        if (debugSettings countCycles)
            "Cycles: %d" printfln(debugSettings cycles)
    }

    /***/

    /* DEPRECATED -- run code directly. */
    runCode: func (data: String, ns: Namespace) {
        // make sure currentWordStack is not empty
        if (currentWordStack empty?())
            currentWordStack push(ArrayList<EoType> new())

        done := parse(data)
        if (done) {
            code: ArrayList<EoType> = currentWordStack pop()
            for (c in code) {
                frame := EoStackFrame new(c, ns)
                callStack push(frame)
                executeAll()
            }
            clear()
        }
        else Exception new("Error: Incomplete code!") throw()
    }

    /* run code by putting it on the call stack and letting the interpreter do
     * its work when execute() is called. */
    runCodeViaStack: func (data: String, ns: Namespace) {
        // make sure currentWordStack is not empty
        if (currentWordStack empty?())
            currentWordStack push(ArrayList<EoType> new())

        done := parse(data)
        if (done) {
            code: ArrayList<EoType> = currentWordStack pop()
            blk := EoCodeBlock new(code, ns)
            uw := blk asEoUserDefWord()
            frame := EoStackFrame new(uw, ns)
            callStack push(frame)
            clear()
        }
        else Exception new("Error: Incomplete code!") throw()
    }

    autoload: func {
        /* look for autoload/autoload.eo and load it. any other files should
           be loaded by autoload.eo itself. */
        autoloadfile := File join(rootDir, "autoload", "autoload.eo")
        "Loading: %s... " printf(autoloadfile)
        data := File new(autoloadfile) read()
        runCode(data, rootNamespace)
        "OK" println()
    }

    /* Q: Do we display only the top stack, or all the stacks? */
    stackRepr: func -> String {
        topStack: Stack<EoType>  = stack peekStack()
        strValues := (topStack data map(|x| (x as EoType) toString()))
        numPrevStacks := stack stacks getSize() - 1
        prefix := numPrevStacks ? "(%d) " format(numPrevStacks) : ""
        //strValues add(0, "[")
        //strValues add("]")
        return prefix + "[" + strValues join(" ") + "]"
    }

    showCallStack: func {
        frames := callStack data as ArrayList<EoStackFrame> // workaround
        "call stack: "print()
        strValues := (frames map(|f| f code toString()))
        s := "[" + strValues join(" ") + "]"
        s println()
    }

    /* clear the current word stack. */
    clear: func {
        currentWordStack clear()
        currentWordStack push(ArrayList<EoType> new())
    }
}

EoREPL: class {
    interpreter: EoInterpreter
    prompt := "> "
    greeting: String  /* apparently cannot be initialized with "" + format */
    rootDir := "."

    init: func() {
        greeting = "Welcome to Eo version %s." format(EO_VERSION)
        interpreter = EoInterpreter new(rootDir)
    }
    init: func ~withRoot (=rootDir) { init() }

    run: func() {
        greeting println()
        while (stdin hasNext?()) {
            stdout write(prompt)
            line := stdin readLine()
            done := interpreter parse(line)
            if (done) {
                /* treat input like it was all entered in one code block */
                code: ArrayList<EoType> = interpreter currentWordStack pop()
                blk := EoCodeBlock new(code, interpreter userNamespace)
                uw := blk asEoUserDefWord()
                frame := EoStackFrame new(uw, interpreter userNamespace)
                interpreter callStack push(frame)
                interpreter executeAll()
                interpreter clear()
            }
            // FIXME: some code duplication here with EoInterpreter.runCode
            interpreter stackRepr() println()
        }
        println()
    }
}
