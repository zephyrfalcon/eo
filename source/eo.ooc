/* eo.ooc */

import structs/[ArrayList, HashMap, Stack]
import text/[EscapeSequence, Regexp]
import patch
import namespace, eotypes
import builtins

EO_VERSION := "0.0.5"

/*****/

re_word := Regexp compile("(\"[^\"]*\")|(\\S+)")

tokenize: func(data: String) -> ArrayList<String> {
    return re_word split(data)
}

expandMacros: func (tokens: ArrayList<String>) -> ArrayList<String> {
    newTokens := ArrayList<String> new()
    for (token in tokens) {
        if (token startsWith?("->$") && token length() > 3) {
            newTokens add("\"%s\"" format(token substring(2)))
            newTokens add("defvar")
        }
        else
            newTokens add(token)
    }
    return newTokens
}

print_tokens: func(tokens: ArrayList<String>) {
    tokens each(|token| token println())
}

re_number := Regexp compile("\\d+")

parseToken: func(token: String) -> EoType {
    if (re_number matches(token)) {
        return EoInteger new(token toInt())
    }
    if (token startsWith?("\"") && token endsWith?("\"")) {
        return EoString new(token[1..-2]) /* TODO: (un)escaping */
        /* NOTE: ooc slicing != Python slicing. */
    }
    return EoSymbol new(token)
    /* NOTE: symbols include variables. */
}

StackStack: class {
    stacks := Stack<Stack<EoType>> new()
    init: func {
        stacks push(Stack<EoType> new())
    }

    /* methods that operate on the top stack */

    push: func (x: EoType) {
        stacks peek() push(x)
    }
    pop: func -> EoType {
        (stacks peek() as Stack<EoType>) pop()
    }
    peek: func -> EoType {
        (stacks peek() as Stack<EoType>) peek()
    }
    clear: func {
        stacks peek() clear()
    }

    /* methods that operate on the whole stack of stacks */

    popStack: func -> Stack<EoType> {
        stacks pop()
    }
    pushStack: func (stk: Stack<EoType>) {
        stacks push(stk)
    }
    peekStack: func -> Stack<EoType> {
        stacks peek()
    }
    /* TODO: size of StackStack, vs size of top stack? */
}

EoInterpreter: class {
    //stack := Stack<EoType> new()  /* later: must be a "StackStack" */
    stack := StackStack new()
    rootNamespace := Namespace new()
    userNamespace := Namespace new(rootNamespace)

    /* stack to deal with nested word definitions */
    currentWordStack := Stack<ArrayList<EoType>> new()

    init: func {
        clear()
        rootNamespace add("true", EoTrue)
        rootNamespace add("false", EoFalse)
        loadBuiltinWords(this)
    }

    parse: func (data: String) -> Bool {
        tokens := tokenize(data)
        tokens = expandMacros(tokens)
        for (token in tokens) {
            match (token) {
                case "{" =>
                    currentWordStack push(ArrayList<EoType> new())
                case "}" =>
                    code: ArrayList<EoType> = currentWordStack pop()
                    w := EoUserDefWord new(code)
                    currentWordStack peek() add(w)
                    /* namespace must be added later */
                case =>
                    x := parseToken(token)
                    currentWordStack peek() add(x)
            }
        }
        /* if the stack has more than 1 list on it, we're still inside a word
         * definition. */
        return currentWordStack size == 1  /* done? */
    }

    execute: func (x: EoType, ns: Namespace) {
        /* Symbols are looked up, everything else get pushed onto the stack. */
        match (x) {
            case sym: EoSymbol =>
                value := ns lookup(sym value)
                if (value == null)
                    "Symbol not found: %s" printfln(sym toString())
                    /* later: raise an exception? */
                else if (value instanceOf?(EoVariable))
                    stack push((value as EoVariable) value)
                else
                    executeWord(value, ns)
                    /* this works, but how do we execute user-defined words?
                       needs fixed. */
            case uw: EoUserDefWord =>
                uw namespace = ns
                stack push(uw)
            case => stack push(x)
        }
    }

    executeWord: func (x: EoType, ns: Namespace) {
        match (x) {
            case bw: EoBuiltinWord => bw f(this, ns)
            case uw: EoUserDefWord =>
                newns := Namespace new(ns)
                for (c in uw words) execute(c, newns)
                /* FIXME: later, we'll use a code stack */
            case => "Cannot execute: %s" printfln(x class name)
        }
    }

    /* Q: Do we display only the top stack, or all the stacks? */
    stackRepr: func -> String {
        topStack: Stack<EoType>  = stack peekStack()
        strValues := (topStack data map(|x| (x as EoType) toString()))
        return "[" + strValues join(" ") + "]"
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
                for (c in code)
                    interpreter execute(c, interpreter userNamespace)
                interpreter clear()
            }
            interpreter stackRepr() println()
        }
        println()
    }
}

repl := EoREPL new()
repl run()

