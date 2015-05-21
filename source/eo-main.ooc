/* eo-main.ooc */

/* `eo-main` is supposed to be run interactively, and does so by default,
    but you can run `eo-main --test` to run the test suite. */

import eo
import structs/ArrayList
import testing
import io/File

whereAmI: func (executableName: String) -> String {
    f := File new(executableName) getAbsoluteFile()
    return f parentName()
}

main: func (args: ArrayList<String>) {
    runTests := false
    allowStderr := false

    if (args size > 1)
        for (arg in args slice(1..-1)) {
            match (arg) {
                case "--test" => runTests = true
                case "--allow-stderr" => allowStderr = true
                case => "Unknown option: %s" printfln(arg)
            }
        }

    executablePath := whereAmI(args[0])

    repl := EoREPL new(executablePath)
    if (allowStderr)
        stderr = repl interpreter _oldStderr
    if (runTests) {
        testPath := File join(executablePath, "source", "tests")
        "Tests are in: %s" printfln(testPath)
        "Running tests..." println()
        runEoTests(testPath)
    }
    else
        repl run()
}

