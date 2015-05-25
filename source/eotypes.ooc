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
}

/*** atoms ***/

EoInteger: class extends EoType {
    value: Int
    init: func(=value)
    toString: func -> String { value toString() }

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
}

EoString: class extends EoType {
    value: String
    init: func(=value)
    toString: func -> String { "\"" + EscapeSequence escape(value) + "\"" }
    valueAsString: func -> String { value }
    equals?: func (other: EoString) -> Bool {
        return this value == other value
    }
}

EoSymbol: class extends EoType {
    value: String
    init: func(=value)
    toString: func -> String { value }
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

    asEoUserDefWord: func -> EoUserDefWord {
        return EoUserDefWord new(this)
    }
}

EoWord: abstract class extends EoType {
    arity: Arity
    mutable?: func -> Bool { true }
}

EoUserDefWord: class extends EoWord {
    code: EoCodeBlock
    name: String
    init: func (=code, =name)  // name is optional
    init: func ~plain (=code)
    toString: func -> String { "u#<%s>" format(name == null ? "" : name) }
}

EoBuiltinWord: class extends EoWord {
    f: Func(EoInterpreter, Namespace)
    name: String
    toString: func -> String { "#<%s>" format(name) }
    init: func (=name, =f)
}

EoList: class extends EoType {
    data: ArrayList<EoType>
    toString: func -> String {
        strValues := data map(|x| x toString())
        return "[" + strValues join(" ") + "]"
    }
    init: func(=data)
    init: func ~empty { data := ArrayList<EoType> new() }
    mutable?: func -> Bool { true }
}

EoBool: class extends EoType {
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
    mutable?: func -> Bool { true }
}

EoModule: class extends EoType {
    name := "unknown"; path := ""  // override when loading module
    namespace: Namespace
    init: func (=namespace)  /* will usually be based on userNamespace */
    toString: func -> String { "#module<%s>" format(name) }
    mutable?: func -> Bool { true }
}

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
    return eoEquals
}

EoDict: class extends EoType {
    data := HashMap<EoType, EoType> new()
    toString: func -> String { "#dict" } /* FIXME */
    mutable?: func -> Bool { true }

    init: func {
        data keyEquals = eoStandardEquals(EoType)
        /* XXX needs to return a FUNCTION that does the comparison */
    }

    add: func (key, value: EoType) {
        if (key.mutable?())
            Exception new("Mutable objects cannot be used as keys") throw()
        data put(key, value)
    }
}

