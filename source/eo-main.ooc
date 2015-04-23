/* eo-main.ooc */

import eo
import structs/ArrayList

main: func (args: ArrayList<String>) {
    runTests := false
    if (args size > 1 && args[1] == "--test") runTests = true

    repl := EoREPL new()
    if (runTests)
        "run tests!" println()
    else
        repl run()
}

