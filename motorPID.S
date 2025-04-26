/*
*   motorPID.S
*   created: 20 April, 2025
*   edited:  20 April, 2025
*       author: Ron Shackelford
*/
@ Conditional Compilation Guard Code
@ Allows us to build/compile this file once
@ regardless of how many files we .include it in
.ifndef MOTORPID_S_ 
.set MOTORPID_S_, 1

.include "../src/PMODB.S"
.include "../src/RobotMotors.S"


.set motor0_kp, 800     @ sets the motor0 proportional constant kp
.set motor0_ki, 90        @ sets the motor0 integral constant ki
.set motor0_kd, 70        @ sets the motor0 derivative constant kd

.set motor1_kp, 800     @ sets the motor1 proportional constant kp
.set motor1_ki, 90        @ sets the motor1 integral constant ki
.set motor1_kd, 70        @ sets the motor1 derivative constant kd

// addresses in which to store error data for summation
.global mot0_int0
.global mot0_int1
.global mot0_int2
.global mot0_int3
.global mot0_int4

.global mot1_int0
.global mot1_int1
.global mot1_int2
.global mot1_int3
.global mot1_int4

.data

// initializing summation data to zero
mot0_int0: .word 0
mot0_int1: .word 0
mot0_int2: .word 0
mot0_int3: .word 0
mot0_int4: .word 0

mot1_int0: .word 0
mot1_int1: .word 0
mot1_int2: .word 0
mot1_int3: .word 0
mot1_int4: .word 0

.text

# this updates the motor drive signal to the motors
update_motors:
    PUSH {lr}
    BL calculate_mot0_control
    LDR r1, =MOTOR_0_BASEADDR
    MOV r2, r0
    BL change_motor_speed

    BL calculate_mot1_control
    LDR r1, =MOTOR_1_BASEADDR
    MOV r2, r0
    BL change_motor_speed
    POP {lr}

# r0 is used to return motor0 control signal u(t)
calculate_mot0_control:
    PUSH {lr, r1-r3}
    BL get_mot0_error
    MOV r1, r0          @ error is now in r1
    BL mot0_eint    
    MOV r2, r0          @ integral error is now in r2
    BL mot0_dedt
    MOV r3, r0          @ derivative error is now in r3
    LDR r4, =motor0_kp
    LDR r5, =motor0_ki
    LDR r6, =motor0_kd
    MUL r1, r1, r4      @ this gives us the proportional part of u(t) in r1
    MUL r2, r2, r5      @ this gives us the integral part of u(t) in r2
    MUL r3, r3, r6      @ this gives us the derivative part of u(t) in r3
    ADD r0, r1, r2      
    ADD r0, r0, r3      @ this gives us u(t) in r0
    LDR r2, =#65535     @ this is the max motor control value
    MOV r3, #0          @ this is the min motor control value
    CMP r0, r2
    LDRGT r0, =#65535   @ if the control value is more than the max set it to the max
    CMP r0, r3
    LDRLT r0, =#0       @ if the control value is less than the min set it to the min
    POP {lr, r1-r3}
    BX lr


# r0 is used to return motor1 control signal u(t)
calculate_mot1_control:
    PUSH {lr, r1-r3}
    BL get_mot1_error
    MOV r1, r0          @ error is now in r1
    BL mot1_eint    
    MOV r2, r0          @ integral error is now in r2
    BL mot1_dedt
    MOV r3, r0          @derivative error is now in r3
    LDR r4, =motor1_kp
    LDR r5, =motor1_ki
    LDR r6, =motor1_kd
    MUL r1, r1, r4      @ this gives us the proportional part of u(t) in r1
    MUL r2, r2, r5      @ this gives us the integral part of u(t) in r2
    MUL r3, r3, r6      @ this gives us the derivative part of u(t) in r3
    ADD r0, r1, r2      
    ADD r0, r0, r3      @ this gives us u(t) in r0
    LDR r2, =#65535     @ this is the max motor control value
    MOV r3, #0          @ this is the min motor control value
    CMP r0, r2
    LDRGT r0, =#65535   @ if the control value is more than the max set it to the max
    CMP r0, r3
    LDRLT r0, =#0       @ if the control value is less than the min set it to the min
    POP {lr, r1-r3}
    BX lr


