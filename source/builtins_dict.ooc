/* builtins_dict.ooc */

import eo, eotypes, namespace
import structs/ArrayList

dict: func (interp: EoInterpreter, ns: Namespace) {
    d := EoDict new()
    interp stack push(d)
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
        value := dict data get(key as EoType) as EoType
        pair := EoList new()
        pair data add(key as EoType)
        pair data add(value)
        values add(pair)
    }
    result := EoList new(values)
    interp stack push(result)
    // XXX can we use EoDict.asAList for this?
}


