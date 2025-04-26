/*
*   rcMode.S
*   created: March 17th, 2025
*   edited:  March 21st, 2025
*       author: Ron Shackelford
*/
@ Conditional Compilation Guard Code
@ Allows us to build/compile this file once
@ regardless of how many files we .include it in
.ifndef SRC_RCMODE_S_ 
.set SRC_RCMODE_S_, 1

.data
rc_mode_string: .asciz "this is rc mode\n"
line_follower_string: .asciz "You have entered Line Following!\r\n"


.text

rc_mode:
    PUSH {lr, r1}
    LDR r1, =rc_mode_string
    BL uart1_write

    rc_loop:
        BL uart0_read_structured
        LDRB r0, [r0]
        CMP r0, #0xF3
        BNE rc_loop


    POP {lr, r1}
    BX lr


line_follower_mode:
    PUSH {lr, r1}
    LDR r1, =line_follower_string
    BL uart1_write

    lf_loop:
        BL uart0_read_structured  @ this will break out based on the halt button being pressed
        LDRB r0, [r0]  @
        CMP r0, #0xF3  @
        BNE lf_loop

    POP {lr, r1}
    BX lr


.endif /* SRC_RCMODE_S_ */
