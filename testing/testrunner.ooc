/* testrunner.ooc */

import structs/ArrayList

TestError: class extends Exception {
    //message: String
    init: func (=message)
}

test: func (cond: Bool) {
    test(cond, "")
}
test: func ~withMessage (cond: Bool, message: String) {
    if (!cond) TestError new(message) throw()
}

Test: class {
    description: String
    testFunction: Func
    init: func (=description, =testFunction)
}

TestRunner: class {
    tests := ArrayList<Test> new()
    init: func

    addTest: func (description: String, testFunction: Func) {
        test := Test new(description, testFunction)
        tests add(test)
    }

    run: func {
        for (test in tests) {
            "Testing: %s... " printf(test description)
            try {
                test testFunction()
            } catch (e: TestError) {
                "FAILED" println()
                if (e message != "") e message println()
                continue
            } catch (e: Exception) {
                "ERROR" println()
                "(%s)" printfln(e message)
                continue
            }
            "OK" println()
        }
    }
}

