/* builtins_str.ooc
   Built-in words for the str module. */

/* FIXME: there should not be a str module after all. However, there should be
 * other built-in modules, like sys, which can be modeled after this code. */

import structs/ArrayList
import builtins
import eo, namespace, eotypes

upper: func (interp: EoInterpreter, ns: Namespace) {
    s := interp stack popCheck(EoString) as EoString
    interp stack push(EoString new(s value toUpper()))
}
upper_doc := \
"upper ( string -- string' )
Converts a string to uppercase."
upper_tags := ["string"]
upper_arity := Arity new(1, 1)

str_loadBuiltinWords: func (interp: EoInterpreter) {
    newns := Namespace new(interp rootNamespace)
    strmod := EoModule new(newns)
    strmod name = "str"
    strmod path = "<builtin>"
    strns := strmod namespace

    /* add builtin word 'str' that returns the module */
    words := ArrayList<EoType> new()
    words add(strmod)
    blk := EoCodeBlock new(words, strns)
    strword := EoUserDefWord new(blk)
    interp rootNamespace add("str", strword)

    /* builtin words in the module */
    loadBuiltinWordInModule(strns, "upper", upper, upper_doc)
}


