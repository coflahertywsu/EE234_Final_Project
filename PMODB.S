/*
 * pmod.S
 *
 *  Created on: Feb 16, 2025
 *      Author: Ron Shackelford
 */

@ Conditional Compilation Guard Code
@ Allows us to build/compile this file once
@ regardless of how many files we .include it in
.ifndef SRC_PMOD_S_
.set SRC_PMOD_S_, 1

.data

@ Base address for our MIO address space
@ We care about DATA_2, DATA_2_RO, DIR_2, and OE_2
@ Which have offsets #0x48, #0x68, #0x284, #0x288 from the base address respectively
.set MIO_BASE_ADDR, 0xE000A000

@ Our bitmasks for the top and bottom pins of PMODB
.set PMODB_MASK, 0x7F80 	@ IR LED pin information is in bits 7,8,9,10,11,12,13,14 of the above registers

.text

@ unsigned int r1 = 0 sets the port as an input, r1 = 1 sets the port as an output 
setupPMODB:
	PUSH {lr, r2-r6}
	LDR r3, =MIO_BASE_ADDR
	LDR r5, =PMODB_MASK
	CMP r1, #0
	BNE setup_PMODB_output
	setup_PMODB_input: @ inout = 0
		LDR r4, [r3, #0x284]		@ r4 = DIR_2
		MVN r5, r5					@ ~PMODB_MASK
		AND r6, r4, r5				@ DIR_2 & ~PMODB_MASK
		STR r6, [r3, #0x284]		@ DIR_2 = DIR_2 & ~PMODB_MASK
		LDR r4, [r3, #0x288]		@ r4 = OE_2
		AND r6, r4, r5				@ OE_2 & ~PMODB_MASK
		STR r6, [r3, #0x288]		@ OE_2 = OE_2 & ~PMODB_MASK
	B endSetupPMOD
	setup_PMODB_output: @ inout = 1
		LDR r4, [r3, #0x284]		@ r4 = DIR_2
		ORR r6, r4, r5				@ DIR_2 | PMODB_MASK
		STR r6, [r3, #0x284]		@ DIR_2 = DIR_2 | PMODB_MASK
		LDR r4, [r3, #0x288]		@ r4 = OE_2
		ORR r6, r4, r5				@ OE_2 | PMODB_MASK
		STR r6, [r3, #0x288]		@ OE_2 = OE_2 | PMODB_MASK
	B endSetupPMOD
	endSetupPMOD:
		POP {lr, r2-r6}
		BX LR


# unsigned int value r1; a eight bit binary number (active low)
writePMODB:
	PUSH {lr, r3-r9}
	LDR r3, =MIO_BASE_ADDR
	LDR r4, =PMODB_MASK
	MVN r5, r4				@ r5 = ~PMODB_MASK
	LDR r6, [r3, #0x48]		@ r6 = DATA_2
	AND r7, r6, r5			@ r7 = DATA_2 & ~PMODB_MASK
	AND r8, r4, r1, LSL #7  @ r8 = PMODB_MASK & (value << 7)
	ORR r9, r7, r8			@ r9 = (DATA_2 & ~PMODB_MASK) | (PMODB_MASK & (value << 7))
	STR r9, [r3, #0x48]		@ DATA_2 = r9
	POP {lr, r3-r9}
	BX lr


# unsigned int that is returned from the function r0;
readPMODB:
	PUSH {lr, r1-r6}
	LDR r3, =MIO_BASE_ADDR
	LDR r4, =PMODB_MASK	    @ r4 = PMODB_MASK
	LDR r5, [r3, #0x68]		@ r5 = DATA_2_RO
	AND r6, r5, r4			@ r6 = PMODB_MASK & DATA_2_RO
	LSR r0, r6, #7			@ r0 = (PMODB_MASK & DATA_2_RO) >> 7

	POP {lr, r1-r6}
	BX lr

.endif /* SRC_PMOD_S_ */
