/* eo.ooc */

import structs/[ArrayList, HashMap, Stack]
import text/[EscapeSequence, Regexp]
import patch
import namespace, eotypes
import builtins

EO_VERSION := "0.0.2"

/*****/

re_word := Regexp compile("(\"[^\"]*\")|(\\S+)")

tokenize: func(data: String) -> ArrayList<String> {
    return re_word split(data)
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
}

EoInterpreter: class {
    stack := Stack<EoType> new()  /* later: must be a "StackStack" */
    rootNamespace := Namespace new()
    userNamespace := Namespace new(rootNamespace)
    currentWordStack := Stack<ArrayList<EoType>> new()
    inWordDef := false
    /* something not right here... we need to deal with nested { }
     * definitions... maybe using a stack? */

    init: func {
        clear()
        rootNamespace add("true", EoTrue)
        rootNamespace add("false", EoFalse)
        loadBuiltinWords(this)
    }

    parse: func (data: String) -> Bool {
        tokens := tokenize(data)
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

    execute: func (x: EoType) {
        /* Symbols are looked up, everything else get pushed onto the stack. */
        match (x) {
            case sym: EoSymbol =>
                value := userNamespace lookup(sym value)
                if (value == null)
                    "Symbol not found: %s" printfln(sym toString())
                    /* later: raise an exception? */
                else
                    executeWord(value)
                    /* this works, but how do we execute user-defined words?
                       needs fixed. */
            case uw: EoUserDefWord => stack push(uw)
            /* FIXME: must add namespace to uw object */
            case => stack push(x)
        }
    }

    executeWord: func (x: EoType) {
        match (x) {
            case bw: EoBuiltinWord => bw f(this)
            case uw: EoUserDefWord =>
                for (c in uw words) execute(c)
                /* FIXME: later, we'll use a code stack */
            case => "Cannot execute: %s" printfln(x class name)
        }
    }

    stackRepr: func -> String {
        strValues := stack data map(|x| (x as EoType) toString())
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
                for (c in code) interpreter execute(c)
                interpreter clear()
            }
            interpreter stackRepr() println()
        }
        println()
    }
}

repl := EoREPL new()
repl run()

