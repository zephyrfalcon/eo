/* eo.ooc */

import structs/[ArrayList, HashMap, Stack]
import text/[EscapeSequence, Regexp]
import patch
import namespace, eotypes
import builtins

EO_VERSION := "0.0.2"

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
    stack := Stack<EoType> new()  /* later: must be a "StackStack" */
    rootNamespace := Namespace new()
    userNamespace := Namespace new(rootNamespace)
    currentWord := ArrayList<EoType> new()
    inWordDef := false
    /* something not right here... we need to deal with nested { }
     * definitions... maybe using a stack? */

    init: func {
        loadBuiltinWords(this)
    }

    parse: func (data: String) -> ArrayList<EoType> {
        code := ArrayList<EoType> new()
        tokens := tokenize(data)
        for (token in tokens) {
            match (token) {
                //case "{" => ...
                //case "}" => ...
                case =>
                    x := parseToken(token)
                    code add(x)
            }
        }
        return code
    }

    execute: func (x: EoType) {
        match (x) {
            case i: EoInteger => stack push(i)
            case s: EoString => stack push(s)
            case sym: EoSymbol =>
                value := userNamespace lookup(sym value)
                if (value == null)
                    "Symbol not found: %s" printfln(sym toString())
                    /* later: raise an exception? */
                else
                    execute(value)
            case bw: EoBuiltinWord => bw f(this)
            //case uw: EoUserDefWord => 
            case => "Unknown" println()
        }
    }

    stackRepr: func -> String {
        strValues := stack data map(|x| (x as EoType) toString())
        return "[" + strValues join(" ") + "]"
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
            code := interpreter parse(line)
            for (c in code) interpreter execute(c)
            interpreter stackRepr() println()
        }
        println()
    }
}

repl := EoREPL new()
repl run()

