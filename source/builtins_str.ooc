/* builtins_str.ooc */

import structs/ArrayList
import eo, namespace, eotypes

upper: func (interp: EoInterpreter, ns: Namespace) {
    s := interp stack popCheck(EoString) as EoString
    interp stack push(EoString new(s value toUpper()))
}

