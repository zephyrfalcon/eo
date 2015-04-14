
import structs/ArrayList
import testing/testrunner
import source/eo

tr := TestRunner new()


tr addTest("test eo.tokenize", func {
        test(tokenize("1 a") == (["1", "a"] as ArrayList<String>))
        /* is in need of a testEquals or something, but that is not always
         * easy in ooc... :-/ */
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



