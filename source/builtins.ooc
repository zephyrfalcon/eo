/* builtins.ooc */

import structs/[ArrayList, Stack]
import eotypes, eo, namespace
import builtins_str

dup: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    interp stack push(x)
    interp stack push(x)
}

plus: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    y := interp stack pop()
    if (x instanceOf?(EoInteger) && y instanceOf?(EoInteger)) {
        result := EoInteger new((x as EoInteger) value + (y as EoInteger) value)
        interp stack push(result)
    }
    else
        Exception new("+ only works on numbers") throw()
}

def: func (interp: EoInterpreter, ns: Namespace) {
    /* ( lambda-word name -- ) */
    name := interp stack pop() as EoString
    blk := interp stack pop() as EoCodeBlock //EoUserDefWord
    word := EoUserDefWord new(blk)  /* block already has a namespace */
    ns add(name value, word)
}

defvar: func (interp: EoInterpreter, ns: Namespace) {
    /* ( value varname -- ) */
    varname := interp stack pop() as EoString
    value := interp stack pop()
    assert (varname value startsWith?("$"))
    /* NOTE: this is the only place where we enforce that variable names
     * should start with a '$'. Otherwise it's treated as any other symbol. */
    realname := varname value substring(1)
    e := EoVariable new(realname, value)
    ns add(varname value, e)
}

lbracket: func (interp: EoInterpreter, ns: Namespace) {
    /* [ ( -- ) */
    interp stack pushStack(Stack<EoType> new())
}

rbracket: func (interp: EoInterpreter, ns: Namespace) {
    /* ] ( -- lst ) */
    stk: Stack<EoType> = interp stack popStack()
    lst := EoList new(stk data)
    interp stack push(lst)
}

exec: func (interp: EoInterpreter, ns: Namespace) {
    /* exec ( string|executable -- ? )
       Execute the string as if it was a regular symbol found in code.
       NOTE: Currently only expects and executes ONE token. Also see #22.
    */
    x := interp stack pop()  /* string or executable */
    match (x) {
        case (s: EoString) => {
            sv := parseToken((s as EoString) value)
            frame := EoStackFrame new(sv, ns)
            interp pushToCallStack(frame)
            /* XXX will this suffice? it should be picked up by the execution
             * loop... */
        }
        case =>
            frame := EoStackFrame new(x, ns)
            interp pushToCallStack(frame)
    }
}

// execns
// is really the same as `lookup exec`, assuming `exec` accepts words and
// such, nespa? could be in stdlib, but let's keep it built-in instead, at
// least for now.

execns: func (interp: EoInterpreter, ns: Namespace) {
    /* execns ( module name -- ? )
       Lookup name in module/namespace/etc and execute it. */
    //name := interp stack popCheck(EoString) as EoString
    //mod := interp stack pop()
    lookup(interp, ns)
    exec(interp, ns)
}

lookup: func (interp: EoInterpreter, ns: Namespace) {
    /* lookup ( module name -- value ) */
    /* for now, only works for modules, but other types will probably be added
     * later. */
    name := interp stack popCheck(EoString) as EoString
    module := interp stack pop() // later: can be other things as well
    match (module) {
        case (m: EoModule) =>
            value := m namespace lookup(name value)
            interp stack push(value)
        case => "Cannot look up in object of type (%s)" \
                printfln(module class name)
    }
}

/* loading builtins */

loadBuiltinWord: func (interp: EoInterpreter, name: String,
                       f: Func(EoInterpreter, Namespace)) {
    //"Loading builtin: %s" printfln(name)
    builtinWord := EoBuiltinWord new(name, f)
    interp rootNamespace add(name, builtinWord)
}

loadBuiltinWordInModule: func (targetNs: Namespace, name: String,
                               f: Func(EoInterpreter, Namespace)) {
    builtinWord := EoBuiltinWord new(name, f)
    targetNs add(name, builtinWord)
}

loadBuiltinWords: func (interp: EoInterpreter) {
    loadBuiltinWord(interp, "dup", dup)
    loadBuiltinWord(interp, "+", plus)
    loadBuiltinWord(interp, "def", def)
    loadBuiltinWord(interp, "defvar", defvar)
    loadBuiltinWord(interp, "[", lbracket)
    loadBuiltinWord(interp, "]", rbracket)
    loadBuiltinWord(interp, "exec", exec)
    loadBuiltinWord(interp, "lookup", lookup)
    loadBuiltinWord(interp, "execns", execns)

    str_loadBuiltinWords(interp)
}

