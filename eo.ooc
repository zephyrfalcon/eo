/* eo.ooc */

import structs/[ArrayList, Stack]
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
    toString: func -> String { value }
    /* difference between str and repr? */
}

EoSymbol: class extends EoType {
    value: String
    init: func(=value)
    toString: func -> String { value }
}

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
        return EoString new(token) /* FIXME */
    }
    return EoSymbol new(token)
}

EoInterpreter: class {
    stack := Stack<EoType> new()
    init: func
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
                "That's an %s with value %s!" printfln(value class name, value toString())
            )
        }
        println()
    }
}

repl := EoREPL new()
repl run()

