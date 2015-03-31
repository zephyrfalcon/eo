/* eo.ooc */

import structs/[ArrayList, HashMap, Stack]
import text/[EscapeSequence, Regexp, Shlex, StringTokenizer]

EO_VERSION := "0.0.1"

/* monkey patching :-) */

extend Regexp {
    split: func (s: String) -> ArrayList<String> {
        results := ArrayList<String> new()
        while (true) {
            matchobj := re_word matches(s)
            if (matchobj == null) break

            token := matchobj group(0)
            cutoff := matchobj groupStart(0) + matchobj groupLength(0)
            results add(token)

            s = s substring(cutoff)
        }
        return results
    }
}

/* Namespace */

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
    lookup: func(key: String) -> EoType {
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

    lookup_with_source: func(key: String) -> (EoType, Namespace) {
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
}

/* Eo built-in types */

EoType: abstract class {
    toString: abstract func -> String
}

EoInteger: class extends EoType {
    value: Int
    init: func(=value)
    toString: func -> String { value toString() }
}

EoString: class extends EoType {
    value: String
    init: func(=value)
    toString: func -> String { "\"" + value + "\"" }
    /* difference between str and repr? */
}

EoSymbol: class extends EoType {
    value: String
    init: func(=value)
    toString: func -> String { value }
}

/* we need an EoList, but not an EoStack; they're the same thing.
   Even structs/Stack is implemented with an ArrayList, so we can treat them
   the same.
*/

/*****/

re_word := Regexp compile("(\"[^\"]*\")|(\\S+)")

tokenize: func(data: String) -> ArrayList<String> {
    return re_word split(data)
}

print_tokens: func(tokens: ArrayList<String>) {
    tokens each(|token| token println())
}

re_number := Regexp compile("\\d+")

parseToken: func(token: String) -> EoType {
    if (re_number matches(token)) {
        return EoInteger new(token toInt())
    }
    if (token startsWith?("\"") && token endsWith?("\"")) {
        return EoString new(token[1..-2]) /* TODO: (un)escaping */
        /* NOTE: ooc slicing != Python slicing. */
    }
    return EoSymbol new(token)
}

EoInterpreter: class {
    stack := Stack<EoType> new()
    init: func

    push: func (x: EoType) {
        stack push(x)
    }

    execute: func (x: EoType) {
        match (x) {
            case i: EoInteger => push(i)
            case s: EoString => push(s)
            case sym: EoSymbol => "Not implemented yet" println()
            case => "Unknown" println()
        }
    }

    stackRepr: func -> String {
        strValues := stack data map(|x| (x as EoType) toString())
        return "[" + strValues join(" ") + "]"
        /*
        result := "["
        strValues := stack data map(|x| (x as EoType) toString())
        for ((index, s) in strValues) {
            result append(s)
            if (index < stack data size - 1)
                result append(" ")
        }
        result append("]")
        return result
        */
    }
}

EoREPL: class {
    interpreter := EoInterpreter new()
    prompt := "> "
    greeting: String  /* apparently cannot be initialized with "" + format */

    init: func() {
        greeting = "Welcome to Eo version %s." format(EO_VERSION)
    }

    run: func() {
        greeting println()
        while (stdin hasNext?()) {
            stdout write(prompt)
            line := stdin readLine()
            tokens := tokenize(line)
            print_tokens(tokens)
            //"\"%s\"" printfln(EscapeSequence escape(line))
            tokens each(|token|
                value := parseToken(token)
                //"That's an %s with value %s!" printfln(value class name, value toString())
                interpreter execute(value)
                interpreter stackRepr() println()
            )
        }
        println()
    }
}

repl := EoREPL new()
repl run()

