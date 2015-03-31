/* patch.ooc
   Miscellaneous monkey patching. :-)
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


