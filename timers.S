/*
*   timers.S
*   created: March 17th, 2025
*   edited:  March 21st, 2025
*       author: Ron Shackelford
*/
@ Conditional Compilation Guard Code
@ Allows us to build/compile this file once
@ regardless of how many files we .include it in
.ifndef SRC_timers_S_ 
.set SRC_timers_S_, 1

.set GTC_BASEADDR, 0xF8F00200

.data


.text

configure_GTC:
    LDR r0, =GTC_BASEADDR

    # set the comparator value to make a one second timer interrupt
    # time interval / T_GTC =  comparator value + 1
    # 0.0004s / (1/1.302083) = comparator + 1 = 52; comparator = 51
    LDR r1, =#51
    MOV r10, r1
    STR r1, [r0, #0x10]
    STR r1, [r0, #0x18]
    MOV r1, #0
    STR r1, [r0, #0x14] @ upper 32-bits of the comparator value

    # set the global timer control register
    # auto-increment on 
    # enable interrupts
    # enable comparator
    # disable timer
    # we can choose the GTC's frequency by taking f_CPU3X2X / (prescaler + 1)
    # the f_CPU3X2X = f_CPU/2, f_CPU = 666.6666 MHz, f_CPU3X2X = 333.3333 MHz
    # choosing a prescaler value of 255; f_GTC = 333.3333 MHz / (255 + 1) = 1.302083 MHz
    LDR r1, =#0xFF0E
    STR r1, [r0, #0x08]


    MOV pc, lr



.endif /* SRC_timers_S_ */
