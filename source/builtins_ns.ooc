/* builtins_ns.ooc */

import eo, eotypes, namespace

rootns: func (interp: EoInterpreter, ns: Namespace) {
    rns := EoNamespace new(interp rootNamespace)
    interp stack push(rns)
}

userns: func (interp: EoInterpreter, ns: Namespace) {
    uns := EoNamespace new(interp userNamespace)
    interp stack push(uns)
}

thisns: func (interp: EoInterpreter, ns: Namespace) {
    tns := EoNamespace new(ns)
    interp stack push(tns)
}

newns: func (interp: EoInterpreter, ns: Namespace) {
    nns := EoNamespace new(ns)
    interp stack push(nns)
}

newns_star: func (interp: EoInterpreter, ns: Namespace) {
    /* newns* ( parent -- newns ) */
    parent := interp stack popCheck(EoNamespace) as EoNamespace
    nns := EoNamespace new(parent namespace)
    interp stack push(nns)
}

_ns: func (interp: EoInterpreter, ns: Namespace) {
    /* ns ( obj -- obj.ns ) */
    obj := interp stack pop()
    xns: Namespace
    match (obj) {
        case (m: EoModule) => xns = m namespace
        case (blk: EoCodeBlock) => xns = blk namespace
        case => Exception new("Cannot extract namespace") throw()
    }
    assert (xns != null)
    interp stack push(EoNamespace new(xns))
}