# r0 is used to return motor0 error
# r11 holds the motor0 rpm target
get_mot0_error:
    PUSH {lr}    
    LDR r1, =MOTOR_0_BASEADDR
    BL read_motor_rpm
    SUB r0, r11, r0      @ this calculates the motor0 error
    POP {lr}
    BX lr


# r0 is used to return motor1 error
# r12 holds the motor1 rpm target
get_mot1_error:
    PUSH {lr}    
    LDR r1, =MOTOR_1_BASEADDR
    BL read_motor_rpm
    SUB r0, r12, r0      @ this calculates the motor1 error
    POP {lr}
    BX lr


# r0 is used to return the integral error
# r1 is used to pass in the current error
mot0_eint:
    PUSH {lr, r2-r3}

    LDR r3, =mot0_int4  @ load r3 with address of 5th value
    LDR r2, =mot0_int3  @ load r2 with address of 4th value
    LDR r2, [r2]        @ load r2 with value of 4th value
    STR r2, [r3]        @ store 4th value at 5th values address
    MOV r0, r2          @ add 4th value to new running total
    LDR r3, =mot0_int3  
    LDR r2, =mot0_int2
    LDR r2, [r2]
    STR r2, [r3]
    ADD r0, r0, r2
    LDR r3, =mot0_int2
    LDR r2, =mot0_int1
    LDR r2, [r2]
    STR r2, [r3]
    ADD r0, r0, r2
    LDR r3, =mot0_int1
    LDR r2, =mot0_int0
    LDR r2, [r2]
    STR r2, [r3]
    ADD r0, r0, r2
    LDR r3, =mot0_int0
    STR r1, [r3]
    ADD r0, r0, r1      @ return new sum of last 5 error values

    POP {lr, r2-r3}
    BX lr

# r0 is used to return the integral error
# r1 is used to pass in the current error
mot1_eint:
    PUSH {lr, r2-r3}

    LDR r3, =mot1_int4  @ load r3 with address of 5th value
    LDR r2, =mot1_int3  @ load r2 with address of 4th value
    LDR r2, [r2]        @ load r2 with value of 4th value
    STR r2, [r3]        @ store 4th value at 5th values address
    MOV r0, r2          @ add 4th value to new running total
    LDR r3, =mot1_int3  
    LDR r2, =mot1_int2
    LDR r2, [r2]
    STR r2, [r3]
    ADD r0, r0, r2
    LDR r3, =mot1_int2
    LDR r2, =mot1_int1
    LDR r2, [r2]
    STR r2, [r3]
    ADD r0, r0, r2
    LDR r3, =mot1_int1
    LDR r2, =mot1_int0
    LDR r2, [r2]
    STR r2, [r3]
    ADD r0, r0, r2
    LDR r3, =mot1_int0
    STR r1, [r3]
    ADD r0, r0, r1      @ return new sum of last 5 error values

    POP {lr, r2-r3}
    BX lr


mot0_dedt:
    PUSH {lr, r2}

    LDR r2, =mot0_int1  @ this is the address where the previous error is stored
    LDR r2, [r2]        @ this loads the previous error
    SUB r0, r1, r2      @ this returns the difference of the current error and the previous error in r0

    POP {lr, r2}
    BX lr

mot1_dedt:
    PUSH {lr, r2}

    LDR r2, =mot1_int1  @ this is the address where the previous error is stored
    LDR r2, [r2]        @ this loads the previous error
    SUB r0, r1, r2      @ this returns the difference of the current error and the previous error in r0
    
    POP {lr, r2}
    BX lr


.endif /* MOTORPID_S_ */
