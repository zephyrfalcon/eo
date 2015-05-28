/* builtins.ooc */

import patch
import structs/[ArrayList, Stack]
import text/StringTokenizer
import io/File
import eotypes, eo, namespace, tools
import builtins_str
import builtins_dict
import builtins_stack
import builtins_logic
import builtins_ns

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

_equals: func (interp: EoInterpreter, ns: Namespace) {
    /* ( = a b -- bool ) */
    x := interp stack popCheck(EoInteger) as EoInteger
    y := interp stack popCheck(EoInteger) as EoInteger
    result := (x value == y value) ? EoTrue : EoFalse
    interp stack push(result)
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
    if (eovar == null || varns == null)
        Exception new("Symbol not found: %s" format(varname value)) throw()
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
    /* exec ( string|executable -- )
       Execute the string as if it was a regular symbol found in code.
       NOTE: Currently only expects and executes ONE token. Also see #22.
       NOTE: Work correctly with word objects that happen to be on the stack
       (for example, after having been placed there by `lookup-here`).
       TODO: run strings with arbitrary code.
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
            /* this handles both words and non-executables correctly */
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
            if (value == null)
                Exception new("Symbol not found: %s" format(name value)) throw()
            else
                interp stack push(value)
        case => "Cannot look up in object of type (%s)" \
                printfln(module class name)
    }
}

lookup_here: func (interp: EoInterpreter, ns: Namespace) {
    name := interp stack popCheck(EoString) as EoString
    obj := ns lookup(name value)
    if (obj == null)
        Exception new("Symbol not found: %s" format(name value)) throw()
    else
        interp stack push(obj)
}
lookup_here_doc := \
"lookup-here ( name -- obj )
Look up the given string in the current namespace, and push the object
associated with it. This can be anything, including words."

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
    interp runCodeViaStack(data, ns)
}

_import: func (interp: EoInterpreter, ns: Namespace) {
    /* import ( filename -- )
       Produces a module that is placed in the caller's namespace. */
    /* XXX For now:
       - ONLY accepts single filenames (so no paths)
       - filenames are expected to be relative to libRootDir (i.e., in lib/)
       LATER: add support for paths and possibly absolute paths to import
       files are not in the lib directory.
    */
    filename := interp stack popCheck(EoString) as EoString
    fn := filename value
    if (!fn endsWith?(".eo")) fn += ".eo"

    path := File join(interp libRootDir, fn)
    if (!File new(path) exists?())
        Exception new("Cannot import %s: file does not exist" format(path)) \
                  throw()
    //"Absolute path: %s" printfln(path)
    shortName := getShortName(path) /* also strips extension */
    //"Shortname: %s" printfln(shortName)

    data := File new(path) read()
    /* create a namespace for the module, then a module object that uses this
     * namespace */
    newns := Namespace new(interp userNamespace)
    mod := EoModule new(newns) 
    mod name = shortName; mod path = path

    /* create a WORD with the shortname that pushes the module */
    w := makeWordThatReturns(interp, mod)
    /* place this word in current namespace (ns) */
    ns add(shortName, w)

    /* lastly: run code in module's namespace via usual mechanism */
    interp runCodeViaStack(data, newns)
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
   /* Note: in theory we could handle dicts as well, but because of the
    * integer requirement (see above) I will use a separate word `get` rather
    * than making this code too complicated. */
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
        case (dict: EoDict) =>
            interp stack push(EoInteger new(dict data size))
        case =>
            "Error: length not supported on objects of type %s" \
              printfln(obj class name)
    }
}

add_excl: func (interp: EoInterpreter, ns: Namespace) {
    // TODO: there should also be a plain `add` that creates a new list and
    // leaves the original one alone, but this is less efficient with
    // ooc-style lists.
    item := interp stack pop()
    list := interp stack popCheck(EoList) as EoList
    list data add(item)
}
add_excl_doc := \
"add! ( list item -- )
Add the given item to the (end of the) list, changing the list in-place."

doc: func (interp: EoInterpreter, ns: Namespace) {
    obj := interp stack pop()
    //doc: String = withDefault(obj description, "")
    doc := obj description == null ? "" : obj description
    interp stack push(EoString new(doc))
}
doc_doc := \
"doc ( obj -- docstring )
Get the docstring of the given object. Return an empty string if it has none."
doc_excl: func (interp: EoInterpreter, ns: Namespace) {
    docstring := interp stack popCheck(EoString) as EoString
    obj := interp stack pop()
    obj description = docstring value
}
doc_excl_doc := \
"doc! ( obj docstring -- )
Set the docstring for the given object."

