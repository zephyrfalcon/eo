/* builtins.ooc */

import eotypes, eo

dup: func (interp: EoInterpreter) {
    x := interp stack pop()
    interp stack push(x)
    interp stack push(x)
}

plus: func (interp: EoInterpreter) {
    x := interp stack pop()
    y := interp stack pop()
    if (x instanceOf?(EoInteger) && y instanceOf?(EoInteger)) {
        result := EoInteger new((x as EoInteger) value + (y as EoInteger) value)
        interp stack push(result)
    }
    else
        Exception new("+ only works on numbers") throw()
}

def: func (interp: EoInterpreter) {
    /* ( lambda-word name -- ) */
    name := interp stack pop() as EoString
    word := interp stack pop() as EoUserDefWord
    /* FIXME: this should be the "current" namespace instead */
    interp userNamespace add(name value, word)
}

/* loading builtins */

loadBuiltinWord: func (interp: EoInterpreter, name: String, f: Func(EoInterpreter)) {
    //"Loading builtin: %s" printfln(name)
    builtinWord := EoBuiltinWord new(name, f)
    interp rootNamespace add(name, builtinWord)
}

loadBuiltinWords: func (interp: EoInterpreter) {
    loadBuiltinWord(interp, "dup", dup)
    loadBuiltinWord(interp, "+", plus)
    loadBuiltinWord(interp, "def", def)
}
