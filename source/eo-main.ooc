/* eo-main.ooc */

import eo
import structs/ArrayList

main: func (args: ArrayList<String>) {
    repl := EoREPL new()
    repl run()
}

