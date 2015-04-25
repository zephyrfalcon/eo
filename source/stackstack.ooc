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
    popCheck: func (type: Class) -> EoType {
        x := (stacks peek() as Stack<EoType>) pop()
        if (x class name != type name) 
            "Type error: %s expected, got %s instead" \
             printfln(type name, x class name)
        /* FIXME: raise error or something */
        return x
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
    clearStack: func {
        while (stacks size > 0) popStack()
        stacks push(Stack<EoType> new())
        //stacks = Stack<Stack<EoType>> new()
        //init: func {
            //stacks push(Stack<EoType> new())
    }
    /* TODO: size of StackStack, vs size of top stack? */
}


