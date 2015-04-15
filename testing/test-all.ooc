
import structs/ArrayList
import testing/testrunner
import source/eo

tr := TestRunner new()

extend ArrayList<String> {
    /* comparing with '==' fails, so I have to define me own... */
    equals: func (other: ArrayList<String>) -> Bool {
        //"%d, %d" printfln(this size, other size)
        if (this size != other size) return false
        if (this size > 0) {
            for (i in 0..this size) {
                //"%d: %s" printfln(i, this get(i) as String, other get(i) as String)
                if (this get(i) as String != other get(i) as String) return false
            }
        }
        return true
    }
}

/* TODO: patch ArrayList<EoType> */

tr addTest("test ArrayList<String> equals", func {
    a := ["a", "b", "c"] as ArrayList<String>
    test(a equals(a))
    //println(a equals(a) ? "yea" : "nay")
})

tr addTest("test eo.tokenize", func {
    test(tokenize("") equals([] as ArrayList<String>), "FAIL!")
    test(tokenize("1 a") equals(["1", "a"] as ArrayList<String>))
})

tr addTest("check that 1+1 equals 2", func {
    test(1==2)
})

tr addTest("messy test", func {
    q := ArrayList<String> new()
    q first() println()
    test(2==3)
})

tr run()



