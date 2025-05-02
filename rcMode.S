/*
*   rcMode.S
*   created: 17 March, 2025
*   edited:  1 May, 2025
*       author: Ron Shackelford
*/
@ Conditional Compilation Guard Code
@ Allows us to build/compile this file once
@ regardless of how many files we .include it in
.ifndef SRC_RCMODE_S_ 
.set SRC_RCMODE_S_, 1

.data
rc_mode_string: .asciz "This is RC mode.\n"

.text

rc_mode:
    PUSH {lr, r1-r12}
    LDR r1, =rc_mode_string
    BL uart1_write
    
    // clear the registers that will hold program data
    MOV r9, #0      @ x data
    MOV r10, #0     @ y data
    MOV r11, #0     @ Mot0 target rpm
    MOV r12, #0     @ Mot1 target rpm

    // turn on the motors by turning on the GTC
    LDR r0, =GTC_BASEADDR
    LDR r1, =#0xFF0F
    STR r1, [r0, #0x08]

    joystick_read_loop:

        BL uart0_read_structured	@ read data from controller
        LDRB r1, [r0]
        CMP r1, #0xF3
        BEQ end_rc_mode     		@ if it was the halt button go back to main

        CMP r1, #0xF6
        BNE joystick_read_loop		@ if identifier is not from joystick go to top of loop
                                    @ it has to be done this way b/c LDRBEQ is not valid

        LDRB r1, [r0, #1]			@ loading second byte from uart0 buffer containing data

        // joystick data comes in as the second byte from the uart0 buffer
        // it is formatted as 0b1YYY1XXX thus we must extract the three Y bits and three X bits
        AND r10, r1, #0x7           @ y data is stored in r10
        LSR r1, r1, #4
        AND r9, r1, #0x7            @ x data is stored in r9

        CMP r10, #4         @ if y data is above 4 robot moving forward
        BGT rc_forward
        CMP r10, #3         @ if y data is below 3 robot is moving backward
        BLT rc_reverse
        MOV r11, #0         @ if y data is 3 or 4 the robot is not moving set motors (r11 & r12) to 0
        MOV r12, #0
        B joystick_read_loop

        rc_forward:
            LDR r1, =MOTOR_0_BASEADDR
            MOV r2, #1
            BL change_motor_dir
            LDR r1, =MOTOR_1_BASEADDR
            MOV r2, #1
            BL change_motor_dir

            SUB r1, r10, #4     @ subtract 4 from y data and multiply by 150 to get motor speed
            MOV r2, #150
            MUL r11, r1, r2
            MOV r12, r11            
            BL rc_turn
            B joystick_read_loop
        
        rc_reverse:
            LDR r1, =MOTOR_0_BASEADDR   @ Going backward...need to change direction of the motor
            MOV r2, #0
            BL change_motor_dir
            LDR r1, =MOTOR_1_BASEADDR
            MOV r2, #0
            BL change_motor_dir  

            MVN r1, r10         @ since data is lower than 3, in order to get the motor speed we must
            ADD r1, r1, #3      @ change the sign of the data, add 3, and multiply by 150 to get motor speed
            MOV r2, #150
            MUL r11, r1, r2
            MOV r12, r11
            BL rc_turn
            B joystick_read_loop          
 
    end_rc_mode:
        // set the motors to 0 rpm
        MOV r11, #0
        MOV r12, #0

        // set a delay to allow the motors time to stop
        LDR r1, =#46500000
        BL delay

        // turn off the GTC
        LDR r0, =GTC_BASEADDR
        LDR r1, =#0xFF0E
        STR r1, [r0, #0x08]
        
        POP {lr, r1-r12}
        BX lr


rc_turn:
    PUSH {lr, r1, r2}
    CMP r9, #4
    BGT rc_turn_right
    CMP r9, #3
    BLT rc_turn_left
    B end_rc_turn

    rc_turn_right:
        SUB r1, r9, #4      @ same as above on the algorithm but multiplying by 40 and adding
        MOV r2, #40         @ to the outside wheel to get the robot to turn.
        MUL r1, r1, r2     
        ADD r12, r12, r1
        B end_rc_turn
    
    rc_turn_left:
        MVN r1, r9
        ADD r1, r1, #3
        MOV r2, #40
        MUL r1, r1, r2
        ADD r11, r11, r1
        B end_rc_turn

    end_rc_turn:
        POP {lr, r1, r2}
        BX lr

.endif /* SRC_RCMODE_S_ */