hash: func (interp: EoInterpreter, ns: Namespace) {
    /* hash ( x -- hash(x) ) */
    obj := interp stack pop()
    h := obj hash()
    interp stack push(EoInteger new(h))
}

eq_qm: func (interp: EoInterpreter, ns: Namespace) {
    /* eq? ( a b -- bool ) */
    b := interp stack pop()
    a := interp stack pop()
    result := a equals?(b) ? EoTrue : EoFalse
    interp stack push(result)
}

id: func (interp: EoInterpreter, ns: Namespace) {
    /* id ( x -- id(x) ) */
    obj := interp stack pop()
    s: SizeT = obj as SizeT  
    /* note that obj is itself a pointer, technically */
    interp stack push(EoInteger new(s))
}

clear_excl: func (interp: EoInterpreter, ns: Namespace) {
    /* clear ( container -- container' ) */
    obj := interp stack pop()
    match (obj) {
        case (list: EoList) => list data clear()
        case (dict: EoDict) => dict data clear()
        case => Exception new("Cannot call 'clear!' on this type") throw()
    }
}

type: func (interp: EoInterpreter, ns: Namespace) {
    obj := interp stack pop()
    interp stack push(EoString new(obj type()))
}

hex: func (interp: EoInterpreter, ns: Namespace) {
    obj := interp stack popCheck(EoInteger) as EoInteger
    s := EoString new("%x" format(obj value))
    interp stack push(s)
}

// TODO: words to get ns from modules, code blocks, etc */

/*** loading builtins ***/

loadBuiltinWord: func (interp: EoInterpreter, name: String,
                       f: Func(EoInterpreter, Namespace),
                       description := "") {
    //"Loading builtin: %s" printfln(name)
    builtinWord := EoBuiltinWord new(name, f)
    builtinWord description = description
    interp rootNamespace add(name, builtinWord)
}

loadBuiltinWordInModule: func (targetNs: Namespace, name: String,
                               f: Func(EoInterpreter, Namespace),
                               description := "") {
    builtinWord := EoBuiltinWord new(name, f)
    builtinWord description = description
    targetNs add(name, builtinWord)
}

loadBuiltinWords: func (interp: EoInterpreter) {
    loadBuiltinWord(interp, "+", plus)
    loadBuiltinWord(interp, "-", minus)
    loadBuiltinWord(interp, "=", _equals)
    loadBuiltinWord(interp, ">", _gt)
    loadBuiltinWord(interp, "def", def)
    loadBuiltinWord(interp, "defvar", defvar)
    loadBuiltinWord(interp, "[", lbracket)
    loadBuiltinWord(interp, "]", rbracket)
    loadBuiltinWord(interp, "exec", exec)
    loadBuiltinWord(interp, "lookup", lookup)
    loadBuiltinWord(interp, "lookup-here", lookup_here, lookup_here_doc)
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
    loadBuiltinWord(interp, "hash", hash)
    loadBuiltinWord(interp, "id", id)
    loadBuiltinWord(interp, "type", type)
    loadBuiltinWord(interp, "clear!", clear_excl)
    loadBuiltinWord(interp, "eq?", eq_qm)
    loadBuiltinWord(interp, "add!", add_excl, add_excl_doc)
    loadBuiltinWord(interp, "doc", doc, doc_doc)
    loadBuiltinWord(interp, "doc!", doc_excl, doc_excl_doc)
    loadBuiltinWord(interp, "hex", hex)

    /* builtins_stack */
    loadBuiltinWord(interp, "dup", dup)
    loadBuiltinWord(interp, "drop", drop)
    loadBuiltinWord(interp, "swap", swap)
    loadBuiltinWord(interp, "over", over)
    loadBuiltinWord(interp, "stack-empty?", stack_empty_qm)
    loadBuiltinWord(interp, "pick", pick)

    /* builtins_dict */
    loadBuiltinWord(interp, "dict", dict)
    loadBuiltinWord(interp, "put!", put_excl)
    loadBuiltinWord(interp, "get", _get)
    loadBuiltinWord(interp, "keys", keys)
    loadBuiltinWord(interp, "values", values)
    loadBuiltinWord(interp, "items", items)

    /* builtins_logic */
    loadBuiltinWord(interp, "not", not)
    loadBuiltinWord(interp, "and", and)
    loadBuiltinWord(interp, "or", or)

    /* builtins_ns */
    loadBuiltinWord(interp, "rootns", rootns)
    loadBuiltinWord(interp, "userns", userns)
    loadBuiltinWord(interp, "thisns", thisns)
    loadBuiltinWord(interp, "newns", newns)
    loadBuiltinWord(interp, "newns*", newns)
    loadBuiltinWord(interp, "ns*", _ns)

    str_loadBuiltinWords(interp)
}

