/*
 * RobotMotors.S
 *
 *  Created on: Apr 4, 2022
 *      Author: jacob
 *	Updated on: March, 23 2025
 *		By: Ron Shackelford
 */

.ifndef SRC_ROBOTMOTORS_S_
.set SRC_ROBOTMOTORS_S_, 1

# WARNING: DO NOT HAVE MOTORS DIRECTLY PLUGGED INTO BLACKBOARD
#          WHEN THE BOARD IS POWERED UP AND BEFORE PROGRAMMING THE BOARD.
# 		   THE H-BRIDGE WILL CREATE A SHORT-CIRCUIT AND YOU WILL DAMAGE IT.
#
# 		   YOU CAN CONNECT THE MOTORS AFTER YOU HAVE UPLOADED THE PROGRAM TO YOUR BOARD
#
#		   IF YOU SMELL BURNING, SHUT THE POWER OFF ON YOUR BOARD IMMEDIATELY TO PREVENT DAMAGE.
#
#		   This issue should largely be absent if you are using the DHB1 PMOD.
#
#		   However, still know that if you leave the DHB1 module and the battery connected,
#		   the motors will spin at full speed prior to programming your board.

.set MOTOR_0_BASEADDR, 0x43C60000	@ This is the motor connected to the top row pins of PMODC port
.set MOTOR_1_BASEADDR, 0x43C80000	@ This is the motor connected to the bottom row pins of PMODC port

# The H-Bridge IP Block consists of the following register map:

# |	  Register Name   |	             Function   		|	 Offset   |	  Bits   |
# --------------------------------------------------------------------------------
# |	   HB_EN		  |   Enables the H-Bridge  		|    0x0000   |    1     |
# |	   HB_DIR	  	  |   Sets the Motor Direction      |    0x0004   |    1     |
# |	   HB_SPEED	  	  |   Sets PWM Duty Cycle			|    0x0008   |    32    |
# |	   HB_ENC_EN	  |   Enables the Feedback Encoder	|    0x000C   |    1     |
# |	   HB_RPM_READ 	  |   Provides the Motor RPM 		|    0x0010   |    16    |
# |	   HB_PERIOD	  |   Sets PWM Frequency			|    0x0014   |    32    |

# HB_EN[0] - This bit is used to enable the H-Bridge system. Writing a 1 to this bit enables the H-Bridge.
# HB_DIR[0] - This bit is used to choose the direction of rotation. Writing a 0 or 1 to this register corresponds
#             to clockwise or counter-clockwise rotation of the motor, respectively.
# HB_SPEED[31:0] - Writing into these bits will define the PWM duty cycle of the motor;
#				   The duty cycle is calculated as HB_SPEED / HB_PERIOD. HB_SPEED should be bounded between 0 and HB_PERIOD.
# HB_ENC_EN[0] - This bit is used to choose to enable / start an RPM reading while the HB_EN is 1.
#				 Writing a 1 to this enables and starts the RPM reading from the decoder block.
# HB_RPM_READ[15:0] - Reading from this register returns a half word that represents the raw value of RPM.
#					  Raw RPM can be used to calculate the final RPM value using the folowing equation:
#					  RPM = (1MHz / (RPM_raw * GearRatio)) * (60s/min)
# HB_PERIOD[31:0] - Writing into these bits will define the PWM frequency of the motor;
#				    The PWM frequency is calculated as 100MHz / HB_PERIOD. (i.e. if HB_PERIOD = 4095, PWM freq. = 24.42kHz)

.text

# Let's assume that r1 is passed into this function call as the base address of the corresponding motor to setup
setup_motor:

	# Setup initial motor speed (hence duty cycle) to 0; (Make sure H-bridge enable starts with motors off)
	MOV r0, #0
	STR r0, [r1, #0x08]

	# Setup initial motor direction if we want
	MOV r0, #1
	STR r0, [r1, #0x04]

	# Setup the motor PWM freq. of 100MHz / 131071 = 1526 Hz
	LDR r0, =#65535
	STR r0, [r1, #0x14]

	# Enable the H-Bridge
	MOV r0, #1
	STR r0, [r1]

	BX lr

# Let's assume that r1 is passed into this function call as the base address of the corresponding motor to modify
# Let's assume that r2 is passed into this function call as the motor speed
change_motor_speed:
	# Change motor speed (hence duty cycle) to r2
	STR r2, [r1, #0x08]
	BX lr

# r1 is the base address of the corresponding motor to modify
# r2 is the motor dir; 0 for backward, 1 for forward
change_motor_dir:
	PUSH {r0, r3}
	# Change motor direction to value stored in r2
	LDR r0, [r1, #0x08] @ store speed in r0
	MOV r3, #0
	STR r3, [r1, #0x08] @ set speed to 0
	STR r2, [r1, #0x04] @ change direction
	STR r0, [r1, #0x08] @ reset speed
	POP {r0, r3}
	BX lr

# Let's assume that r1 is passed into this function call as the base address of the corresponding motor to modify
# Let's assume that r0 returns the motors RPM value
read_motor_rpm:
	PUSH {lr, r2, r3, r4}
	MOV r4, r1
	# As soon as the encoder is enabled, a raw RPM value is generated.
	# In order to read another raw RPM value, the encoder enable bit must be set to 0 and then 1 again

	# 1. Set Encoder EN to 1
	MOV r2, #1
	STR r2, [r4, #0x0C]

	# 2. Short delay to wait until the value has been updated in read register
	NOP
	NOP
	NOP
	NOP
	NOP

	# 3. Grab the raw RPM value.
	LDR r3, [r4, #0x10]

	# 4. Manipulate to true RPM value based on: RPM = (1MHz / (RPM_raw * GearRatio)) * (60s/min)
	MOV r2, #3712
	MUL r3, r3, r2
	LDR r2, =#100000000
	MOV r0, #0
	CMP r3, #0
	BEQ endReadRPM
	divideRPM:
		SUB r2, r2, r3
		ADD r0, r0, #1
		CMP r2, r3
		BGT divideRPM
	MOV r1, #60
	MUL r0, r0, r1

	# 5. Clear Encoder EN to 0
	endReadRPM:
		MOV r2, #0
		STR r2, [r4, #0x0C]
		POP {lr, r2, r3, r4}
		BX lr


# delay uses counts down from the number passed in r1
# If 1 is placed in r1 the delay is ~ 10.7 ns 
# 100,000,000 in r1 is ~ 1.7 sec
delay:
    again:
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        SUBS r1, r1, #1
        BNE again
    BX lr


.endif /* SRC_ROBOTMOTORS_S_ */
