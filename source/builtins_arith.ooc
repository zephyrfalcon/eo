/* builtins_arith.ooc
   Arithmetic functions etc. */

import eo, eotypes, namespace
import patch, tools

plus: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    y := interp stack pop()
    if (x instanceOf?(EoInteger) && y instanceOf?(EoInteger)) {
        result := EoInteger new((y as EoInteger) value + (x as EoInteger) value)
        interp stack push(result)
    }
    else
        Exception new("+ only works on numbers") throw()
}

/* lots of boilerplate in here; needs fixed */
minus: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    y := interp stack pop()
    if (x instanceOf?(EoInteger) && y instanceOf?(EoInteger)) {
        result := EoInteger new((y as EoInteger) value - (x as EoInteger) value)
        interp stack push(result)
    }
    else
        Exception new("- only works on numbers") throw()
}

_equals: func (interp: EoInterpreter, ns: Namespace) {
    /* ( = a b -- bool ) */
    x := interp stack popCheck(EoInteger) as EoInteger
    y := interp stack popCheck(EoInteger) as EoInteger
    result := (x value == y value) ? EoTrue : EoFalse
    interp stack push(result)
}

/* lots of boilerplate here too; also, future versions of `>` will likely
 * support more types, like strings */
_gt: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    y := interp stack pop()
    if (x instanceOf?(EoInteger) && y instanceOf?(EoInteger)) {
        result := ((y as EoInteger) value > (x as EoInteger) value)
        interp stack push(result ? EoTrue : EoFalse)
    }
    else
        Exception new("> only works on numbers") throw()
}

_lt: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    y := interp stack pop()
    if (x instanceOf?(EoInteger) && y instanceOf?(EoInteger)) {
        result := ((y as EoInteger) value < (x as EoInteger) value)
        interp stack push(result ? EoTrue : EoFalse)
    }
    else
        Exception new("< only works on numbers") throw()
}


