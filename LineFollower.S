/*
 * LineFollower.S
 *
 *  Created on: 19 April, 2025
 *      Author: Ron Shackelford
 */

@ Conditional Compilation Guard Code
@ Allows us to build/compile this file once
@ regardless of how many files we .include it in
.ifndef SRC_LINEFOLLOWER_S_
.set SRC_LINEFOLLOWER_S_, 1

.include "../src/interrupt.S"
.include "../src/timers.S"
.include "../src/PMODB.S"
.include "../src/RobotMotors.S"

.set leds, 0x41210000

.set LF_kp, 5      @ sets the line follow proportional constant kp
.set LF_ki, 0      @ sets the line follow integral constant ki
.set LF_kd, 100    @ sets the line follow derivative constant kd

.global LF_err_int0
.global LF_err_int1
.global LF_err_int2
.global LF_err_int3
.global LF_err_int4


.data
line_follower_string: .asciz "Follow the yellow brick road...or maybe just this black line.\r\n"


LF_err_int0: .word 0
LF_err_int1: .word 0
LF_err_int2: .word 0
LF_err_int3: .word 0
LF_err_int4: .word 0

@ turnData: .word STOP, RIGHT, RIGHT, RIGHT, FORWARD, FORWARD, RIGHT, RIGHT, LEFT, LEFT, FORWARD, FORWARD, LEFT, LEFT, FORWARD, RIGHT, LEFT, FORWARD, RIGHT, RIGHT, FORWARD, FORWARD, RIGHT, RIGHT, LEFT, LEFT, FORWARD, FORWARD, LEFT, LEFT, LEFT, LEFT


.text

