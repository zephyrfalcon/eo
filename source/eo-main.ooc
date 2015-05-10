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
    runTests := (args size > 1 && args[1] == "--test")
    executablePath := whereAmI(args[0])
    // later: have proper command line handling :-/
    //"Executable is in: %s" printfln(executablePath)

    repl := EoREPL new(executablePath)
    if (runTests) {
        testPath := File join(executablePath, "source", "tests")
        "Tests are in: %s" printfln(testPath)
        "Running tests..." println()
        runEoTests(testPath)
    }
    else
        repl run()
}

