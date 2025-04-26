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
.set PMODB_MASK, 0x0F80 	@ IR LED pin information is in bits 7,8,9,10,11 of the above registers
.set PMODB_TOP_MASK, 0x0780 	@ top pin information is in bits 7,8,9,10 of the above registers
.set PMODB_BOTTOM_MASK, 0x7800  @ bottom pin information is in bits 11,12,13,14 of the above registers

.set KEY_COL1, 0b0111 @ we use this mask to write to column 1
.set KEY_COL2, 0b1011 @ we use this mask to write to column 2
.set KEY_COL3, 0b1101 @ we use this mask to write to column 3
.set KEY_COL4, 0b1110 @ we use this mask to write to column 4

.text

@ unsigned int r1; inout = 0 sets the row as an input, inout = 1 sets the row as an output 
@ unsigned int r2; row = 0 means PMODB top row, row = 1 means PMODB bottom row
setupPMODB:
	PUSH {lr, r2-r6}
	@ if (row == 0)
	LDR r3, =MIO_BASE_ADDR
	CMP r2, #0
	BNE setupRowTrue
	setupRowFalse: @ row = 0
		@ if (inout == 0)
		LDR r5, =PMODB_TOP_MASK
		CMP r1, #0
		BNE setupRowFalseInoutTrue
		setupRowFalseInoutFalse: @ row = 0, inout = 0
			LDR r4, [r3, #0x284]		@ r4 = DIR_2
			MVN r5, r5					@ ~PMODB_TOP_MASK
			AND r6, r4, r5				@ DIR_2 & ~PMODB_TOP_MASK
			STR r6, [r3, #0x284]		@ DIR_2 = DIR_2 & ~PMODB_TOP_MASK
			LDR r4, [r3, #0x288]		@ r4 = OE_2
			AND r6, r4, r5				@ OE_2 & ~PMODB_TOP_MASK
			STR r6, [r3, #0x288]		@ OE_2 = OE_2 & ~PMODB_TOP_MASK
		B endSetupPMOD
		setupRowFalseInoutTrue: @ row = 0, inout = 1
			LDR r4, [r3, #0x284]		@ r4 = DIR_2
			ORR r6, r4, r5				@ DIR_2 | PMODB_TOP_MASK
			STR r6, [r3, #0x284]		@ DIR_2 = DIR_2 | PMODB_TOP_MASK
			LDR r4, [r3, #0x288]		@ r4 = OE_2
			ORR r6, r4, r5				@ OE_2 | PMODB_TOP_MASK
			STR r6, [r3, #0x288]		@ OE_2 = OE_2 | PMODB_TOP_MASK
		B endSetupPMOD
	setupRowTrue: @ row = 1
		// @ (inout == 0)
		LDR r5, =PMODB_BOTTOM_MASK
		CMP r1, #0
		BNE setupRowTrueInoutTrue
		setupRowTrueInoutFalse: @ row = 1, inout = 0
			LDR r4, [r3, #0x284]		@ r4 = DIR_2
			MVN r5, r5					@ ~PMODB_BOTTOM_MASK
			AND r6, r4, r5				@ DIR_2 & ~PMODB_BOTTOM_MASK
			STR r6, [r3, #0x284]		@ DIR_2 = DIR_2 & ~PMODB_BOTTOM_MASK
			LDR r4, [r3, #0x288]		@ r4 = OE_2
			AND r6, r4, r5				@ OE_2 & ~PMODB_BOTTOM_MASK
			STR r6, [r3, #0x288]		@ OE_2 = OE_2 & ~PMODB_BOTTOM_MASK
		B endSetupPMOD
		setupRowTrueInoutTrue: @ row = 1, inout = 1
			LDR r4, [r3, #0x284]		@ r4 = DIR_2
			ORR r6, r4, r5				@ DIR_2 | PMODB_BOTTOM_MASK
			STR r6, [r3, #0x284]		@ DIR_2 = DIR_2 | PMODB_BOTTOM_MASK
			LDR r4, [r3, #0x288]		@ r4 = OE_2
			ORR r6, r4, r5				@ OE_2 | PMODB_BOTTOM_MASK
			STR r6, [r3, #0x288]		@ OE_2 = OE_2 | PMODB_BOTTOM_MASK

		endSetupPMOD:
			POP {lr, r2-r6}
			BX LR


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
