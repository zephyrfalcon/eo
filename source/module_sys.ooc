/* module_sys.ooc */

import structs/ArrayList
import builtins
import eo, namespace, eotypes

_version: func (interp: EoInterpreter, ns: Namespace) {
    /* version ( -- version-string ) */
    interp stack push(EoString new(EO_VERSION))
}

/* once we have more built-in modules, maybe we can generalize this... */

sys_loadBuiltinWords: func (interp: EoInterpreter) {
    newns := Namespace new(interp rootNamespace)
    sysmod := EoModule new(newns)
    sysmod name = "sys"
    sysmod path = "<builtin>"
    sysns := sysmod namespace

    /* add builtin word 'sys' that returns the module */
    words := ArrayList<EoType> new()
    words add(sysmod)
    blk := EoCodeBlock new(words, sysns)
    sysword := EoUserDefWord new(blk)
    interp rootNamespace add("sys", sysword)

    /* builtin words in the module */
    loadBuiltinWordInModule(sysns, "version", _version)
}


