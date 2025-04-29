/*
 * robomal.S
 *
 *  Created on: Feb 15, 2025
 *      Author: Ron Shackelford
 */

.ifndef ROBOMAL_S
.set ROBOMAL_S, 1

// .include "../src/RobotMotors.S"
.include "../src/motorPID.S"

.data

debug_statement1: .asciz "Copy Instructions occurred"

.set HALF_WORD_MASK, 0xFFFF
.set QUARTER_SEC, 25000000
.set ONE_SEC, 100000000
.set TWO_SEC, 200000000

# ROBOMAL Architecture: 16-bit VonNeumann RISC
// ROBO_Instructions: .hword 0x13CF, 0x405F, 0x415F, 0x425F, 0x442F, 0x453F, 0x442F, 0x432F, 0x442F, 0x463F, 0x44FF, 0x3300

robomal_instruction_set: .space 0xFF	@ you should have something like this, buffer size = 256 bytes  

# ROBOMAL Register File
# r6 = Program counter
# r7 = Instruction register
# r8 = Operation code register
# r9 = Operand register
# r10 = speed register
# r11 = mot0 rpm reg
# r12 = mot1 rpm reg

# jump table for opcode families
opcodeFamily: .word dataTransfer, arithmetic, branchInstruction, robotControl

# jump tables for instructions
dataTransferInstructions: .word readData, writeData, loadSpeed, storeSpeed
arithmeticInstructions: .word addData, subtractData, multiplyData
branchInstructions: .word branch, brancheq, branchne, halt 
robotControlInstructions: .word left, right, forward, backward, brake, spinLeft, spinRight

program_string: .asciz "This is Program Mode brought to you by robomal!\n"

.text

