/* eo-main.ooc */

import eo
import structs/ArrayList

main: func (args: ArrayList<String>) {
    runTests := (args size > 1 && args[1] == "--test")

    repl := EoREPL new()
    if (runTests)
        "run tests!" println()
    else
        repl run()
}

