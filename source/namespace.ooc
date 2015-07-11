/* namespace.ooc */

import structs/[ArrayList, HashMap]
import eotypes

Namespace: class {
    parent: Namespace
    data := HashMap<String, EoType> new()

    init: func (=parent)
    init: func ~noparent { parent = null }

    add: func(key: String, value: EoType) {
        data put(key, value)
    }

    /* helper method to wrap code blocks in EoUserDefWords */
    addWord: func (key: String, value: EoCodeBlock) -> EoUserDefWord {
        assert (!key startsWith?("$"))
        word := EoUserDefWord new(value, key) /* block already has a namespace */
        this add(key, word)
        return word
    }

    /* helper function to wrap values in EoVariables */
    addVariable: func (key: String, value: EoType) -> EoVariable {
        assert(key startsWith?("$"))
        realname := key substring(1)
        e := EoVariable new(realname, value)
        this add(key, e)
        return e
    }

    delete: func (key: String) {
        (ns, value) := lookup_with_source(key)
        if (ns == null)
            Exception new("Key not found: %s" format(key)) throw()
        else 
            data remove(key)
    }

    // alternatively, we could just use null to mean "no result", in which
    // case this would map straightforwardly to HashMap.get
    lookup: func (key: String) -> EoType {
        result := data get(key)
        match (result) {
            case null =>
                if (parent == null) {
                    return null
                } else {
                    return parent lookup(key)
                }
            case =>
                return result
        }
        return null
    }

    lookup_with_source: func (key: String) -> (EoType, Namespace) {
        result := data get(key)
        if (result == null) {
            if (parent == null) {
                return (null, null)
            } else {
                return parent lookup_with_source(key)
            }
        } else {
            return (result, this)
        }
        return (null, null)  /* can't be reached; put here to keep rock happy */
    }

    update: func(key: String, new_value: EoType) {
        (result, ns) := lookup_with_source(key)
        if (result == null) {
            raise("Could not find name %s" format(key))
        } else {
            ns add(key, new_value)
        }
    }

    names: func -> ArrayList<String> {
        return data getKeys() 
    }

    all_names: func -> ArrayList<String> {
        currns := this
        names := HashMap<String, Int> new()
        for (name in this names()) names put(name, 0)
        while (currns parent != null) {
            currns = currns parent
            for (name in currns names()) names put(name, 0)
        }
        return names getKeys()
    }

    hasName?: func (key: String) -> Bool {
        value := lookup(key)
        return (value != null)
    }

    equals?: func (other: Namespace) -> Bool {
        this == other /* pointer comparison */
    }

    clone: func -> Namespace {
        newns := Namespace new(this parent)
        newns data = this data clone()
        return newns
    }
}


