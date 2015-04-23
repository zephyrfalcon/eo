/* testing.ooc */
/* Running Eo tests. Part of the regular eo-main executable. */

import eo, eotypes
import structs/ArrayList
import io/File
import text/StringTokenizer

EoTestResult: enum { SUCCESS, FAILURE, ERROR }

EoTest: class {
    description, input, output: String
    // TODO: setting that indicates whether we start with a fresh interpreter?
    init: func (=input, =output)
    init: func ~withDesc (=input, =output, =description)

    run: func -> (EoTestResult, String) {
        // blah...
        return (EoTestResult SUCCESS, "")
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
        source := ""
        title := ""
        for (line in lines) {
            if (line startsWith?("#")) {
                // the last comment will make up the title of the test
                title := line substring(2)
            }
            else if (line startsWith?("=>")) {
                result := line substring(3) trim()
                source = source trim()
                if (title == "") title = source
                tst := EoTest new(source, result, title)
                tests add(tst)
                source = title = ""
            }
            else {
                if (line trim() == "") continue // skip empty lines
                source = source + "\n" + line
            }
        }
    }

    run: func {
        passed = failed = error = 0
        // set up EoInterpreter...
        for (t in tests) {
            t run()  // FIXME
        }
    }
}

// TODO: read tests from files

runEoTests: func {
    runner := EoTestRunner new()
    runner readFromFile("tests/abc.txt") // FIXME: better path handling
    runner run()
}

