/* builtins_str.ooc
   Built-in words for the str module. */

import structs/ArrayList
import builtins
import eo, namespace, eotypes

upper: func (interp: EoInterpreter, ns: Namespace) {
    s := interp stack popCheck(EoString) as EoString
    interp stack push(EoString new(s value toUpper()))
}

str_loadBuiltinWords: func (interp: EoInterpreter) {
    strmod := EoModule new(interp userNamespace)
    strmod name = "str"
    strmod path = "<builtin>"
    strns := strmod namespace

    /* add builtin word 'str' that returns the module */
    words := ArrayList<EoType> new()
    words add(strmod)
    blk := EoCodeBlock new(words, interp userNamespace)
    strword := EoUserDefWord new(blk)
    interp userNamespace add("str", strword)

    /* builtin words in the module */
    loadBuiltinWordInModule(strns, "upper", upper)
}


