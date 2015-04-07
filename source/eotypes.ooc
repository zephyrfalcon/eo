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
    words: ArrayList<String> // for now!
    name: String
    namespace: Namespace
    init: func (=words, =namespace)  // name is optional
    toString: func -> String { "u#<%s>" format(name) }
}

EoBuiltinWord: class extends EoWord {
    f: Func(EoInterpreter)
    name: String
    toString: func -> String { "#<%s>" format(name) }
    init: func (=name, =f)
}


/* we need an EoList, but not an EoStack; they're the same thing.
   Even structs/Stack is implemented with an ArrayList, so we can treat them
   the same.
*/