program_mode:
    PUSH {lr, r1}
    LDR r1, =program_string
    BL uart1_write

    wait_for_initiation_loop:
        BL uart0_read_structured	@ read uart0
        LDRB r1, [r0]
        CMP r1, #0xF5
        BNE wait_for_initiation_loop	@ keep reading until the initiation packet is received    

        LDRB r1, [r0, #1]			@ load number of instructions to be delivered
        SUB r1, r1, #1
        MOV r2, #1			@ instructions read counter
        LDR r3, =robomal_instruction_set
        BL uart1_write_hex_chars

    copy_instructions_loop:
        BL uart0_read_structured	@ read uart0
        LDRH r0, [r0]			@ load halfword from buffer
        CMP r0, #0			@ if nothing was read don’t count it and goto top of loop
        BEQ copy_instructions_loop 	@ needed to account for send/receive rate mismatch 

        STRH r0, [r3], #2			@ store hword in robomal array, increment r3 addr by 2
        ADD r2, r2, #1
        CMP r2, r1			@ compare instructions read w/ instruction to be delivered			BNE copy_instructions_loop
		BNE copy_instructions_loop

     LDR r1, =debug_statement1
     BL uart1_write   


# tell the robot to run a program
runROBO_Program:
    # initialie the PC to the start of the program
    # PC will be the offset from the beginning of instruction memory
    MOV r6, #0
    MOV r7, #0
    MOV r8, #0
    MOV r9, #0
    MOV r10, #0
    MOV r11, #0
    MOV r12, #0

    // turn on the motors by turning on the GTC
    LDR r0, =GTC_BASEADDR
    LDR r1, =#0xFF0F
    STR r1, [r0, #0x08]

    ROBO_loop:
        BL simulateClockCycle
        // this will break out based on the halt button being pressed
        BL uart0_read_structured  
        LDRB r0, [r0]
        CMP r0, #0xF3
        BEQ end_ROBO_loop

        CMP r8, #0x33
        BNE ROBO_loop

        end_ROBO_loop:
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

            POP {lr}
            BX lr

# Simulate one fetch, decode, execute instruction cycle
simulateClockCycle:
    PUSH {lr}

    BL fetch
    BL decode
    BL execute

    POP {lr}
    BX lr

# Grab an instruction from instruction memory located at the PC
# PC = r6
# Instruction register = r7
fetch:
    # get a pointer to the base address of the instruction memory
    LDR r0, =robomal_instruction_set

    # fetching the halfword (LDRH) instruction located at ROBO_Instructions with an offset of the program counter (r6)
    LDRH r7, [r0, r6]

    # increment the pc to point to the next instruction
    # need to increment by 2 because these are halfwords
    ADD r6, r6, #2

    BX lr

# break the instruction into its parts
# instruction register = r7
# opcode = r8
# operand = r9
decode:
    # 0xYYZZ, where YY is the opcode and ZZ is the operand
    # get opcode from instruction reg; r8 = 0xYY
    LSR r9, r7, #8

    # get the operand from instruction reg; r9 = 0xZZ
    AND r8, r7, #0xFF

    BX lr

# perform our operation
# accumulator reg = r5 (if arithmetic)
# program counter reg = r6 (if branch)
# opcode reg = r8
# operand reg = r9

execute:
    PUSH {lr}
    # take the opcode and perform the correct operation
    LSR r3, r8, #4  @ look only at the msb nibble of r8 for the opcode family
    CMP r3, #5
    SUB r3, r3, #1 
    BGE endExecute
    LDR r1, =opcodeFamily
    LDR r1, [r1, r3, LSL #2]
    BX r1

    dataTransfer:
        AND r3, r8, #0xF @ look at lsb nibble of r8 for the opcode instruction
        CMP r3, #4
        BGE endExecute
        LDR r1, =dataTransferInstructions
        LDR r1, [r1, r3, LSL #2]
        BX r1        
        readData:
            B endExecute
        writeData:

            B endExecute
        loadSpeed:

            B endExecute
        storeSpeed:
        // add code to make sure final value is not less than zero
            MOV r10, r9
            LSL r10, #1
            SUB r10, r10, #90
            B endExecute

    arithmetic:
        AND r3, r8, #0xF
        CMP r3, #3
        BGE endExecute
        LDR r1, =arithmeticInstructions
        LDR r1, [r1, r3, LSL #2]
        BX r1
        addData:
            B endExecute
        subtractData:
            B endExecute
        multiplyData:
            B endExecute

    branchInstruction:
        AND r3, r8, #0xF
        CMP r3, #4
        BGE endExecute
        LDR r1, =branchInstructions
        LDR r1, [r1, r3, LSL #2]
        BX r1
        branch:                  
            B endExecute
        brancheq:
            B endExecute
        branchne:
            B endExecute
        halt:
            B endExecute

    robotControl:
        AND r3, r8, #0xF
        CMP r3, #7
        BGE endExecute
        LDR r1, =robotControlInstructions
        LDR r1, [r1, r3, LSL #2]
        BX r1
        left:
            LDR r1, =MOTOR_0_BASEADDR
	        MOV r2, #1
            BL change_motor_dir
            LDR r1, =MOTOR_1_BASEADDR
            MOV r2, #1
            BL change_motor_dir
            // adjust the motor speed to turn left
            MOV r5, #50
            ADD r11, r10, r5
            SUB r12, r10, r5
            // delay for prescribed amount of time
            MOV r1, r9
            LSL r1, #16
            BL delay
            MOV r11, #0
            MOV r12, #0
            B endExecute

        right:
            LDR r1, =MOTOR_0_BASEADDR
	        MOV r2, #1
            BL change_motor_dir
            LDR r1, =MOTOR_1_BASEADDR
            MOV r2, #1
            BL change_motor_dir
            // adjust the motor speed to turn right
            MOV r5, #50
            SUB r11, r10, r5
            ADD r12, r10, r5         
            // delay for prescribed amount of time
            MOV r1, r9
            LSL r1, #16
            BL delay
            MOV r11, #0
            MOV r12, #0
            B endExecute

        forward:
            LDR r1, =MOTOR_0_BASEADDR
	        MOV r2, #1
            BL change_motor_dir
            LDR r1, =MOTOR_1_BASEADDR
            MOV r2, #1
            BL change_motor_dir
            // adjust the motor speed
            MOV r11, r10
            MOV r12, r10
            // delay for prescribed amount of time
            MOV r1, r9
            LSL r1, #16
            BL delay
            MOV r11, #0
            MOV r12, #0
            B endExecute

        backward:
            LDR r1, =MOTOR_0_BASEADDR
            MOV r2, #0
            BL change_motor_dir
            LDR r1, =MOTOR_1_BASEADDR
            MOV r2, #0
            BL change_motor_dir
            // adjust the motor speed
            MOV r11, r10
            MOV r12, r10
            // delay for prescribed amount of time
            MOV r1, r9
            LSL r1, #16
            BL delay
            MOV r11, #0
            MOV r12, #0
            B endExecute

        brake:
            MOV r11, #0
            MOV r12, #0       
            // delay for prescribed amount of time
            MOV r1, r9
            LSL r1, #16
            BL delay
            B endExecute

        spinLeft:
            LDR r1, =MOTOR_0_BASEADDR
	        MOV r2, #0
            BL change_motor_dir
            LDR r1, =MOTOR_1_BASEADDR
            MOV r2, #1
            BL change_motor_dir
            // adjust the motor speed
            MOV r11, r10
            MOV r12, r10
            // delay for prescribed amount of time
            MOV r1, r9
            LSL r1, #16
            BL delay
            MOV r11, #0
            MOV r12, #0
            B endExecute

        spinRight:
            LDR r1, =MOTOR_0_BASEADDR
	        MOV r2, #1
            BL change_motor_dir
            LDR r1, =MOTOR_1_BASEADDR
            MOV r2, #0
            BL change_motor_dir
            // adjust the motor speed
            MOV r11, r10
            MOV r12, r10        
            // delay for prescribed amount of time
            MOV r1, r9
            LSL r1, #16
            BL delay
            MOV r11, #0
            MOV r12, #0
            B endExecute

    endExecute:
    POP {lr}
    BX lr

transmit_delay:
    PUSH {lr, r1}
    LDR r1, =#9345794 
    BL delay
    POP {lr, r1}
    BX lr

.endif