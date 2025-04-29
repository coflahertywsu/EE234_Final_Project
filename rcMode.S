/*
*   rcMode.S
*   created: March 17th, 2025
*   edited:  March 21st, 2025
*       author: Ron Shackelford
*/
@ Conditional Compilation Guard Code
@ Allows us to build/compile this file once
@ regardless of how many files we .include it in
.ifndef SRC_RCMODE_S_ 
.set SRC_RCMODE_S_, 1

.data
rc_mode_string: .asciz "Start your engines!  This is RC mode.\n"

//the jump table below acts as a family for the X data based on the joystick Y data
yPosition: .word zeroY, oneY, twoY, threeY, fourY, fiveY, sixY, sevenY

// the jump tables below hardcode the motor speeds and directions based on the joystick X data
zeroYPositions: .word zeroY0, zeroY1, zeroY2, zeroY3, zeroY4, zeroY5, zeroY6, zeroY7
oneYPositions: .word oneY0, oneY1, oneY2, oneY3, oneY4, oneY5, oneY6, oneY7
twoYPositions: .word twoY0, twoY1, twoY2, twoY3, twoY4, twoY5, twoY6, twoY7
threeYPositions: .word threeY0, threeY1, threeY2, threeY3, threeY4, threeY5, threeY6, threeY7
fourYPositions: .word fourY0, fourY1, fourY2, fourY3, fourY4, fourY5, fourY6, fourY7
fiveYPositions: .word fiveY0, fiveY1, fiveY2, fiveY3, fiveY4, fiveY5, fiveY6, fiveY7
sixYPositions: .word sixY0, sixY1, sixY2, sixY3, sixY4, sixY5, sixY6, sixY7
sevenYPositions: .word sevenY0, sevenY1, sevenY2, sevenY3, sevenY4, sevenY5, sevenY6, sevenY7

.text

