/* builtins_dict.ooc */

import eo, eotypes, namespace
import structs/ArrayList

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
    keys := dict data getKeys()  /* as EoTypes */
    result := EoList new(keys)
    interp stack push(result)
}

values: func (interp: EoInterpreter, ns: Namespace) {
    /* values ( dict -- values ) */
    dict := interp stack popCheck(EoDict) as EoDict
    keys := dict data getKeys()  /* as EoTypes */
    /* apparently ArrayList.map returns a plain List rather than an ArrayList,
     * and casting seems to be tricky. so we do it the hard way: */
    values := ArrayList<EoType> new()
    keys each(|key| values add(dict data get(key))) 
    result := EoList new(values)
    interp stack push(result)
}

items: func (interp: EoInterpreter, ns: Namespace) {
    /* items ( dict -- items ) */
    dict := interp stack popCheck(EoDict) as EoDict
    keys: ArrayList<EoType> = dict data getKeys()  /* as EoTypes */
    /* apparently ArrayList.map returns a plain List rather than an ArrayList,
     * and casting seems to be tricky. so we do it the hard way: */
    values := ArrayList<EoType> new()
    for (key in keys) {
        key toString() println()
        value := dict data get(key as EoType) as EoType
        value toString() println()
        pair := EoList new()
        pair data add(key as EoType)
        "segfault?" println()
        pair data add(value)
        pair toString() println()
        values add(pair)
    }
    result := EoList new(values)
    interp stack push(result)
}

