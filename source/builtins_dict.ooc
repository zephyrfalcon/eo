/* builtins_dict.ooc */

import eo, eotypes, namespace

dict: func (interp: EoInterpreter, ns: Namespace) {
    d := EoDict new()
    interp stack push(d)
}

put_excl: func (interp: EoInterpreter, ns: Namespace) {
    /* put! ( dict key value -- ) */
    value := interp stack pop() as EoType
    key := interp stack pop() as EoType
    dict := interp stack popCheck(EoDict) as EoDict
    dict add(key, value)
}

_get: func (interp: EoInterpreter, ns: Namespace) {
    /* get ( dict key -- value ) */
    key := interp stack pop()
    dict := interp stack popCheck(EoDict) as EoDict
    value: EoType = dict data get(key) as EoType
    if (value == null)
        Exception new("Key not found: %s" format(key toString())) throw()
    //"zzz" println()
    interp stack push(value)
    //"pushed!" println()
    //"%s" printfln(value class name)
    //"%s pushed!" printfln(value toString())
}

keys: func (interp: EoInterpreter, ns: Namespace) {
    /* keys ( dict -- keys ) */
    dict := interp stack popCheck(EoDict) as EoDict
    keys := dict data getKeys()  /* as EoStrings */
    result := EoList new(keys)
    interp stack push(result)
}