line_follower_mode:
    PUSH {lr, r0-r12}
    @ LDR r1, =line_follower_string            ############ Change ##############
    @ BL uart1_write

    // set the direction to forward
    LDR r1, =MOTOR_0_BASEADDR
    MOV r2, #1
    BL change_motor_dir
    LDR r1, =MOTOR_1_BASEADDR
    MOV r2, #1
    BL change_motor_dir

    // clear the line follower registers
    MOV r4, #0
    MOV r5, #0
    MOV r6, #0
    MOV r7, #0
    MOV r8, #0
    MOV r9, #0
    MOV r10, #0
    MOV r11, #0
    MOV r12, #0

    // set the target rpm
    MOV r10, #180
    MOV r11, r10
    MOV r12, r10

    // turn on the GTC
    LDR r0, =GTC_BASEADDR
    LDR r1, =#0xFF0F
    STR r1, [r0, #0x08]

// Main loop while seeking the line    
    seekLine:
        @ BL uart0_read_structured  @ this will break out based on the halt button being pressed      ################## Change ################
        @ LDRB r0, [r0]  @
        @ CMP r0, #0xF3  @
        @ BEQ end_line_follower_mode
        BL update_motor_targets

        @ LDR r1, =#140000
        @ BL delay

        B seekLine

    
    end_line_follower_mode:
    // set the motor speed to 0
        MOV r11, #0
        MOV r12, #0
    // set a delay to allow the motorPID to stop the motors
        LDR r1, =#46500000
        BL delay

    // turn off the GTC which
        LDR r0, =GTC_BASEADDR
        LDR r1, =#0xFF0E
        STR r1, [r0, #0x08]

        POP {lr, r0-r12}
        BX lr       


// Updates the target rpm values for motor0 and motor1
update_motor_targets:
    PUSH {lr, r0-r3}
    BL get_LF_error

    CMP r3, #0b11111111
    BEQ fullStop

    BL LF_err_eint
    BL LF_dedt
    LDR r7, =LF_kp
    LDR r8, =LF_ki
    LDR r9, =LF_kd
    MUL r7, r4, r7      @ this gives us the proportional part of u(t) in r7
    MUL r8, r5, r8      @ this gives us the integral part of u(t) in r8
    MUL r9, r6, r9      @ this gives us the derivative part of u(t) in r9
    ADD r0, r7, r8
    ADD r0, r0, r9      @ this gives us u(t) in r0

    SUB r4, r10, r0    @ this is the new motor0 value
    ADD r5, r10, r0    @ this is the new motor1 value

    MOV r1, #420     @ this is the max motor control value
    MOV r2, #0      @ this is the min motor control value
    CMP r4, r1
    LDRGT r4, =#420   @ if the control value is more than the max set it to the max
    CMP r4, r2
    LDRLT r4, =#0       @ if the control value is less than the min set it to the min
    CMP r5, r1
    LDRGT r5, =#420   @ if the control value is more than the max set it to the max
    CMP r5, r2
    LDRLT r5, =#0       @ if the control value is less than the min set it to the min

    MOV r11, r4     @ This sets motor0 rpm !!!!!!!!!!!!!!!
    MOV r12, r5     @ This sets motor1 rpm !!!!!!!!!!!!!!!


    POP {lr, r0-r3}
    BX lr

    fullStop:
        POP {lr, r0-r3}
        B end_line_follower_mode


# r4 is used to return the error
get_LF_error:
    PUSH {lr, r0, r1}    
    # setup PMODB as an output
    MOV r1, #1
    BL setupPMODB
    # write all ones to PMODB
    MOV r1, #0b11111111
    BL writePMODB
    # delay to allow the capacitors time to charge
    MOV r1, #935
    BL delay
    # setup PMODB as in input
    MOV r1, #0
    BL setupPMODB
    # timing delay to allow time for the reflected light to reach the sensor
    LDR r1, =#80000
    BL delay
    # read the data from PMODB
    BL readPMODB

    LDR r1, =leds
    STR r0, [r1]

    CMP r0, #0b00000000
    MOVEQ r4, #0
    CMP r0, #0b10000000
    MOVEQ r4, #4
    CMP r0, #0b11000000
    MOVEQ r4, #3
    CMP r0, #0b11100000
    MOVEQ r4, #3    
    CMP r0, #0b01100000
    MOVEQ r4, #2
    CMP r0, #0b01110000
    MOVEQ r4, #2
    CMP r0, #0b00110000
    MOVEQ r4, #1
    CMP r0, #0b00111000
    MOVEQ r4, #1    
    CMP r0, #0b00011000
    MOVEQ r4, #0
    CMP r0, #0b00011100
    MOVEQ r4, #-1    
    CMP r0, #0b00001100
    MOVEQ r4, #-1
    CMP r0, #0b00001110
    MOVEQ r4, #-2    
    CMP r0, #0b00000110
    MOVEQ r4, #-2
    CMP r0, #0b00000111
    MOVEQ r4, #-3    
    CMP r0, #0b00000011
    MOVEQ r4, #-3
    CMP r0, #0b00000001
    MOVEQ r4, #-4
    MOV r3, r0

    POP {lr, r0, r1}
    BX lr



# r5 is used to return the integral error
# r4 is used to pass in the current error
LF_err_eint:
    PUSH {lr, r2-r3}

    LDR r3, =LF_err_int4  @ load r3 with address of 5th value
    LDR r2, =LF_err_int3  @ load r2 with address of 4th value
    LDR r2, [r2]        @ load r2 with value of 4th value
    STR r2, [r3]        @ store 4th value at 5th values address
    MOV r5, r2          @ add 4th value to new running total
    LDR r3, =LF_err_int3  
    LDR r2, =LF_err_int2
    LDR r2, [r2]
    STR r2, [r3]
    ADD r5, r5, r2
    LDR r3, =LF_err_int2
    LDR r2, =LF_err_int1
    LDR r2, [r2]
    STR r2, [r3]
    ADD r5, r5, r2
    LDR r3, =LF_err_int1
    LDR r2, =LF_err_int0
    LDR r2, [r2]
    STR r2, [r3]
    ADD r5, r5, r2
    LDR r3, =LF_err_int0
    STR r4, [r3]
    ADD r5, r5, r4      @ return new sum of last 5 error values

    POP {lr, r2-r3}
    BX lr

# r6 is used to return the error difference
LF_dedt:
    PUSH {lr, r2}

    LDR r2, =LF_err_int1  @ this is the address where the previous error is stored
    LDR r2, [r2]        @ this loads the previous error
    SUB r6, r4, r2      @ this returns the difference of the current error and the previous error in r6

    POP {lr, r2}
    BX lr





.endif /* SRC_LINEFOLLOWER_S_ */