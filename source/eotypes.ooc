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

EoUserDefWord: class extends EoWord {
    words: ArrayList<EoType> 
    name: String
    namespace: Namespace
    init: func (=words, =namespace)  // name is optional
    init: func ~plain (=words)
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
    name, path: String
    namespace: Namespace
    init: func (=namespace)  /* will usually be based on userNamespace */
    toString: func -> String { "module" } /* FIXME */
}



