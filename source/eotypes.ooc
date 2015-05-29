/* Eo built-in types */

import structs/[ArrayList, HashMap]
import text/EscapeSequence
import eo
import namespace

/*** helper classes ***/

Arity: class {
    in, out: Int
    init: func (=in, =out)
}

/*** base class ***/

EoType: abstract class {
    /* all objects can have a description and tags. */
    description: String
    tags: ArrayList<String>

    toString: abstract func -> String
    valueAsString: func -> String { this toString() }
    mutable?: func -> Bool { false }
    equals?: func (other: EoType) -> Bool { false }
    hash: func -> SizeT { 0 }
    type: func -> String { "unknown" }
}

/*** atoms ***/

EoInteger: class extends EoType {
    value: Int
    init: func(=value)
    toString: func -> String { value toString() }
    type: func -> String { "int" }

    fromHexString: static func (s: String) -> EoInteger {
        /* parse hexadecimal literal to integer value. the input string may be
         * negative and/or start with "0x". */
        negative := false
        if (s startsWith?("-")) {
            negative = true
            s = s substring(1)
        }
        if (s startsWith?("0x") || s startsWith?("0X"))
            s = s substring(2)
        value := 0
        for (c in s) {
            if (c >= '0' && c <= '9') {
                x := c - '0'
                value = value * 16 + x
            }
            else if (c >= 'a' && c <= 'f') {
                x := c - 'a'
                value = value * 16 + 10 + x
            }
            else if (c >= 'A' && c <= 'F') {
                x := c - 'A'
                value = value * 16 + 10 + x
            }
        }
        if (negative) value = -value
        return EoInteger new(value)
    }

    fromOctalString: static func (token: String) -> EoInteger {
        negative := false
        if (token startsWith?("-")) {
            negative = true
            token = token substring(1)
        }
        if (token startsWith?("0o") || token startsWith?("0O"))
            token = token substring(2)
        value := 0
        for (c in token) {
            if (c >= '0' && c <= '7') {
                x := c - '0'
                value = value * 8 + x
            }
        }
        if (negative) value = -value
        return EoInteger new(value)
    }

    fromBinaryString: static func (token: String) -> EoInteger {
        negative := false
        if (token startsWith?("-")) {
            negative = true
            token = token substring(1)
        }
        if (token startsWith?("0b") || token startsWith?("0B"))
            token = token substring(2)
        value := 0
        for (c in token) {
            if (c >= '0' && c <= '1') {
                x := c - '0'
                value = value * 2 + x
            }
        }
        if (negative) value = -value
        return EoInteger new(value)
    }

    equals?: func (other: EoInteger) -> Bool { this value == other value }
    hash: func -> SizeT { value % 0xFFFF }

}

EoString: class extends EoType {
    value: String
    init: func(=value)
    toString: func -> String { "\"" + EscapeSequence escape(value) + "\"" }
    valueAsString: func -> String { value }
    equals?: func (other: EoString) -> Bool {
        return this value == other value
    }
    hash: func -> SizeT { ac_X31_hash(value) }
    type: func -> String { "string" }
}

EoSymbol: class extends EoType {
    value: String
    init: func(=value)
    toString: func -> String { value }
    type: func -> String { "symbol" }
}

/*** words ***/

/* Code blocks vs user-defined words:
   We need to distinguish between the two when they're on the call stack.
   A code block on the call stack will be pushed on the (data) stack.
   A user-defined word on the call stack will be executed.
*/

EoCodeBlock: class extends EoType /* EoWord */ {
    words: ArrayList<EoType>
    namespace: Namespace
    init: func (=words, =namespace)
    init: func ~plain (=words)
    toString: func -> String { "#code{}" }
    /* later: maybe toString() should actually show the code? */
    mutable?: func -> Bool { true }
    type: func -> String { "block" }

    asEoUserDefWord: func -> EoUserDefWord {
        return EoUserDefWord new(this)
    }
}