rc_mode:
    PUSH {lr, r1-r12}
    LDR r1, =rc_mode_string
    BL uart1_write
    
    // clear the registers that will hold program data
    MOV r9, #0
    MOV r10, #0
    MOV r11, #0
    MOV r12, #0

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

        LDR r1, =yPosition
        LDR r1, [r1, r10, LSL #2]
        BX r1
        zeroY:
            LDR r1, =zeroYPositions
            LDR r1, [r1, r9, LSL #2]
            BX r1
            zeroY0:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                MOV r11, #420
                MOV r12, #100
                B joystick_read_loop
            zeroY1:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #420
                MOV r12, #200                
                B joystick_read_loop            
            zeroY2:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #420
                MOV r12, #300
                B joystick_read_loop            
            zeroY3:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #420
                MOV r12, #420
                B joystick_read_loop            
            zeroY4:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #420
                MOV r12, #420
                B joystick_read_loop            
            zeroY5:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #300
                MOV r12, #420
                B joystick_read_loop            
            zeroY6:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #200
                MOV r12, #420
                B joystick_read_loop            
            zeroY7:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                MOV r11, #100
                MOV r12, #420
                B joystick_read_loop

        oneY:
            LDR r1, =oneYPositions
            LDR r1, [r1, r9, LSL #2]
            BX r1
            oneY0:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                MOV r11, #300
                MOV r12, #100
                B joystick_read_loop
            oneY1:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #300
                MOV r12, #175                
                B joystick_read_loop            
            oneY2:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #300
                MOV r12, #225
                B joystick_read_loop            
            oneY3:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #300
                MOV r12, #300
                B joystick_read_loop            
            oneY4:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #300
                MOV r12, #300
                B joystick_read_loop            
            oneY5:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #225
                MOV r12, #300
                B joystick_read_loop            
            oneY6:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #175
                MOV r12, #300
                B joystick_read_loop            
            oneY7:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                MOV r11, #100
                MOV r12, #300
                B joystick_read_loop

        twoY:
            LDR r1, =twoYPositions
            LDR r1, [r1, r9, LSL #2]
            BX r1
            twoY0:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                MOV r11, #150
                MOV r12, #0
                B joystick_read_loop
            twoY1:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #75                
                B joystick_read_loop            
            twoY2:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #120
                B joystick_read_loop            
            twoY3:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #150
                B joystick_read_loop            
            twoY4:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #150
                B joystick_read_loop            
            twoY5:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #120
                MOV r12, #150
                B joystick_read_loop            
            twoY6:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #75
                MOV r12, #150
                B joystick_read_loop            
            twoY7:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                MOV r11, #0
                MOV r12, #150
                B joystick_read_loop

        threeY:
            LDR r1, =threeYPositions
            LDR r1, [r1, r9, LSL #2]
            BX r1
            threeY0:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                MOV r11, #350
                MOV r12, #350
                B joystick_read_loop
            threeY1:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #225
                MOV r12, #225                
                B joystick_read_loop            
            threeY2:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #150
                B joystick_read_loop            
            threeY3:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #0
                MOV r12, #0
                B joystick_read_loop            
            threeY4:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #0
                MOV r12, #0
                B joystick_read_loop            
            threeY5:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #150
                B joystick_read_loop            
            threeY6:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #225
                MOV r12, #225
                B joystick_read_loop            
            threeY7:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                MOV r11, #350
                MOV r12, #350
                B joystick_read_loop            

        fourY:
            LDR r1, =fourYPositions
            LDR r1, [r1, r9, LSL #2]
            BX r1
            fourY0:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                MOV r11, #350
                MOV r12, #350
                B joystick_read_loop
            fourY1:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #225
                MOV r12, #225                
                B joystick_read_loop            
            fourY2:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #150
                B joystick_read_loop            
            fourY3:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #0
                MOV r12, #0
                B joystick_read_loop            
            fourY4:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #0
                BL change_motor_dir            
                MOV r11, #0
                MOV r12, #0
                B joystick_read_loop            
            fourY5:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #150
                B joystick_read_loop            
            fourY6:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #225
                MOV r12, #225
                B joystick_read_loop            
            fourY7:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #0
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                MOV r11, #350
                MOV r12, #350
                B joystick_read_loop              

        fiveY:
            LDR r1, =fiveYPositions
            LDR r1, [r1, r9, LSL #2]
            BX r1
            fiveY0:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                MOV r11, #150
                MOV r12, #0
                B joystick_read_loop
            fiveY1:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #75                
                B joystick_read_loop            
            fiveY2:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #120
                B joystick_read_loop            
            fiveY3:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #150
                B joystick_read_loop            
            fiveY4:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #150
                MOV r12, #150
                B joystick_read_loop            
            fiveY5:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #120
                MOV r12, #150
                B joystick_read_loop            
            fiveY6:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #75
                MOV r12, #150
                B joystick_read_loop            
            fiveY7:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                MOV r11, #0
                MOV r12, #150
                B joystick_read_loop            

        sixY:
            LDR r1, =sixYPositions
            LDR r1, [r1, r9, LSL #2]
            BX r1        
            sixY0:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                MOV r11, #300
                MOV r12, #100
                B joystick_read_loop
            sixY1:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #300
                MOV r12, #175                
                B joystick_read_loop            
            sixY2:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #300
                MOV r12, #225
                B joystick_read_loop            
            sixY3:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #300
                MOV r12, #300
                B joystick_read_loop            
            sixY4:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #300
                MOV r12, #300
                B joystick_read_loop            
            sixY5:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #225
                MOV r12, #300
                B joystick_read_loop            
            sixY6:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #175
                MOV r12, #300
                B joystick_read_loop            
            sixY7:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                MOV r11, #100
                MOV r12, #300
                B joystick_read_loop            

        sevenY:
            LDR r1, =sevenYPositions
            LDR r1, [r1, r9, LSL #2]
            BX r1
            sevenY0:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                MOV r11, #420
                MOV r12, #100
                B joystick_read_loop
            sevenY1:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #420
                MOV r12, #200                
                B joystick_read_loop            
            sevenY2:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #420
                MOV r12, #300
                B joystick_read_loop            
            sevenY3:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #420
                MOV r12, #420
                B joystick_read_loop            
            sevenY4:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #420
                MOV r12, #420
                B joystick_read_loop            
            sevenY5:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #300
                MOV r12, #420
                B joystick_read_loop            
            sevenY6:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir            
                MOV r11, #200
                MOV r12, #420
                B joystick_read_loop            
            sevenY7:
                LDR r1, =MOTOR_0_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                LDR r1, =MOTOR_1_BASEADDR
                MOV r2, #1
                BL change_motor_dir
                MOV r11, #100
                MOV r12, #420
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





.endif /* SRC_RCMODE_S_ */
