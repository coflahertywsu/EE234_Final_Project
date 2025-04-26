/*
 * pmod.S
 *
 *  Created on: Feb 16, 2025
 *      Author: Ron Shackelford
 */

@ Conditional Compilation Guard Code
@ Allows us to build/compile this file once
@ regardless of how many files we .include it in
.ifndef SRC_LINEFOLLOW_S_
.set SRC_LINEFOLLOW_S_, 1


.include "../src/PMODB.S"
.include "../src/RobotMotors.S"


.data
// compare        00000   00001      00010      00011    00100     00101    00110       00111     01000     01001     01010   01011     01100     01101     01110     01111     10000     10001     10010     10011      10100    10101     10110      10111      11000    11001     11010    11011    11100     11101     11110     11111
lineData: .word   STOP, SPINRIGHT, SPINRIGHT, SPINRIGHT, FORWARD, FORWARD, TURNRIGHT, TURNRIGHT, SPINLEFT, TURNLEFT, FORWARD, FORWARD, TURNLEFT, TURNLEFT, FORWARD, TURNRIGHT, SPINLEFT, FORWARD, TURNRIGHT, TURNRIGHT, FORWARD, FORWARD, TURNRIGHT, TURNRIGHT, SPINLEFT, TURNLEFT, FORWARD, FORWARD, TURNLEFT, TURNLEFT, TURNLEFT, FORWARD




.text

lineFollow:
    PUSH {lr}
    MOV r4, #0
    LDR r9, =#0b100000000000000000  @ used to set delay time of ~1.4 ms
    seekLine:
        CMP r4, #141
        BEQ endLineFollow
        BL readPMODB
        AND r0, r0, #0b11111
        CMP r0, #31
        BGT endLineFollow   @ this excludes anything larger than 31 (invalid input)
	    LDR r1, =lineData	@ load the address of the first case
	    LDR r1, [r1, r0, LSL #2]
	    BX r1

    endLineFollow:
        POP {lr}
        BX lr        


TURNLEFT:
    LDR r1, =MOTOR_0_BASEADDR
    MOV r2, #1
    BL change_motor_dir
    LDR r1, =MOTOR_1_BASEADDR
    MOV r2, #1
    BL change_motor_dir
    LDR r2, =#0xFFF
    LDR r1, =MOTOR_0_BASEADDR
    BL change_motor_speed
    LDR r2, =#0xDFFF
    LDR r1, =MOTOR_1_BASEADDR
    BL change_motor_speed
//    MOV r1, r9
//    BL delay
    B seekLine

TURNRIGHT:
    LDR r1, =MOTOR_0_BASEADDR
    MOV r2, #1
    BL change_motor_dir
    LDR r1, =MOTOR_1_BASEADDR
    MOV r2, #1
    BL change_motor_dir
    LDR r2, =#0xDFFF
    LDR r1, =MOTOR_0_BASEADDR
    BL change_motor_speed
    LDR r2, =#0xFFF
    LDR r1, =MOTOR_1_BASEADDR
    BL change_motor_speed
//    MOV r1, r9
//    BL delay   
    B seekLine

FORWARD:
    LDR r1, =MOTOR_0_BASEADDR
    MOV r2, #1
    BL change_motor_dir
    LDR r1, =MOTOR_1_BASEADDR
    MOV r2, #1
    BL change_motor_dir
    LDR r2, =#0xDFFF
    LDR r1, =MOTOR_0_BASEADDR
    BL change_motor_speed
    LDR r1, =MOTOR_1_BASEADDR
    BL change_motor_speed
//    MOV r1, r9
//    BL delay
    B seekLine

STOP:
    MOV r8, #100
    stopCheck:
        LDR r1, =MOTOR_0_BASEADDR
        MOV r2, #1
        BL change_motor_dir
        LDR r1, =MOTOR_1_BASEADDR
        MOV r2, #1
        BL change_motor_dir
        LDR r2, =#0xDFFF
        LDR r1, =MOTOR_0_BASEADDR
        BL change_motor_speed
        LDR r1, =MOTOR_1_BASEADDR
        BL change_motor_speed
//        MOV r1, r9
//        BL delay
        BL readPMODB
        AND r0, r0, #0b11111
        CMP r0, #0
        BNE seekLine
        SUB r8, r8, #1
        CMP r8, #0
        BNE stopCheck

    LDR r2, =#0x000
    LDR r1, =MOTOR_0_BASEADDR
    BL change_motor_speed
    LDR r1, =MOTOR_1_BASEADDR
    BL change_motor_speed
    MOV r4, #141
    B seekLine

SPINLEFT:
    LDR r1, =MOTOR_0_BASEADDR
    MOV r2, #0
    BL change_motor_dir
    LDR r1, =MOTOR_1_BASEADDR
    MOV r2, #1
    BL change_motor_dir
    LDR r2, =#0xDFFF
    LDR r1, =MOTOR_0_BASEADDR
    BL change_motor_speed
    LDR r1, =MOTOR_1_BASEADDR
    BL change_motor_speed
//    MOV r1, r9
//    BL delay
    B seekLine

SPINRIGHT:
    LDR r1, =MOTOR_0_BASEADDR
    MOV r2, #1
    BL change_motor_dir
    LDR r1, =MOTOR_1_BASEADDR
    MOV r2, #0
    BL change_motor_dir
    LDR r2, =#0xDFFF
    LDR r1, =MOTOR_0_BASEADDR
    BL change_motor_speed
    LDR r1, =MOTOR_1_BASEADDR
    BL change_motor_speed
//    MOV r1, r9
//    BL delay
    B seekLine



.endif /* SRC_LINEFOLLOW_S_ */