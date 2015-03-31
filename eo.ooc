/* eo.ooc */

import structs/[ArrayList, Stack]
import text/[EscapeSequence, Shlex, StringTokenizer]

EO_VERSION := "0.0.1"

/* Eo built-in types */

EoType: abstract class {
}

EoInteger: class extends EoType {
}

EoString: class extends EoType {
}

/*****/

tokenize: func(data: String) -> ArrayList<String> {
    return Shlex split(data)  /* for now */
}

print_tokens: func(tokens: ArrayList<String>) {
    tokens each(|token| "\"%s\"" format(EscapeSequence escape(token)) println() )
}

EoInterpreter: class {
    stack := Stack<EoType> new()
    init: func
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
            parts := tokenize(line)
            print_tokens(parts)
            "\"%s\"" printfln(EscapeSequence escape(line))
        }
        println()
    }
}

repl := EoREPL new()
repl run()

