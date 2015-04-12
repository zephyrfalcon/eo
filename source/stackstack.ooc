/* stackstack.ooc */

import structs/Stack
import eotypes

StackStack: class {
    stacks := Stack<Stack<EoType>> new()
    init: func {
        stacks push(Stack<EoType> new())
    }

    /* methods that operate on the top stack */

    push: func (x: EoType) {
        stacks peek() push(x)
    }
    pop: func -> EoType {
        (stacks peek() as Stack<EoType>) pop()
    }
    peek: func -> EoType {
        (stacks peek() as Stack<EoType>) peek()
    }
    clear: func {
        stacks peek() clear()
    }

    /* methods that operate on the whole stack of stacks */

    popStack: func -> Stack<EoType> {
        stacks pop()
    }
    pushStack: func (stk: Stack<EoType>) {
        stacks push(stk)
    }
    peekStack: func -> Stack<EoType> {
        stacks peek()
    }
    /* TODO: size of StackStack, vs size of top stack? */
}


