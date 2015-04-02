/* Eo built-in types */

EoType: abstract class {
    toString: abstract func -> String
}

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

/* we need an EoList, but not an EoStack; they're the same thing.
   Even structs/Stack is implemented with an ArrayList, so we can treat them
   the same.
*/


