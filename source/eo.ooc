/* eo.ooc */

import structs/[ArrayList, HashMap, Stack]
import text/[EscapeSequence, Regexp, StringTokenizer]
import patch
import namespace, eotypes, stackstack
import builtins

EO_VERSION := "0.0.16"

/*****/

/* XXX there can be interpreter settings as well... is there a clear
 * difference between debug settings and interpreter settings? If not, we can
 * just use the same class. Or a dictionary... */
DebugSettings: class {
    showCallStack := false

    init: func
}

// comment | string | word
re_word := Regexp compile("(--.*?(\\n|$))|(\"[^\"]*\")|(\\S+)")

tokenize: func (data: String) -> ArrayList<String> {
    results := re_word split(data)
    return results filter(|token| !(token startsWith?("--"))) as ArrayList<String>
}

expandMacros: func (tokens: ArrayList<String>) -> ArrayList<String> {
    newTokens := ArrayList<String> new()
    for (token in tokens) {
        if (token startsWith?("->$") && token length() > 3) {
            newTokens add("\"%s\"" format(token substring(2)))
            newTokens add("defvar")
        }
        else if (token contains?(":") && !(token startsWith?(":")) \
                 && !(token endsWith?(":"))) {
            /* split foo:bar and replace with `foo "bar" execns` */
            parts := token split(":")
            newTokens add(parts[0])
            for (part in parts[1..-1]) {
                newTokens add("\"%s\"" format(part))
                newTokens add("execns")
            }
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

    /* stack to deal with nested word definitions */
    currentWordStack := Stack<ArrayList<EoType>> new()

    /* call stack to execute code */
    callStack := Stack<EoStackFrame> new()

    init: func {
        clear()
        /* true and false are special names that evaluate to themselves */
        rootNamespace add("true", EoTrue)
        rootNamespace add("false", EoFalse)
        loadBuiltinWords(this)
        loadStdlib()
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
        frame := callStack peek()
        match (frame code) {
            case sym: EoSymbol =>
                value := frame namespace lookup(sym value)
                /* the value found must be a variable or a word */
                callStack pop()  /* always remove in this case */
                match (value) {
                    case null =>
                        "Symbol not found: %s" printfln(sym toString())
                        /* later: raise an exception? */
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
                newns := Namespace new(frame namespace)
                blk namespace = newns
                stack push(blk)
                callStack pop()
            case bw: EoBuiltinWord =>
                /* REDUNDANT? yet this will execute things like `str:upper` */
                callStack pop()
                bw f(this, frame namespace)  /* is this the right namespace? */
            case uw: EoUserDefWord =>
                /* next step in executing user-defined word */
                if (frame counter >= uw code words size)
                    callStack pop()  /* done */
                else {
                    wordTBE := uw code words[frame counter]
                    frame counter += 1
                    newFrame := EoStackFrame new(wordTBE, uw code namespace)
                    callStack push(newFrame)
                }
                /* TODO: optimization opportunity here */
            case =>
                stack push(frame code)
                callStack pop()
        }
    }

    executeAll: func {
        while (!(callStack empty?())) executeStep()
    }

    /***/

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

    loadStdlib: func {
        /* look for .eo files in autoload/ and load them. at this point we
         * don't care about the order of the files. */
    }

    /* Q: Do we display only the top stack, or all the stacks? */
    stackRepr: func -> String {
        topStack: Stack<EoType>  = stack peekStack()
        strValues := (topStack data map(|x| (x as EoType) toString()))
        numPrevStacks := stack stacks getSize() - 1
        prefix := numPrevStacks ? "(%d) " format(numPrevStacks) : ""
        return prefix + "[" + strValues join(" ") + "]"
    }

    /* clear the current word stack. */
    clear: func {
        currentWordStack clear()
        currentWordStack push(ArrayList<EoType> new())
    }
}

EoREPL: class {
    interpreter := EoInterpreter new()
    prompt := "> "
    greeting: String  /* apparently cannot be initialized with "" + format */

    init: func() {
        greeting = "Welcome to Eo version %s." format(EO_VERSION)
    }

    run: func() {
        greeting println()
        while (stdin hasNext?()) {
            stdout write(prompt)
            line := stdin readLine()
            done := interpreter parse(line)
            if (done) {
                code: ArrayList<EoType> = interpreter currentWordStack pop()
                for (c in code) {
                    frame := EoStackFrame new(c, interpreter userNamespace)
                    interpreter callStack push(frame)
                    interpreter executeAll()
                }
                interpreter clear()
            }
            // FIXME: some code duplication here with EoInterpreter.runCode
            interpreter stackRepr() println()
        }
        println()
    }
}
