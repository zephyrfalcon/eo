/* tools.ooc
   Miscellaneous tools. */

import eo, eotypes
import structs/ArrayList
import io/File

makeWordThatReturns: func (interp: EoInterpreter, result: EoType) -> EoUserDefWord {
    words := ArrayList<EoType> new()
    words add(result)
    blk := EoCodeBlock new(words, interp userNamespace)
    w := EoUserDefWord new(blk)
    return w
}

/* Get the "shortname" of a filename. This is the last element of a path
   minus the extension.
   If filename is not fully qualified, turn it into an absolute filename first.
*/
getShortName: func (filename: String) -> String {
    filename = File new(filename) getAbsolutePath()
    last := File new(filename) getName()
    // extension needs stripped; for now, let's assume it's ".eo" and remove
    // that. FIXME later.
    if (last endsWith?(".eo"))
        last = last substring(0, -4)
    return last
}

