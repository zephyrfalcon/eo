/* Eo built-in types */

import structs/ArrayList
import eo
import namespace

/*** base class ***/

EoType: abstract class {
    toString: abstract func -> String
}

/*** atoms ***/

EoInteger: class extends EoType {
    value: Int
    init: func(=value)
    toString: func -> String { value toString() }
}

EoString: class extends EoType {
    value: String
    init: func(=value)
    toString: func -> String { "\"" + value + "\"" }
    /* difference between str and repr? */
}

EoSymbol: class extends EoType {
    value: String
    init: func(=value)
    toString: func -> String { value }
}

/*** words ***/

EoWord: abstract class extends EoType {
}

/* Code blocks vs user-defined words:
   We need to distinguish between the two when they're on the call stack.
   A code block on the call stack will be pushed on the (data) stack.
   A user-defined word on the call stack will be executed.
*/

EoCodeBlock: class extends EoWord {
    words: ArrayList<EoType>
    namespace: Namespace
    init: func (=words, =namespace)
    init: func ~plain (=words)
    toString: func -> String { "#code{}" }
    /* later: maybe toString() should actually show the code? */
}

EoUserDefWord: class extends EoWord {
    code: EoCodeBlock
    name: String
    init: func (=code, =name)  // name is optional
    init: func ~plain (=code)
    toString: func -> String { "u#<%s>" format(name) }
}

EoBuiltinWord: class extends EoWord {
    f: Func(EoInterpreter, Namespace)
    name: String
    toString: func -> String { "#<%s>" format(name) }
    init: func (=name, =f)
}

EoList: class extends EoWord {
    data: ArrayList<EoType>
    toString: func -> String {
        strValues := data map(|x| x toString())
        return "[" + strValues join(" ") + "]"
    }
    init: func(=data)
    init: func ~empty { data := ArrayList<EoType> new() }
}

EoBool: class extends EoWord {
    value: Bool
    toString: func -> String { value ? "true" : "false" }
    init: func(=value)
}

/* don't create EoBools, use these instead */
EoTrue := EoBool new(true)
EoFalse := EoBool new(false)

EoVariable: class extends EoType {
    value: EoType
    name: String
    init: func (=name, =value)
    toString: func -> String { "$%s" format(name) }
}

EoModule: class extends EoType {
    name := "unknown"; path := ""  // override when loading module
    namespace: Namespace
    init: func (=namespace)  /* will usually be based on userNamespace */
    toString: func -> String { "#module<%s>" format(name) }
}



