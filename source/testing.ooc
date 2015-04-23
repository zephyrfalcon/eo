/* testing.ooc */
/* Running Eo tests. Part of the regular eo-main executable. */

import eo, eotypes
import structs/ArrayList

EoTestResult: enum { SUCCESS, FAILURE, ERROR }

EoTest: class {
    input: String
    output: String
    init: func (=input, =output)

    run: func -> (EoTestResult, String) {
        // blah...
        return (EoTestResult SUCCESS, "")
    }
}

EoTestRunner: class {
    tests := ArrayList<EoTest> new()
    passed, failed, error: Int

    add: func (input, output: String) {
        eotest := EoTest new(input, output)
        tests add(eotest)
    }

    run: func {
        passed = failed = error = 0
        // set up EoInterpreter...
        for (t in tests) {
            t run()  // FIXME
        }
    }
}

