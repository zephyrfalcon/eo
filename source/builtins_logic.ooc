/* builtins_logic.ooc */

import eo, eotypes, namespace

not: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack popCheck(EoBool) as EoBool
    result := x value ? EoFalse : EoTrue
    interp stack push(result)
}
