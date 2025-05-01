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
.set TTC0_BASEADDR, 0xF8001000

.data


.text

configure_GTC:
    LDR r0, =GTC_BASEADDR

    # set the comparator value
    # time interval / T_GTC =  comparator value + 1
    # 0.001s / (1/1.302083) = comparator + 1 = 1302; comparator = 1301
    LDR r1, =#1301
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

@ configure_TTC0:
@     LDR r0, =TTC0_BASEADDR

@     # set the TTC0 input clock
@     # we can choose the TTC's frequency by taking 111.1111 MHz / (prescaler + 1)
@     # choosing a prescaler value of 255; f_TTC = 111.1111 MHz / (255 + 1) = 434.028 kHz
@     LDR r1, =#0xF
@     STR r1, [r0]
    
@     # set the mode Configuration
@     # PL=0, OW=0, CR=1, ME=0, DC=0, IM=1, OD=1
@     LDR r1, =#0x13
@     STR r1, [r0, #0x0C]

@     # set the interval value
@     # time interval / T_GTC =  comparator value + 1
@     # 0.005s / (1/434028) = comparator + 1 = 2170; comparator = 2169
@     LDR r1, =#2169
@     STR r1, [r0, #0x24]
    
@     # set the interval interrupt enable to 1
@     MOV r1, #0x1
@     STR r1, [r0, #0x60]

 



    MOV pc, lr

.endif /* SRC_timers_S_ */
