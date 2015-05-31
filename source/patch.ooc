/* patch.ooc
   Miscellaneous monkey patching. :-)
*/

/* TODO:
   - ArrayList needs better sorting algorithm >=(
*/

import text/Regexp
import structs/ArrayList

extend Regexp {
    split: func (s: String) -> ArrayList<String> {
        results := ArrayList<String> new()
        while (true) {
            matchobj := this matches(s)
            if (matchobj == null) break

            token := matchobj group(0)
            cutoff := matchobj groupStart(0) + matchobj groupLength(0)
            results add(token)

            s = s substring(cutoff)
        }
        return results
    }
}

/* ooc does not seem to have a way to tell if a string is "greater" or
 * "smaller" than another (like C's strcmp() or Python's cmp()), so I'm adding
 * a version here.
 */

extend String {
    cmp: func (other: String) -> Int {
        for (i in 0..size) {
            if (i >= other size) return 1  /* this is longer than other */
            if (this[i] < other[i]) return -1
            if (this[i] > other[i]) return 1
        }
        if (other size > this size) return -1
        return 0
    }
}

/* add different functions (non-methods) of cmp here: */
cmp: func ~withStrings (s1, s2: String) -> Int { s1 cmp(s2) }
cmp: func ~withInts (s1, s2: Int) -> Int { s1 - s2 }

/* we can define operators here as well, although it's not strictly necessary.
 * String > String etc did work, but I think it compares pointers rather than
 * content. */
operator > (left, right: String) -> Bool { left cmp(right) > 0 }

