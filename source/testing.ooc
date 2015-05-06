/* testing.ooc */
/* Running Eo tests. Part of the regular eo-main executable. */

import eo, eotypes
import structs/ArrayList
import io/File
import text/StringTokenizer

EoTestResult: enum { SUCCESS, FAILURE, ERROR }

EoTest: class {
    description, input, output, source: String
    // TODO: setting that indicates whether we start with a fresh interpreter?
    init: func (=input, =output)
    init: func ~withDesc (=input, =output, =description, =source)

    run: func (interp: EoInterpreter) -> (EoTestResult, String) {
        try {
            interp runCode(input, interp userNamespace)
        }
        catch (e: Exception) {
            return (EoTestResult ERROR, e message)
        }

        sr := interp stackRepr()
        if (sr == output)
            return (EoTestResult SUCCESS, "")
        else {
            failMsg := "Expected: %s, got %s instead" format(output, sr)
            return (EoTestResult FAILURE, failMsg)
        }
    }
}

EoTestRunner: class {
    tests := ArrayList<EoTest> new()
    passed, failed, error: Int
    init: func

    add: func (input, output: String) {
        eotest := EoTest new(input, output)
        tests add(eotest)
    }

    readFromFile: func (filename: String) {
        data := File new(filename) read()
        lines := data split("\n")
        code := ""
        title := ""
        for (line in lines) {
            if (line startsWith?("--")) {
                // the last comment will make up the title of the test
                title = line substring(2) trim()
            }
            else if (line startsWith?("=>")) {
                result := line substring(3) trim()
                code = code trim()
                if (title == "") title = code
                tst := EoTest new(code, result, title, filename)
                tests add(tst)
                code = title = ""
            }
            else {
                if (line trim() == "") continue // skip empty lines
                code = code + "\n" + line
            }
        }
    }

    run: func {
        passed = failed = error = 0
        interp := EoInterpreter new()
        for (t in tests) {
            interp stack clearStack()
            "%s... " printf(t description)
            (result, message) := t run(interp)
            match (result) {
                case EoTestResult SUCCESS =>
                    "OK" println()
                    passed += 1
                case EoTestResult FAILURE =>
                    "FAIL" println()
                    "  %s" printfln(message)
                    failed += 1
                case EoTestResult ERROR =>
                    "ERROR" println()
                    "  %s" printfln(message)
                    error += 1
                case => "?!" println()
            }
        }
        "Ran %d tests. Passed: %d. Failed: %d. Error: %d." printfln( \
            tests size, passed, failed, error)
    }
}

/*** read tests from files ***/

runEoTests: func (path: String) {
    testFiles := ArrayList<String> new()
    for (fn in File new(path) getChildren()) {
        if (fn path endsWith?(".txt"))
            testFiles add(fn path)
            "Loading: %s" printfln(fn path)
    }
    runner := EoTestRunner new()
    for (fn in testFiles)
        runner readFromFile(fn)
    runner run()
}

