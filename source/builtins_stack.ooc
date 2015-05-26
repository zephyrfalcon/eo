/* builtins_stack.ooc */

import eo, eotypes, namespace

dup: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    interp stack push(x)
    interp stack push(x)
}

drop: func (interp: EoInterpreter, ns: Namespace) {
    interp stack pop()
}

swap: func (interp: EoInterpreter, ns: Namespace) {
    /* swap ( a b -- b a ) */
    b := interp stack pop()
    a := interp stack pop()
    interp stack push(b)
    interp stack push(a)
}
