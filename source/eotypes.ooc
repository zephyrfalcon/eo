/* Eo built-in types */

import structs/[ArrayList, HashMap]
import text/[EscapeSequence, Regexp]
import eo
import namespace
import patch


/* fallback for when a and b are not of the same EoType. we cannot rely on
   EoType.cmp to handle this. */
eocmp: func (a, b: EoType) -> Int {
    if (a class != b class) 
        return cmp(a type(), b type())
    else
        return a cmp(b)
}

/*** base class ***/

EoType: abstract class {
    /* all objects can have a description and tags. */
    description: String
    tags := ArrayList<String> new()

    toString: abstract func -> String
    valueAsString: func -> String { this toString() }
    mutable?: func -> Bool { false }
    hash: func -> SizeT { 31337 }
    type: func -> String { "unknown" }

    /* NOTE: the following methods shouldn't really be called. ooc's object
     * system is not smart enough to call them when appropriate. these cases
     * are handled in `cmp` and `eq?` instead. */
    equals?: func (other: EoType) -> Bool { this == other }
    cmp: func (other: EoType) -> Int { this type() cmp(other type()) }
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
    cmp: func (other: EoInteger) -> Int { cmp(this value, other value) }
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
    cmp: func (other: EoString) -> Int { this value cmp(other value) }
}

EoSymbol: class extends EoType {
    value: String
    init: func(=value)
    toString: func -> String { value }
    type: func -> String { "symbol" }
    equals?: func (other: EoSymbol) -> Bool { cmp(this value, other value) == 0 }
    cmp: func (other: EoSymbol) -> Int { cmp(this value, other value) }
    hash: func -> SizeT { ac_X31_hash(value) }
}

EoBool: class extends EoType {
    value: Bool
    toString: func -> String { value ? "true" : "false" }
    init: func(=value)
    equals?: func (other: EoBool) -> Bool { this value == other value }
    cmp: func (other: EoBool) -> Int { 
        cmp(value ? 1 : 0, other value ? 1 : 0)
    }
    hash: func -> SizeT { value ? 1 : 0 }
    type: func -> String { "bool" }
}

/* don't create EoBools, use these instead */
EoTrue := EoBool new(true)
EoFalse := EoBool new(false)

EoNull_: class extends EoType {
    init: func
    toString: func -> String { "null" }
    equals?: func (other: EoNull_) -> Bool { true }
    cmp: func (other: EoNull_) -> Int { 0 }
    hash: func -> SizeT { 0 }
    type: func -> String { "null" }
}
EoNull := EoNull_ new()

EoRegex: class extends EoType {
    regex: Regexp
    original: String
    /* ooc's Regexp has no way to extract the original string from it, so we
     * need to keep track of it ourselves */
    init: func ~withRegex (r: Regexp, original: String) {
        regex = r
        this original = original
    }
    init: func ~withString (s: String) {
        s = s replaceAll("\\/", "/")
        regex = Regexp compile(s) 
        original = s
    }
    toString: func -> String { "#regex" } // FIXME, obviously
    equals?: func (other: EoRegex) -> Bool { false } // FIXME
    hash: func -> SizeT { ac_X31_hash(original) }
    type: func -> String { "regex" }
    cmp: func (other: EoRegex) -> Int { this original cmp(other original) }
    valueAsString: func -> String { original }
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
    toString: func -> String {
        strValues := words map(|x| x toString())
        strValues add(0, "{")
        strValues add("}")
        return strValues join(" ")
    }
    mutable?: func -> Bool { true }
    type: func -> String { "block" }
    hash: func -> SizeT { this as SizeT }

    clone: func -> EoCodeBlock {
        blk := EoCodeBlock new(this words, this namespace)
        return blk
    }

    /* code blocks are considered equal if their code is equal... but what
     * about the namespace? */
    cmp: func (other: EoCodeBlock) -> Int {
        Exception new("not implemented yet") throw()
        for (i in 0..words size) {
            if (i >= other words size) return 1
            c := eocmp(this words[i], other words[i])
            if (c != 0) return c
        }
        if (this words size < other words size) return -1

        /* take namespaces into account */
        return cmp(this namespace as SizeT, other namespace as SizeT)
    }
    equals?: func (other: EoCodeBlock) -> Bool { 
        this cmp(other) == 0
    }

    asEoUserDefWord: func -> EoUserDefWord {
        return EoUserDefWord new(this)
    }
}

EoWord: abstract class extends EoType {
    //arity: Arity
    mutable?: func -> Bool { true }
    type: func -> String { "word" }
    hash: func -> SizeT { this as SizeT }
}

