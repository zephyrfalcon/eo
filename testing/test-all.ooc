
import structs/ArrayList
import testrunner

tr := TestRunner new()

tr addTest("check that 1 equals 1", func {
        test(1==1)
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



