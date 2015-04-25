/* eo-main.ooc */

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
    //"Executable is in: %s" printfln(executablePath)

    repl := EoREPL new()
    if (runTests) {
        testPath := File join(executablePath, "source", "tests")
        "Tests are in: %s" printfln(testPath)
        "Running tests..." println()
        runEoTests(testPath)
    }
    else
        repl run()
}

