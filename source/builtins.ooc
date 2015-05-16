/* builtins.ooc */

import patch
import structs/[ArrayList, Stack]
import io/File
import eotypes, eo, namespace, tools
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
        result := EoInteger new((y as EoInteger) value + (x as EoInteger) value)
        interp stack push(result)
    }
    else
        Exception new("+ only works on numbers") throw()
}

/* lots of boilerplate in here; needs fixed */
minus: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    y := interp stack pop()
    if (x instanceOf?(EoInteger) && y instanceOf?(EoInteger)) {
        result := EoInteger new((y as EoInteger) value - (x as EoInteger) value)
        interp stack push(result)
    }
    else
        Exception new("- only works on numbers") throw()
}

/* lots of boilerplate here too; also, future versions of `>` will likely
 * support more types, like strings */
_gt: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    y := interp stack pop()
    if (x instanceOf?(EoInteger) && y instanceOf?(EoInteger)) {
        result := ((y as EoInteger) value > (x as EoInteger) value)
        interp stack push(result ? EoTrue : EoFalse)
    }
    else
        Exception new("> only works on numbers") throw()
}

def: func (interp: EoInterpreter, ns: Namespace) {
    /* ( lambda-word name -- ) */
    name := interp stack pop() as EoString
    blk := interp stack pop() as EoCodeBlock //EoUserDefWord
    word := EoUserDefWord new(blk, name value) /* block already has a namespace */
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

update: func (interp: EoInterpreter, ns: Namespace) {
    /* update ( value varname -- )
       Updates an existing variable. */
    eovar: EoVariable
    varns: Namespace
    varname := interp stack popCheck(EoString) as EoString
    value := interp stack pop()
    assert (varname value startsWith?("$"))
    /* note: we reuse the existing EoVariable object */
    (eovar, varns) = ns lookup_with_source(varname value)
    /* FIXME: segfaults if variable doesn't exist */
    eovar value = value
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
       TODO: Should this execute different things as well, like code blocks?
    */
    x := interp stack pop()  /* string or executable */
    match (x) {
        case (s: EoString) => {
            sv := parseToken((s as EoString) value)
            frame := EoStackFrame new(sv, ns)
            interp callStack push(frame)
            /* this should be picked up by the execution loop */
        }
        case (blk: EoCodeBlock) => {
            uw := blk asEoUserDefWord()
            frame := EoStackFrame new(uw, ns)
            interp callStack push(frame)
        }
        case =>
            frame := EoStackFrame new(x, ns)
            interp callStack push(frame)
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
     * later (e.g. namespaces, dictionaries). */
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

_if: func (interp: EoInterpreter, ns: Namespace) {
    /* if ( cond code-if-true code-if-false -- ) */
    codeIfFalse := interp stack popCheck(EoCodeBlock) as EoCodeBlock
    codeIfTrue := interp stack popCheck(EoCodeBlock) as EoCodeBlock
    cond := interp stack popCheck(EoBool) as EoBool
    blk := cond value ? codeIfTrue : codeIfFalse
    anonWord := blk asEoUserDefWord()
    frame := EoStackFrame new(anonWord, ns)
    interp callStack push(frame)
}

_include: func (interp: EoInterpreter, ns: Namespace) {
    /* include ( filename -- ) */
    filename := interp stack popCheck(EoString) as EoString
    data := File new(filename value) read()
    interp runCode(data, ns)
}

_import: func (interp: EoInterpreter, ns: Namespace) {
    /* import ( filename -- )
       Produces a module that is placed in the caller's namespace. */
    filename := interp stack popCheck(EoString) as EoString
    path := File new(filename value) getAbsolutePath()
    //"Absolute path: %s" printfln(path)
    shortName := getShortName(path)
    //"Shortname: %s" printfln(shortName)

    data := File new(filename value) read()
    newns := Namespace new(interp userNamespace)
    interp runCode(data, newns)
    // XXX need the name! derive from filename
    mod := EoModule new(newns) // FIXME: add name, path
    mod name = shortName; mod path = path
    // XXX maybe use absolute path for filename?
    // then create a WORD with that name that pushes the module
    w := makeWordThatReturns(interp, mod)
    // then place in current namespace (ns)
    ns add(shortName, w)
}

_print: func (interp: EoInterpreter, ns: Namespace) {
    /* ( x -- ) */
    x := interp stack pop()
    //x toString() print()
    x valueAsString() print()
}

repr: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    interp stack push(EoString new(x toString()))
}

to_str: func (interp: EoInterpreter, ns: Namespace) {
    x := interp stack pop()
    interp stack push(EoString new(x valueAsString()))
}

emit: func (interp: EoInterpreter, ns: Namespace) {
    /* ( charcode -- ) */
    charCode := interp stack popCheck(EoInteger) as EoInteger
    "%c" printf(charCode value)
    // output character...
}

/* FIXME: can later be written in pure Eo */
words: func (interp: EoInterpreter, ns: Namespace) {
    /* words ( -- ) */
    names := interp userNamespace all_names()
    names sort(|s1, s2| s1 > s2)
    for (name in names) "%s " printf(name)
    println()
}

_perc_show_call_stack: func (interp: EoInterpreter, ns: Namespace) {
    /* %show-call-stack ( <bool> -- )
       Show the contents of the call stack at every execution step. */
    onoff := interp stack popCheck(EoBool) as EoBool
    interp debugSettings showCallStack = onoff value
}

_perc_count_cycles: func (interp: EoInterpreter, ns: Namespace) {
    /* %count-cycles ( <bool> -- )
       Turn on cycle counting. */
    onoff := interp stack popCheck(EoBool) as EoBool
    interp debugSettings countCycles = onoff value
}

index: func (interp: EoInterpreter, ns: Namespace) {
    /* index ( list n -- list[n] )
       Get the item at position n of the list (indexing starts at 0).
    */
   // TODO: should work for strings as well
   // TODO: also support negative indexes
   // TODO: handle out-of-bounds indexen
   n := interp stack popCheck(EoInteger) as EoInteger
   indexable := interp stack pop()
   match indexable {
       case (list: EoList) => {
           elem := list data[n value]
           interp stack push(elem)
       }
       case =>
           "Error: index not supported on objects of type %s" \
             printfln(indexable class name)
   }
}

length: func (interp: EoInterpreter, ns: Namespace) {
    /* length ( list -- length )
       Get the length of a list. */
    // TODO: should also work with strings and possibly other types
    obj := interp stack pop()
    match obj {
        case (list: EoList) =>
            interp stack push(EoInteger new(list data size))
        case =>
            "Error: length not supported on objects of type %s" \
              printfln(obj class name)
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
    loadBuiltinWord(interp, "-", minus)
    loadBuiltinWord(interp, ">", _gt)
    loadBuiltinWord(interp, "def", def)
    loadBuiltinWord(interp, "defvar", defvar)
    loadBuiltinWord(interp, "[", lbracket)
    loadBuiltinWord(interp, "]", rbracket)
    loadBuiltinWord(interp, "exec", exec)
    loadBuiltinWord(interp, "lookup", lookup)
    loadBuiltinWord(interp, "execns", execns)
    loadBuiltinWord(interp, "if", _if)
    loadBuiltinWord(interp, "include", _include)
    loadBuiltinWord(interp, "print", _print)
    loadBuiltinWord(interp, "repr", repr)
    loadBuiltinWord(interp, "->string", to_str)
    loadBuiltinWord(interp, "emit", emit)
    loadBuiltinWord(interp, "import", _import)
    loadBuiltinWord(interp, "update", update)
    loadBuiltinWord(interp, "words", words)
    loadBuiltinWord(interp, "%show-call-stack", _perc_show_call_stack)
    loadBuiltinWord(interp, "%count-cycles", _perc_count_cycles)
    loadBuiltinWord(interp, "index", index)
    loadBuiltinWord(interp, "length", length)

    str_loadBuiltinWords(interp)
}

