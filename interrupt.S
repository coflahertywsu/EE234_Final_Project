/*
*   interrupt.S
*   created: March 10th, 2025
*   edited:  March 10th, 2025
*       author: Ron Shackelford
*/
@ Conditional Compilation Guard Code
@ Allows us to build/compile this file once
@ regardless of how many files we .include it in
.ifndef SRC_interrupt_S_
.set SRC_interrupt_S_, 1

.include "../src/timers.S"
.include "../src/motorPID.S"
@ .include "../src/lineFollower.S"

#  Important Base Registers of GIC
.set ICDIPTR_BASEADDR, 0xF8F01800
.set ICDICER_BASEADDR, 0xF8F01180
.set ICDDCR_BASEADDR, 0xF8F01000
.set ICDIPR_BASEADDR, 0xF8F01400
.set ICDICFR_BASEADDR, 0xF8F01C00
.set ICDISER_BASEADDR, 0xF8F01100
.set ICCPMR_BASEADDR, 0xF8F00104
.set ICCICR_BASEADDR, 0xF8F00100
.set ICCIAR_BASEADDR, 0xF8F0010C
.set ICCEOIR_BASEADDR, 0xF8F00110

# Important Base Registers of GPIO
.set GPIO_BASEADDR, 0xE000A000

# important Base Registers of GTC
.set GTC_BASEADDR, 0xF8F00200

# important Base Registers of TTC0
.set TTC0_BASEADDR, 0xF8001000

.text

# Disable ALL interrupts on the CPU-side
disable_interrupts:
MSR cpsr_c, #0b11011111
MOV pc, lr

# Enable ALL interrupts on the CPU-side
enable_interrupts:
MSR cpsr_c, #0b01011111
MOV pc, lr

# Configuring the GIC
configure_GIC:

    # 1. Disable interrupt masks and any CPU's of handling interrupts (ICDIPTR and ICDICER)
    LDR r0, =ICDIPTR_BASEADDR
    MOV r1, #0
    STR r1, [r0, #0x18] @ GTC interrupt 27
    @ STR r1, [r0, #0x28] @ TTC0 interrupt 42

    LDR r0, =ICDICER_BASEADDR
    LDR r1, =#0x8000000 @ for interrupt 27
    STR r1, [r0]
    @ LDR r1, =#0x400 @ for interrupt 42
    @ STR r1, [r0, #0x04]

    # 2. Disable the distributor using Distributor Control Register (ICDDCR)
    LDR r0, =ICDDCR_BASEADDR
    MOV r1, #0
    STR r1, [r0]

    # 3. Set priority levels in the Interrupt Priority Register (ICDIPR)
    LDR r0, =ICDIPR_BASEADDR
    LDR r1, =#0x50000000 @ most significant byte is 0b01010000; 10/32 b/c lowest 3-bits dropped
    STR r1, [r0, #0x18]
    @ MOV r1, #0x400000 @ TTC0 priority is 8/32; 0b01000
    @ STR r1, [r0, #0x28] 

    # 4. Configure Interrupt Processor Targets Registers (ICDIPTR)
    LDR r0, =ICDIPTR_BASEADDR
    LDR r1, =#0x1000000
    STR r1, [r0, #0x18]
    @ MOV r1, #0x10000
    @ STR r1, [r0, #0x28]

    # 5. Set Interrupt Sensistivity int Interrupt Configuration Register (ICDICFR)
    LDR r0, =ICDICFR_BASEADDR
    LDR r1, =#0x7DC00000
    STR r1, [r0, #0x04]
    @ LDR r1, =#0x55555555
    @ STR r1, [r0, #0x08]

    # 6. Enable Interrupts in the Interrupt Set-Enable Register (ICDISER)
    LDR r0, =ICDISER_BASEADDR
    LDR r1, =#0x8000000
    STR r1, [r0]
    @ LDR r1, =#0x400
    @ STR r1, [r0, #0x04]

    # 7. Enable all priority levels in the Interrupt Priority Mask Register (ICCPMR)
    LDR r0, =ICCPMR_BASEADDR
    MOV r1, #0xFF
    STR r1, [r0]

    # 8. Enable Interrupts in the CPU Interface Control Register (ICCICR)
    LDR r0, =ICCICR_BASEADDR
    MOV r1, #0b11
    STR r1, [r0]

    # 9. Enable Distributor in the Distributor Control Register (ICDDCR)
    LDR r0, =ICDDCR_BASEADDR
    MOV r1, #0b11
    STR r1, [r0]

    MOV pc, lr 

# Interrrupt Service Request Handler
IRQ_Handler:

    # First grab the IRQ ID that caused us to enter the IRQ handler
    LDR r0, =ICCIAR_BASEADDR
    LDR r1, [r0]

    # Did we enter the handler because of IRQ ID 27?
    CMP r1, #27
    BEQ GTC_Int
    @ CMP r1, #42
    @ BEQ TTC0_Int
    # Otherwise...
    BNE endIRQ_Handler

GTC_Int:
    PUSH {lr, r2, r3}
    BL update_motors
    # Clear GTC interrupt sticky bit 
    LDR r3, =GTC_BASEADDR
    MOV r2, #1
    STR r2, [r3, #0x0C]
    B endIRQ_Handler

@ TTC0_Int:
@     PUSH {lr, r2, r3}
@     BL update_line_array   //////////////////////////// Look ///////////////////////
    
@     # clear the TTC interrupt by reading the interrupt status register
@     LDR r2, =TTC0_BASEADDR
@     @ MOV r2, #1
@     @ STR r2, [r3, #0x54]
@     LDR r2, [r2, #0x54]


endIRQ_Handler:
    LDR r0, =ICCEOIR_BASEADDR
    MOV r1, #27
    STR r1, [r0]
    
    POP {lr, r2, r3}
    MOV pc, lr

.endif /* SRC_interrupt_S_ */