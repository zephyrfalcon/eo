/* eo.ooc */

import structs/Stack

EO_VERSION := "0.0.1"

/* Eo built-in types */

EoType: abstract class {
}

EoInteger: class extends EoType {
}

EoString: class extends EoType {
}

/*****/

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
            "[%s]" printfln(line)
        }
        println()
    }
}

repl := EoREPL new()
repl run()

