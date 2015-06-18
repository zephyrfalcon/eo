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

/* empty function to be used as a placeholder */
dummy: func {
    "Not implemented yet" println()
}

sign: func (x: Int) -> Int {
    if (x < 0) return -1
    if (x > 0) return 1
    return 0
}

assertInstance: func (x: EoType, c: Class) {
    if (!x instanceOf?(c))
        raise("Expected type: %s, got %s instead" format(c name, x class name))
}

/* Better (?) sorting algorithm for ArrayList.
   ooc uses bubble sort by default! >.<
   Adapted from: http://www.pp4s.co.uk/main/tu-ss-sort-quick.html
*/

qsort: func (list: ArrayList<EoType>, cmp: Func (EoType, EoType) -> Int,
             Left, Right: Int) {
    ptrLeft := Left
    ptrRight := Right
    pivotIndex := (Left + Right) / 2
    pivot := list[pivotIndex]  // hmm
    while (true) {
        while (ptrLeft < Right && cmp(list[ptrLeft], pivot) == -1)
            ptrLeft += 1
        while (ptrRight > Left && cmp(list[ptrRight], pivot) == 1)
            ptrRight -= 1
        if (ptrLeft <= ptrRight) {
            if (ptrLeft < ptrRight) {
                temp := list[ptrLeft]
                list[ptrLeft] = list[ptrRight]
                list[ptrRight] = temp
            }
            ptrLeft += 1
            ptrRight -= 1
        }
        if (ptrLeft > ptrRight) break
    }
    if (ptrRight > Left) qsort(list, cmp, Left, ptrRight)
    if (ptrLeft < Right) qsort(list, cmp, ptrLeft, Right)
}

qsort: func ~short (list: ArrayList<EoType>, cmp: Func (EoType, EoType) -> Int) {
    if (list size < 2) return
    qsort(list, cmp, 0, list size - 1)
}


