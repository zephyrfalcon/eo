/* builtins_logic.ooc */

import eo, eotypes, namespace

not: func (interp: EoInterpreter, ns: Namespace) {
    /* not ( x -- !x ) */
    x := interp stack popCheck(EoBool) as EoBool
    result := x value ? EoFalse : EoTrue
    interp stack push(result)
}

/* and, without shortcut mechanism */
and: func (interp: EoInterpreter, ns: Namespace) {
    /* and ( cond1 cond2 -- ) */
    cond2 := interp stack popCheck(EoBool) as EoBool
    cond1 := interp stack popCheck(EoBool) as EoBool
    result := (cond1 value & cond2 value) ? EoTrue : EoFalse
    interp stack push(result)
}
