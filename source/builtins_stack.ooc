/* builtins_stack.ooc */

import eo, eotypes, namespace, stackstack
import structs/Stack

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

over: func (interp: EoInterpreter, ns: Namespace) {
    /* over ( a b -- a b a ) */
    a: EoType
    stk := interp stack stacks peek() as Stack<EoType>
    /* FIXME: peeking in the stack without actually popping anything is used
     * in other words as well... maybe we should make this a feature of
     * StackStack? */
    try {
        a = stk peek(2)
    } catch (e: Exception) {
        Exception new("stack underflow") throw()
    }
    interp stack push(a)
}

stack_empty_qm: func (interp: EoInterpreter, ns: Namespace) {
}

pick: func (interp: EoInterpreter, ns: Namespace) {
}

