/* builtins_ns.ooc */

import eo, eotypes, namespace, tools
import structs/[ArrayList, Stack]

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
    /* newns ( -- ns ) 
       Creates a new namespace, no parent. */
    xns := Namespace new()  /* no parent! */
    nns := EoNamespace new(xns)
    interp stack push(nns)
}

newns_star: func (interp: EoInterpreter, ns: Namespace) {
    /* newns* ( parent -- newns ) */
    parent := interp stack popCheck(EoNamespace) as EoNamespace
    xns := Namespace new(parent namespace)
    nns := EoNamespace new(xns)
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

/* return all local names in the given namespace (or module). */
names: func (interp: EoInterpreter, ns: Namespace) {
    /* names ( obj -- names ) */
    obj := interp stack pop()
    names: ArrayList<String>
    match (obj) {
        case (n: EoNamespace) => names = n namespace names()
        case (m: EoModule) => names = m namespace names()
        case => Exception new("Cannot extract names from %s" \
                format(obj class name)) throw()
    }
    assert (names != null)
    result := ArrayList<EoType> new()
    for (name in names) 
        result add(EoString new(name))
    interp stack push(EoList new(result))
}

all_names: func (interp: EoInterpreter, ns: Namespace) {
    /* all-names ( obj -- all-names ) */
    obj := interp stack pop()
    names: ArrayList<String>
    match (obj) {
        case (n: EoNamespace) => names = n namespace all_names()
        case (m: EoModule) => names = m namespace all_names()
        case => Exception new("Cannot extract names from %s" \
                format(obj class name)) throw()
    }
    assert (names != null)
    result := ArrayList<EoType> new()
    for (name in names) 
        result add(EoString new(name))
    interp stack push(EoList new(result))
}

/* helper function */
_alist_from_ns: func (targetns: Namespace, interp: EoInterpreter) {
    result := EoList new()
    names := targetns all_names()
    for (name in names) {
        value := targetns lookup(name)  /* an EoType object */
        pair := EoList new()
        pair data add(EoString new(name))
        pair data add(value)
        result data add(pair)
    }
    interp stack push(result)
}

ns_to_alist: func (interp: EoInterpreter, ns: Namespace) {
    /* ns->alist ( ns|mod -- ns-items )
       Return a list of [ name value ] pairs for all names found in the given
       namespace or module. */
    // XXX does this apply to dicts as well? in that case we should move this
    // word and call it `->alist` or something
    container := interp stack pop()
    match (container) {
        case (n: EoNamespace) => _alist_from_ns(n namespace, interp)
        case (mod: EoModule) => _alist_from_ns(mod namespace, interp)
        case => raise("ns->alist: target must be namespace or module")
    }
}

parent: func (interp: EoInterpreter, ns: Namespace) {
    /* parent ( ns -- parent ) */
    xns := interp stack popCheck(EoNamespace) as EoNamespace
    if (xns namespace parent == null) {
        interp stack push(EoNull)  
    } else {
        interp stack push(EoNamespace new(xns namespace parent))
    }
}

find_caller_ns: func (interp: EoInterpreter, ns: Namespace) {
    /* find-caller-ns ( name -- ns )
       Look up the call stack for the (first) namespace associated with a word
       named <name>. */
    name := interp stack popCheck(EoString) as EoString
    cs := interp callStack data as ArrayList<EoStackFrame>
    //"Call stack size: %d" printfln(cs size)
    idx := cs size - 1
    while (idx >= 0) {
        frame := cs[idx] as EoStackFrame
        //"Frame %d: code %s" printfln(idx+1, frame code toString())
        if (frame code instanceOf?(EoUserDefWord) && 
            (frame code as EoUserDefWord) name == name value) {
            interp stack push(EoNamespace new(frame namespace))
            return
        }
        idx -= 1
    }
    raise("Namespace not found")
}

