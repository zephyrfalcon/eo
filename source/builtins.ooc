/* builtins.ooc */

import eotypes, eo

dup: func (interp: EoInterpreter) {
    x := interp stack pop()
    interp stack push(x)
    interp stack push(x)
}

/* loading builtins */

loadBuiltinWord: func (interp: EoInterpreter, name: String, f: Func(EoInterpreter)) {
    //"Loading builtin: %s" printfln(name)
    builtinWord := EoBuiltinWord new(name, f)
    interp rootNamespace add(name, builtinWord)
}

loadBuiltinWords: func (interp: EoInterpreter) {
    loadBuiltinWord(interp, "dup", dup)
}