EoUserDefWord: class extends EoWord {
    code: EoCodeBlock
    name: String

    /* if reuseNamespace is true, then when the word is executed, it will
     * reuse the code block's namespace. this is desirable in *some* cases,
     * but usually it isn't, so the default is false. */
    reuseNamespace := false

    init: func (=code, =name)  // name is optional
    init: func ~plain (=code)
    toString: func -> String { "u#<%s>" format(name == null ? "" : name) }
    type: func -> String { "u-word" }

    /* user-defined words are considered equal if their code blocks are equal */
    cmp: func (other: EoUserDefWord) -> Int {
        this code cmp(other code)
    }
    equals?: func (other: EoUserDefWord) -> Bool {
        this cmp(other) == 0
    }
}

EoBuiltinWord: class extends EoWord {
    f: Func(EoInterpreter, Namespace)
    name: String
    toString: func -> String { "#<%s>" format(name) }
    init: func (=name, =f)
    type: func -> String { "b-word" }

    /* built-in words are considered equal if they refer to the same function. */
    equals?: func (other: EoBuiltinWord) -> Bool {
        /* apparently Func is really just a Closure cover */
        p1 := (this f as Closure) thunk
        p2 := (other f as Closure) thunk
        return p1 == p2
        return true
    }
    cmp: func (other: EoBuiltinWord) -> Int {
        if (this equals?(other)) return 0
        return this name cmp(other name)
    }
}

/*** containers ***/

EoList: class extends EoType {
    data: ArrayList<EoType>
    toString: func -> String {
        strValues := data map(|x| x toString())
        strValues add(0, "[")
        strValues add("]")
        return strValues join(" ")
    }
    init: func(=data)
    init: func ~empty { data = ArrayList<EoType> new() }
    /* ^ don't use `data := ...` here, it causes a segfault later */
    mutable?: func -> Bool { true }
    type: func -> String { "list" }
    hash: func -> SizeT { this as SizeT }
    cmp: func (other: EoList) -> Int {
        for (i in 0..data size) {
            if (i >= other data size) return 1
            c := eocmp(this data[i], other data[i])
            if (c != 0) return c
        }
        if (this data size < other data size) return -1
        return 0
    }
    equals?: func (other: EoList) -> Bool { this cmp(other) == 0 }
}

EoVariable: class extends EoType {
    value: EoType
    name: String
    init: func (=name, =value)
    toString: func -> String { "$%s" format(name) }
    mutable?: func -> Bool { true }
    type: func -> String { "variable" }
    hash: func -> SizeT { ac_X31_hash("$"+name) }

    /* variable comparisons don't make a lot of sense... */
    equals?: func (other: EoVariable) -> Bool { this == other }
    cmp: func (other: EoVariable) -> Int {
        cmp(this as SizeT, other as SizeT)
    }
}

EoModule: class extends EoType {
    name := "unknown"; path := ""  // override when loading module
    namespace: Namespace
    init: func (=namespace)  /* will usually be based on userNamespace */
    toString: func -> String { "#module<%s>" format(name) }
    mutable?: func -> Bool { true }
    type: func -> String { "module" }
    hash: func -> SizeT { this as SizeT }

    /* module comparisons don't make a lot of sense either... */
    equals?: func (other: EoModule) -> Bool { this == other }
    cmp: func (other: EoModule) -> Int {
        cmp(this as SizeT, other as SizeT)
    }
}

EoNamespace: class extends EoType {
    namespace: Namespace
    init: func (namespace: Namespace) {
        this namespace = namespace
    }
    toString: func -> String { "#namespace<%x>" format(this) }
    mutable?: func -> Bool { true }
    type: func -> String { "namespace" }
    hash: func -> SizeT { this as SizeT }
    equals?: func (other: EoNamespace) -> Bool {
        return this namespace == other namespace /* pointer comparison */
    }
    cmp: func (other: EoNamespace) -> Int {
        cmp(this namespace as SizeT, other namespace as SizeT)
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
    hash: func -> SizeT { this as SizeT }

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

    /* returns contents as an a-list, i.e. a list of [key value] pairs. both
     * pairs and the alist itself are EoLists. */
    // XXX is this the same as `items`??
    asAList: func -> EoList {
        alist := EoList new()
        for (key in data getKeys()) {
            value := data get(key)
            pair := EoList new()
            pair data add(key)
            pair data add(value)
            alist data add(pair)
        }
        return alist
    }

    /* XXX how do we compare dictionaries? I think Python goes by length
     * first, then maybe compares keys or items?
     * We _could_ convert both dicts to alists and compare those... but list
     * comparison and dict comparison is not the same! */
    cmp: func (other: EoDict) -> Int {
        if (this data == other data) return 0  /* same object */
        c := cmp(this data size, other data size)
        if (c != 0) return c
        /* same length, not the same object; compare contents: */
        // FIXME: extract contents as alist (EoLists) and compare those
        // *sorted*!!
        return 1  // dummy
    }
}

/* --- end of dictionary-related code --- */