EoWord: abstract class extends EoType {
    arity: Arity
    mutable?: func -> Bool { true }
    type: func -> String { "word" }
}

EoUserDefWord: class extends EoWord {
    code: EoCodeBlock
    name: String
    init: func (=code, =name)  // name is optional
    init: func ~plain (=code)
    toString: func -> String { "u#<%s>" format(name == null ? "" : name) }
    type: func -> String { "u-word" }
}

EoBuiltinWord: class extends EoWord {
    f: Func(EoInterpreter, Namespace)
    name: String
    toString: func -> String { "#<%s>" format(name) }
    init: func (=name, =f)
    type: func -> String { "b-word" }
}

EoList: class extends EoType {
    data: ArrayList<EoType>
    toString: func -> String {
        strValues := data map(|x| x toString())
        strValues add(0, "[")
        strValues add("]")
        //return "[" + strValues join(" ") + "]"
        return strValues join(" ")
    }
    init: func(=data)
    init: func ~empty { data = ArrayList<EoType> new() }
    /* ^ don't use `data := ...` here, it causes a segfault later */
    mutable?: func -> Bool { true }
    type: func -> String { "list" }
}

EoBool: class extends EoType {
    value: Bool
    toString: func -> String { value ? "true" : "false" }
    init: func(=value)
    equals?: func (other: EoBool) -> Bool { this value == other value }
    hash: func -> SizeT { value ? 1 : 0 }
    type: func -> String { "bool" }
}

/* don't create EoBools, use these instead */
EoTrue := EoBool new(true)
EoFalse := EoBool new(false)

EoVariable: class extends EoType {
    value: EoType
    name: String
    init: func (=name, =value)
    toString: func -> String { "$%s" format(name) }
    mutable?: func -> Bool { true }
    type: func -> String { "variable" }
}

EoModule: class extends EoType {
    name := "unknown"; path := ""  // override when loading module
    namespace: Namespace
    init: func (=namespace)  /* will usually be based on userNamespace */
    toString: func -> String { "#module<%s>" format(name) }
    mutable?: func -> Bool { true }
    type: func -> String { "module" }
}

EoNamespace: class extends EoType {
    namespace: Namespace
    init: func (namespace: Namespace) {
        this namespace = namespace
    }
    toString: func -> String { "#namespace<%x>" format(this) }
    mutable?: func -> Bool { true }
    type: func -> String { "namespace" }
    equals?: func (other: EoNamespace) -> Bool {
        return this namespace == other namespace /* pointer comparison */
    }
}

/* --- dictionaries (include equality testing and hash computation) --- */

/* custom equality test, needed for HashMaps */
eoEquals: func<K> (a, b: K) -> Bool {
    c := a as EoType
    d := b as EoType
    assert (c instanceOf?(EoType))
    assert (d instanceOf?(EoType))
    if (c class != d class) return false
    return c equals?(d)
}

/* we wrap eoEquals in this (see ooc source: sdk/structs/HashMap.ooc */
eoStandardEquals: func<T> (T: Class) -> Func<T> (T, T) -> Bool {
    "std equals" println()
    return eoEquals
}

eoHash: func<T> (key: T) -> SizeT {
    a := key as EoType
    return a hash()
}

eoStandardHashFunc: func<T> (T: Class) -> Func <T> (T) -> SizeT {
    return eoHash
}

EoDict: class extends EoType {
    data := HashMap<EoType, EoType> new()
    toString: func -> String { "#dict" } /* FIXME */
    mutable?: func -> Bool { true }
    type: func -> String { "dict" }

    init: func {
        data keyEquals = eoStandardEquals(EoType)
        /* needs to return a FUNCTION that does the comparison */
        data hashKey = eoStandardHashFunc(EoType)
    }

    add: func (key, value: EoType) {
        if (key.mutable?())
            Exception new("Mutable objects cannot be used as keys") throw()
        data put(key, value)
    }
}

/* --- end of dictionary-related code --- */
