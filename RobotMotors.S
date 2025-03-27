/*
 * RobotMotors.S
 *
 *  Created on: Apr 4, 2022
 *      Author: jacob
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
	MOV r0, #0
	STR r0, [r1, #0x04]

	# Setup the motor PWM freq. of 100MHz / 4095 = 24.42kHz
	MOV r0, #4095
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

# Let's assume that r1 is passed into this function call as the base address of the corresponding motor to modify
# Let's assume that r2 is passed into this function call as the motor dir; 0 for clockwise, 1 for counter-clockwise
change_motor_dir:
	# IT WOULD BE WISE TO ADD SOME CODE HERE TO FIRST CHECK THE CURRENT MOTOR DIRECTION, IF WE ARE TRULY CHANGING
	# DIRECTIONS, THEN FIRST SET SPEED TO 0, AND CHANGE DIRECTIONS. YOU CAN SET SPEED BACK TO ITS VALUE AFTERWARDS.

	# Change motor dir to r2
	STR r2, [r1, #0x08]

	BX lr

# Let's assume that r1 is passed into this function call as the base address of the corresponding motor to modify
# Let's assume that r0 returns the motors RPM value
read_motor_rpm:

	# As soon as the encoder is enabled, a raw RPM value is generated.
	# In order to read another raw RPM value, the encoder enable bit must be set to 0 and then 1 again

	# 1. Set Encoder EN to 1

	# 2. Short delay to wait until the value has been updated in read register

	# 3. Grab the raw RPM value.

	# 4. Manipulate to true RPM value based on: RPM = (1MHz / (RPM_raw * GearRatio)) * (60s/min)

	# 5. Clear Encoder EN to 0

	BX lr


.endif /* SRC_ROBOTMOTORS_S_ */
