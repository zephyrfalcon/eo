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
import builtins_str
import builtins_debug
import builtins_arith
import module_sys

def: func (interp: EoInterpreter, ns: Namespace) {
    /* ( code-block name -- ) */
    name := interp stack pop() as EoString
    blk := interp stack pop() as EoCodeBlock 
    word := ns addWord(name value, blk)
    interp lastDefined = word
}

defvar: func (interp: EoInterpreter, ns: Namespace) {
    /* ( value varname -- ) */
    varname := interp stack pop() as EoString
    value := interp stack pop()
    /* NOTE: addVariable is the only place where we enforce that variable names
     * should start with a '$'. Otherwise it's treated as any other symbol. */
    v := ns addVariable(varname value, value)
    interp lastDefined = v
}

update: func (interp: EoInterpreter, ns: Namespace) {
    /* update ( value var -- )
       Updates an existing variable in the current namespace. 
       Value precedes variable names to mirror `defvar` usage.
       `var` can be a name (string) or a variable object.
    */
    eovar: EoVariable
    varns: Namespace
    var := interp stack pop()
    value := interp stack pop()
    match (var) {
        case (varname: EoString) =>
            assert (varname value startsWith?("$"))
            /* note: we reuse the existing EoVariable object */
            (eovar, varns) = ns lookup_with_source(varname value)
            if (eovar == null || varns == null)
                Exception new("Symbol not found: %s" format(varname value)) throw()
            eovar value = value
        case (v: EoVariable) =>
            v value = value
        case => raise("update: needs variable object or variable name (string)")
    }
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
       TODO: run strings with arbitrary code. In the new situation we should
       also be able to handle e.g. "sys:version" (macro expansion).
    */
    x := interp stack pop()  /* string or executable */
    match (x) {
        case (s: EoString) => {
            // FIXME
            sv := parseToken((s as EoString) value)
            frame := EoStackFrame new(sv, ns)
            interp callStack push(frame)
            /* this should be picked up by the execution loop */
        }
        case (blk: EoCodeBlock) => {
            uw := blk asEoUserDefWord()
            /* reuseNamespace = true? not sure */
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
    _get(interp, ns)
    exec(interp, ns)
}

exec_with: func (interp: EoInterpreter, ns: Namespace) {
    /* exec-with ( code module|namespace -- )
       Execute the given code in the given module or namespace. */
    context := interp stack pop()
    code := interp stack popCheck(EoCodeBlock) as EoCodeBlock
    match (context) {
        case (m: EoModule) => dummy()
        case (n: EoNamespace) => dummy()
        case => raise("exec-with must be run with module or namespace")
    }
}

_get: func (interp: EoInterpreter, ns: Namespace) {
    /* get ( container key -- value ) 
       General: look up the given 'key' in the container.
       If container is a:
       - module/namespace: look up the name (a string) and return the value.
         DOES NOT execute anything. If you want that, follow it by `execns` or
         use `container:name` syntax.
       - list/string: return the value at index 'key' (must be an integer).
       - dict: return the value associated with the given key (must be
         immutable).
    */
    key := interp stack pop()
    container := interp stack pop() // later: can be other things as well

    match (container) {

        case (m: EoModule) =>
            assertInstance(key, EoString)
            value := m namespace lookup((key as EoString) value)
            if (value == null)
                raise("Symbol not found: %s" format((key as EoString) value))
            else
                interp stack push(value)

        case (n: EoNamespace) =>
            assertInstance(key, EoString)
            value := n namespace lookup((key as EoString) value)
            if (value == null)
                raise("Symbol not found: %s" format((key as EoString) value))
            else
                interp stack push(value)

        case (d: EoDict) =>  
            if (key mutable?())
                raise("Cannot look up in dictionaries with key of type %s" \
                      format(key class name))
            value: EoType = d data get(key) as EoType
            if (value == null)
                raise("Key not found: %s" format(key toString()))
            interp stack push(value)

        case (list: EoList) =>  
            assertInstance(key, EoInteger)
            value := list data[(key as EoInteger) value]
            interp stack push(value)

        case (s: EoString) =>
            assertInstance(key, EoInteger)
            value := s value[(key as EoInteger) value] toString()
            interp stack push(EoString new(value))

        case => raise("Cannot look up in object of type (%s)" \
                      format(container class name))
    }
}

/* XXX can be written in Eo now? 
   NO!! Not until we have a decent way to get the caller's namespace. (But
   since that is ill-defined, that might not happen. Until then, the builtin
   version does what it should do. 
 */
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
    newns := Namespace new(interp rootNamespace)  
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

length: func (interp: EoInterpreter, ns: Namespace) {
    /* length ( container -- length )
       Get the length of a container (string/list/dict). */
    obj := interp stack pop()
    match obj {
        case (list: EoList) =>
            interp stack push(EoInteger new(list data size))
        case (dict: EoDict) =>
            interp stack push(EoInteger new(dict data size))
        case (s: EoString) =>
            interp stack push(EoInteger new(s value length()))
        case =>
            raise("Error: length not supported on objects of type %s" \
                  format(obj class name))
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
    result := EoFalse
    if (a class == b class)
        result = a equals?(b) ? EoTrue : EoFalse
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

mutable_qm: func (interp: EoInterpreter, ns: Namespace) {
    /* mutable? ( obj -- bool ) */
    obj := interp stack pop()
    result := obj mutable?() ? EoTrue : EoFalse
    interp stack push(result)
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

set_excl: func (interp: EoInterpreter, ns: Namespace) {
    /* set! ( container key value -- ) 
       If container is a:
       - dict: Add (key, value) where key can be any immutable EoType
       - module or namespace: Set key to value. If key is a variable, then the
         value will be wrapped in an EoVariable before it is set. Any other
         key can be associated with any value.
         [XXX this is asymmetrical with def/defvar; should ns:!foo require a
         code block and then create a word in the namespace? if so, we also
         need a way to manipulate a namespace's "raw" values...]
       - list: Set index indicated by key (which must be an integer) to value.
    */
    value := interp stack pop() as EoType
    key := interp stack pop() as EoType
    container := interp stack pop() as EoType

    match (container) {

        case (dict: EoDict) =>
            dict add(key, value)

        case (mod: EoModule) =>
            if (!key instanceOf?(EoString))
                Exception new("Module names must be strings") throw()
            if ((key as EoString) value startsWith?("$"))
                mod namespace addVariable((key as EoString) value, value)
            else {
                assertInstance(value, EoCodeBlock)
                mod namespace addWord((key as EoString) value, value as EoCodeBlock)
            }

        case (xns: EoNamespace) => 
            if (!key instanceOf?(EoString))
                Exception new("Namespace names must be strings") throw()
            if ((key as EoString) value startsWith?("$"))
                xns namespace addVariable((key as EoString) value, value)
            else {
                assertInstance(value, EoCodeBlock)
                xns namespace addWord((key as EoString) value, value as EoCodeBlock)
        }

        case (list: EoList) => 
            if (!key instanceOf?(EoInteger))
                Exception new("List indexes must be integers") throw()
            list data[(key as EoInteger) value] = value

        case => Exception new("set!: Unsupported type: %s" \
                format(value class name)) throw()
    }
}

set_raw_excl: func (interp: EoInterpreter, ns: Namespace) {
    /* set-raw! ( container key value -- ) 
       Like `set!`, but if container is a namespace or a module, then it sets
       the name to the given value without checking it, or converting it to a
       variable or word. This is meant to give us direct access to a
       namespace; it is not symmetrical with `def` and `defvar`. */
    value := interp stack pop() as EoType
    key := interp stack pop() as EoType
    container := interp stack pop() as EoType

    match (container) {
        case (mod: EoModule) =>
            if (!key instanceOf?(EoString))
                Exception new("Module names must be strings") throw()
            mod namespace add((key as EoString) value, value)
        case (xns: EoNamespace) => 
            if (!key instanceOf?(EoString))
                Exception new("Namespace names must be strings") throw()
            xns namespace add((key as EoString) value, value)
        case => 
            /* delegate to set_excl */
            interp stack push(container)
            interp stack push(key)
            interp stack push(value)
            set_excl(interp, ns)
    }
}


del_excl: func (interp: EoInterpreter, ns: Namespace) {
    /* del! ( container key -- )
       Delete the given name/key from the container (which must be a
       dictionary, module, namespace or list). */
    key := interp stack pop()
    container := interp stack pop()
    match (container) {
        case (dict: EoDict) => dict data remove(key)
        case (list: EoList) => 
            if (!key instanceOf?(EoInteger))
                Exception new("del!: index must be integer") throw()
            else
                list data removeAt((key as EoInteger) value)
        case (mod: EoModule) => 
            if (!key instanceOf?(EoString))
                Exception new("del!: name must be string") throw()
            else
                mod namespace delete((key as EoString) value)
        case (xns: EoNamespace) => 
            if (!key instanceOf?(EoString))
                Exception new("del!: name must be string") throw()
            else 
                xns namespace delete((key as EoString) value)
        case => Exception new("Unsupported type: %s" \
                format(container class name)) throw()
    }
}

contains_qm: func (interp: EoInterpreter, ns: Namespace) {
    /* contains? ( obj key -- bool ) 
       Return true if the given container (a list, string, dict, module,
       namespace) contains the given "key".
       For dicts, namespaces and modules, this is actually a key/name.
       For lists, we check if the item is in the list.
       For strings, we check if key is a substring of container. 
    */
   key := interp stack pop()
   container := interp stack pop()
   result: Bool = false
   match (container) {
       case (s: EoString) => 
           if (!key instanceOf?(EoString))
               raise("")
           else
               result = s value find((key as EoString) value, 0) > -1
       case (list: EoList) => 
           //result = (list data indexOf(key) != -1)
           /* note: using ArrayList.indexOf doesn't work, since List has its
            * own comparison method, and the compiler balks if we try to
            * replace it like we do in EoDict <frown> */
           for (elem in list data) {
               if (elem equals?(key)) { result = true; break }
           }
       case (dict: EoDict) =>
           result = dict data contains?(key)
       case (mod: EoModule) => 
           if (!key instanceOf?(EoString))
               raise("")
           else
              result = mod namespace hasName?((key as EoString) value)
       case (n: EoNamespace) => 
           if (!key instanceOf?(EoString))
               raise("")
           else
               result = n namespace hasName?((key as EoString) value)
       case => Exception new("Unsupported type: %s" \
               format(container class name)) throw()
   }
   interp stack push(result ? EoTrue : EoFalse)
}

code: func (interp: EoInterpreter, ns: Namespace) {
    /* code ( block -- words ) */
    blk := interp stack popCheck(EoCodeBlock) as EoCodeBlock
    interp stack push(EoList new(blk words))
}

block: func (interp: EoInterpreter, ns: Namespace) {
    /* block ( word -- code-block ) */
    w := interp stack popCheck(EoUserDefWord) as EoUserDefWord
    interp stack push(w code)
}

_cmp: func (interp: EoInterpreter, ns: Namespace) {
    /* cmp ( a b -- c ) 
     Returns -1 if a < b, 1 if a > b, and 0 otherwise. */
    b := interp stack pop()
    a := interp stack pop()
    c: Int
    /*
    if (a class != b class) 
        c = cmp(a type(), b type())
    else
        c = a cmp(b)
    */
    c = eocmp(a, b)
    interp stack push(EoInteger new(c))
}

append: func (interp: EoInterpreter, ns: Namespace) {
    /* append ( seq1 seq2 -- seq3 )
       Append the two sequences (strings or lists). */
    seq2 := interp stack pop()
    seq1 := interp stack pop()
    match (seq1) {
        case (s: EoString) =>
            seq3 := EoString new(s value + (seq2 as EoString) value)
            interp stack push(seq3)
        case (list: EoList) => dummy()
        case => raise("append: Unsupported type: %s" format(seq1 class name))
    }
}

underscore: func (interp: EoInterpreter, ns: Namespace) {
    if (interp lastDefined == null)
        raise("no word or variable defined")
    interp stack push(interp lastDefined)
}

tags: func (interp: EoInterpreter, ns: Namespace) {
    /* tags ( obj -- tags ) */
    obj := interp stack pop()
    /* we don't use ooc's map here to avoid problems with List vs ArrayList */
    eotaglist := EoList new()
    for (s in obj tags)
        eotaglist data add(EoString new(s))
    interp stack push(eotaglist)
}

tags_excl: func (interp: EoInterpreter, ns: Namespace) {
    /* tags! ( obj tags -- ) */
    tags := interp stack popCheck(EoList) as EoList
    obj := interp stack pop()
    t := ArrayList<String> new()
    for (e in tags data) {
        if (e instanceOf?(EoString))
            t add((e as EoString) value)
        else
            raise("tags!: tags must be strings")
    }
    obj tags = t
}

_regex: func (interp: EoInterpreter, ns: Namespace) {
    /* regex ( str -- regex ) */
    s := interp stack popCheck(EoString) as EoString
    reg := EoRegex new(s value)
    interp stack push(reg)
}

module: func (interp: EoInterpreter, ns: Namespace) {
    /* module ( -- module ) */
    mod := EoModule new(interp rootNamespace)
    interp stack push(mod)
}

reverse: func (interp: EoInterpreter, ns: Namespace) {
    /* reverse ( seq -- qes ) 
       Reverse a sequence. Does not modify the sequence in-place. */
    seq := interp stack pop()
    match (seq) {
        case (s: EoString) => 
            t := s value reverse()
            interp stack push(EoString new(t))
        case (list: EoList) =>
            revlist := list data reverse() as ArrayList<EoType>
            interp stack push(EoList new(revlist))
        case => raise("Cannot reverse this type: %s" format(seq class name))
    }
}

reverse_excl: func (interp: EoInterpreter, ns: Namespace) {
    /* reverse! ( list -- ) 
       Reverse a list in-place. */
    list := interp stack popCheck(EoList) as EoList
    list data reverse!()
}

sort_excl: func (interp: EoInterpreter, ns: Namespace) {
    /* sort! ( list -- )
       Sort a list in-place. */
    list := interp stack popCheck(EoList) as EoList
    qsort(list data, eocmp)
}

/* we will be able to write this in Eo, later:
   $list copy sort!
   We do need a way to copy things first. */
sort: func (interp: EoInterpreter, ns: Namespace) {
    /* sort ( list -- list' )
       Return a sorted list, leaving the original list unchanged. */
    list := interp stack popCheck(EoList) as EoList
    list2 := list copy()
    qsort(list2 data, eocmp)
    interp stack push(list2)
}

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
    loadBuiltinWord(interp, "def", def)
    loadBuiltinWord(interp, "defvar", defvar)
    loadBuiltinWord(interp, "[", lbracket)
    loadBuiltinWord(interp, "]", rbracket)
    loadBuiltinWord(interp, "exec", exec)
    loadBuiltinWord(interp, "get", _get)
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
    loadBuiltinWord(interp, "set!", set_excl)
    loadBuiltinWord(interp, "del!", del_excl)
    loadBuiltinWord(interp, "set-raw!", set_raw_excl)
    loadBuiltinWord(interp, "contains?", contains_qm)
    loadBuiltinWord(interp, "code", code)
    loadBuiltinWord(interp, "block", block)
    loadBuiltinWord(interp, "cmp", _cmp)
    loadBuiltinWord(interp, "mutable?", mutable_qm)
    loadBuiltinWord(interp, "append", append)
    loadBuiltinWord(interp, "_", underscore)
    loadBuiltinWord(interp, "tags", tags)
    loadBuiltinWord(interp, "tags!", tags_excl)
    loadBuiltinWord(interp, "regex", _regex)
    loadBuiltinWord(interp, "module", module)
    loadBuiltinWord(interp, "reverse", reverse)
    loadBuiltinWord(interp, "reverse!", reverse_excl)
    loadBuiltinWord(interp, "sort!", sort_excl)
    loadBuiltinWord(interp, "sort", sort)

    /* builtins_stack */
    loadBuiltinWord(interp, "dup", dup)
    loadBuiltinWord(interp, "drop", drop)
    loadBuiltinWord(interp, "swap", swap)
    loadBuiltinWord(interp, "over", over)
    loadBuiltinWord(interp, "stack-empty?", stack_empty_qm)
    loadBuiltinWord(interp, "pick", pick)
    loadBuiltinWord(interp, "rol", rol)

    /* builtins_dict */
    loadBuiltinWord(interp, "dict", dict)
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
    loadBuiltinWord(interp, "newns*", newns_star)
    loadBuiltinWord(interp, "ns", _ns)
    loadBuiltinWord(interp, "names", names)
    loadBuiltinWord(interp, "all-names", all_names)
    loadBuiltinWord(interp, "parent", parent)
    loadBuiltinWord(interp, "find-caller-ns", find_caller_ns)
    loadBuiltinWord(interp, "ns->alist", ns_to_alist)

    /* builtins_str */
    loadBuiltinWord(interp, "upper", upper)
    loadBuiltinWord(interp, "split*", split_star)

    /* builtins_debug */
    loadBuiltinWord(interp, "%show-call-stack", _perc_show_call_stack)
    loadBuiltinWord(interp, "%count-cycles", _perc_count_cycles)
    loadBuiltinWord(interp, "%show-tokens", _perc_show_tokens)

    /* builtins_arith */
    loadBuiltinWord(interp, "+", plus)
    loadBuiltinWord(interp, "-", minus)
    loadBuiltinWord(interp, "=", _equals)
    loadBuiltinWord(interp, ">", _gt)
    loadBuiltinWord(interp, "<", _lt)

    /* built-in modules */
    sys_loadBuiltinWords(interp)
}

