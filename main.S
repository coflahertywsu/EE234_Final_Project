/*
 * main.S
 *
 *  Created on: Mar 23, 2025
 *      By: Ron Shackelford
 *
 */

.include "../src/robomal.S"
.include "../src/LineFollower.S"
.include "../src/uart.S"
.include "../src/esp32.S"
.include "../src/rcMode.S"

.global main

.data

.text

main:
	# Setup comms
	BL uart0_init
	BL uart1_init
	BL esp32_init
	BL esp32_config_client

	# Setup Motor 0 (connected to top row of PMODC)
	LDR r1, =MOTOR_0_BASEADDR
	BL setup_motor

	# Setup Motor 1 (connected to bottom row of PMODC)
	LDR r1, =MOTOR_1_BASEADDR
	BL setup_motor

    # setup interrupts
    BL disable_interrupts
    BL configure_GTC
    BL configure_GIC

    # Xil_ExceptionRegisterHandler(5, IRQ_Handler, NULL)
    MOV r0, #5
    LDR r1, =IRQ_Handler
    MOV r2, #0
    BL Xil_ExceptionRegisterHandler

    BL enable_interrupts

	whileOne:
		BL uart0_read_structured    @ read 3 byte packet (3rd byte null), returns buffer address (r0)
		LDRB r0, [r0]				@ load first byte from uart0 data
		CMP r0, #0xF0				@ is it RC mode button?
		BLEQ rc_mode
		CMP r0, #0xF1				@ is it program robot button?
		BLEQ program_mode	
		CMP r0, #0xF2				@ is it line follower button?
		BLEQ line_follower_mode

		B whileOne

.end
