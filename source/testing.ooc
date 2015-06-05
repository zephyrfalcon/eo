/* testing.ooc */
/* Running Eo tests. Part of the regular eo-main executable. */

import eo, eotypes
import structs/ArrayList
import io/File
import text/StringTokenizer
import os/Terminal

EoTestStatus: enum { SUCCESS, FAILURE, ERROR }

EoTestResult: class {
    status: EoTestStatus
    message: String
    filename: String
    init: func (=status, =message, =filename)
}

EoTest: class {
    description, input, output, filename: String
    // TODO: setting that indicates whether we start with a fresh interpreter?
    init: func (=input, =output)
    init: func ~withDesc (=input, =output, =description, =filename)

    run: func (interp: EoInterpreter) -> EoTestResult { 
        try {
            interp runCodeViaStack(input, interp userNamespace)
            interp executeAll()
        }
        catch (e: Exception) {
            return EoTestResult new(EoTestStatus ERROR, e message, filename)
        }

        sr := interp stackRepr()
        if (sr == output)
            return EoTestResult new(EoTestStatus SUCCESS, "", filename)
        else {
            failMsg := "Expected: %s, got %s instead" format(output, sr)
            return EoTestResult new(EoTestStatus FAILURE, failMsg, filename)
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
            result := t run(interp)
            match (result status) {
                case EoTestStatus SUCCESS =>
                    "OK" println()
                    passed += 1
                case EoTestStatus FAILURE =>
                    Terminal setFgColor(Color red)
                    "FAIL" println()
                    Terminal reset()
                    "File: %s" printfln(result filename)
                    "  %s" printfln(result message)
                    failed += 1
                case EoTestStatus ERROR =>
                    Terminal setFgColor(Color red)
                    "ERROR" println()
                    Terminal reset()
                    "File: %s" printfln(result filename)
                    "  %s" printfln(result message)
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

