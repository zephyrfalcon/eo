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

    init: func {
        loadBuiltinWords(this)
    }

    execute: func (x: EoType) {
        match (x) {
            case i: EoInteger => stack push(i)
            case s: EoString => stack push(s)
            case sym: EoSymbol => "Not implemented yet" println()
            case => "Unknown" println()
        }
    }

    stackRepr: func -> String {
        strValues := stack data map(|x| (x as EoType) toString())
        return "[" + strValues join(" ") + "]"
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
            tokens := tokenize(line)
            print_tokens(tokens)
            //"\"%s\"" printfln(EscapeSequence escape(line))
            tokens each(|token|
                value := parseToken(token)
                //"That's an %s with value %s!" printfln(value class name, value toString())
                interpreter execute(value)
                interpreter stackRepr() println()
            )
        }
        println()
    }
}

repl := EoREPL new()
repl run()

