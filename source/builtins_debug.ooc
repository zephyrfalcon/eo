/* builtins_debug.ooc 
   Debugging words */

import eo, eotypes, namespace

_perc_show_call_stack: func (interp: EoInterpreter, ns: Namespace) {
    /* %show-call-stack ( <bool> -- )
       Show the contents of the call stack at every execution step. */
    onoff := interp stack popCheck(EoBool) as EoBool
    interp debugSettings showCallStack = onoff value
}

_perc_count_cycles: func (interp: EoInterpreter, ns: Namespace) {
    /* %count-cycles ( <bool> -- )
       Turn on cycle counting. */
    onoff := interp stack popCheck(EoBool) as EoBool
    interp debugSettings countCycles = onoff value
}

_perc_show_tokens: func (interp: EoInterpreter, ns: Namespace) {
    /* %show-tokens ( bool -- )
       Show tokens after tokenizing a string. */
    onoff := interp stack popCheck(EoBool) as EoBool
    interp debugSettings showTokens = onoff value
}


