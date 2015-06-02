/* builtins_str.ooc */

import structs/ArrayList
import eo, namespace, eotypes
import patch
import tools

upper: func (interp: EoInterpreter, ns: Namespace) {
    s := interp stack popCheck(EoString) as EoString
    interp stack push(EoString new(s value toUpper()))
}

split_star: func (interp: EoInterpreter, ns: Namespace) {
    /* split* ( source str|regex -- parts )
       Split a string in parts, based on a string or a regex. */
    splitter := interp stack pop()
    src := interp stack popCheck(EoString) as EoString
    match (splitter) {
        case (s: EoString) => dummy()
        case (r: EoRegex) =>
            parts := r regex splitBy(src value)
            result := EoList new()
            for (part in parts) 
                result data add(EoString new(part))
            interp stack push(result)
        case => raise("split*: splitter must be string or regex")
    }
}
