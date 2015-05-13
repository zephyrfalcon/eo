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
}


