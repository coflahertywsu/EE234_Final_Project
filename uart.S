.ifndef UART_S
.set UART_S, 1

.include "../src/timers.S"

.set UART0_CTRL_ADDR, 0xE0000000
.set UART0_MODE_ADDR, 0xE0000004
.set UART0_BAUDGEN_ADDR, 0xE0000018
.set UART0_BAUDRATE_D_ADDR, 0xE0000034
.set UART0_TRX_FIFO_ADDR, 0xE0000030
.set UART0_INTERRUPT_EN_ADDR, 0xE0000008
.set UART0_INTERRUPT_STAT_ADDR, 0xE0000014

.set UART1_CTRL_ADDR, 0xE0001000
.set UART1_MODE_ADDR, 0xE0001004
.set UART1_BAUDGEN_ADDR, 0xE0001018
.set UART1_BAUDRATE_D_ADDR, 0xE0001034
.set UART1_TRX_FIFO_ADDR, 0xE0001030
.set UART1_INTERRUPT_EN_ADDR, 0xE0001008
.set UART1_INTERRUPT_STAT_ADDR, 0xE0001014

.data
uart0_read_buffer: .space 0xFF        @ Allocating wifi uart temp buffer
uart1_read_buffer: .space 0xFF         @ Allocating usb uart temp buffer
uart_colon_str: .asciz ":"

.text

@************************************************************
@ Function: uart_init
@ Description: Initializes the UART with the specified parameters.
@ Input parameters: r1 UART base address
@ Returns: None
@************************************************************
uart_init:
    PUSH {lr, r1, r2}

    @ resetting uart
    LDR r2, =0b11
    STR r2, [r1] 

    @ enabling TX and RX
    LDR r2, =0b10100
    STR r2, [r1]

    @ setting stop bits to 1, data bits to 8 and parity to none
    LDR r2, =0b0000100000
    STR r2, [r1, #0x4]

    @ setting baud rate to 115200
    LDR r2, =0x7C
    STR r2, [r1, #0x18]
    LDR r2, =6
    STR r2, [r1, #0x34]

    @ enabling FIFO full and empty interrupts
    LDR r2, =0b11110
    STR r2, [r1, #0x08]

    POP {lr, r1, r2}
    BX lr

uart0_init:
    PUSH {lr, r1}
    LDR r1, =UART0_CTRL_ADDR
    BL uart_init
    POP {lr, r1}

uart1_init:
    PUSH {lr, r1}
    LDR r1, =UART1_CTRL_ADDR
    BL uart_init
    POP {lr, r1}


@************************************************************
@ Function: serial_print_string
@ Description: Prints a null-terminated string to the serial console.
@ Input parameters: 
@      - r1: Address of the null-terminated string
@      - r2: Base address of UART
@ Returns: None
@************************************************************

uart_write:
    PUSH {r1, r2, r3, lr}
    
    uart_write_loop:
        BL check_for_full_tx_buffer
        LDRB r3, [r1], #1  
        CMP r3, #0  
        STRB r3, [r2, #0x30]        
        BEQ uart_write_done          
        B uart_write_loop       
    uart_write_done:
        POP {r1, r2, r3, lr}
        BX lr


uart1_write:
    PUSH {r1, r2, r3, lr}
    LDR r2, =UART1_CTRL_ADDR
    BL uart_write
    POP {r1, r2, r3, lr}
    BX lr

uart0_write:
    PUSH {r1, r2, r3, lr}
    LDR r2, =UART0_CTRL_ADDR
    BL uart_write
    POP {r1, r2, r3, lr}
    BX lr

@ requires null char at the end
@ input r0 is address of read bufffer
@ input r1 is UART base address
@ return r0 is address of filled read buffer
uart_read:
    PUSH {lr, r0-r2}
    
    uart_read_loop:
        LDRB r2, [r1, #0x30] 
        STRB r2, [r0], #1        
        CMP r2, #0
        BNE uart_read_loop

    POP {lr, r0-r2}
    BX lr

uart0_wifi_read:
    PUSH {lr, r1}
    LDR r0, =uart0_read_buffer
    LDR r1, =UART0_CTRL_ADDR
    BL uart_read
    POP {lr, r1}
    BX lr

uart1_usb_read:
    PUSH {lr, r1}
    LDR r0, =uart1_read_buffer
    LDR r1, =UART0_CTRL_ADDR
    BL uart_read
    POP {lr, r1}
    BX lr

@ loads 1 byte from uart0 to uart1
uart0_to_uart1:
    PUSH {lr, r1, r2, r3}
    LDR r1, =UART0_CTRL_ADDR
    LDR r2, =UART1_CTRL_ADDR

    LDRB r3, [r1, #0x30]
    CMP r3, #0
    BEQ uart0_to_uart1_end

    STRB r3, [r2, #0x30]

    uart0_to_uart1_end:
        POP {lr, r1, r2, r3}
        BX lr



@ loads 1 byte from uart1 to uart0
uart1_to_uart0:
    PUSH {lr, r1, r2, r3}
    LDR r1, =UART1_CTRL_ADDR
    LDR r2, =UART0_CTRL_ADDR

    LDR r3, [r1, #0x30]
    CMP r3, #0
    BEQ uart1_to_uart0_end

    STRB r3, [r2, #0x30]

    CMP r3, #'\r'
    MOVEQ r3, #'\n'
    STREQ r3, [r2, #0x30]

    uart1_to_uart0_end:
        POP {lr, r1, r2, r3}
        BX lr

uart0_read_structured:
    PUSH {lr, r1-r4}
    LDR r0, =uart0_read_buffer
    LDR r2, =UART0_CTRL_ADDR
    LDR r3, =UART1_CTRL_ADDR

    wait_for_plus_or_null_loop:
        LDRB r4, [r2, #0x30]             @ Read byte from uart0
        CMP r4, #0
        STREQ r4, [r0]                  @ *** this should be STRBEQ but will probably work anyway ***
        BEQ end_structured_read         @ if null, store null char in first element of buffer and return
        STRB r4, [r3, #0x30]             @ else, pass to uart1
        CMP r3, #'+'                    @ if char = '+' break loop
        BNE wait_for_plus_or_null_loop  @ else, go to top of current loop
    
    LDR r1, =uart_colon_str          @ read uart0 into uart1 w/o storing until ':' reached
    BL uart0_read_until_string

    MOV r1, #0                          @ byte counter

    store_structured_data_loop:
        LDRB r4, [r2, #0x30]             @ read byte from uart0
        CMP r4, #0      
        BEQ store_structured_data_loop  @ if null go to top of loop (assuming bytes haven't arrived yet)
        STRB r4, [r0, r1]               @ else store in buffer to be returned and uart1
        STRB r4, [r3, #0x30]
        ADD r1, r1, #1                  
        CMP r1, #1                      
        BNE store_structured_data_loop  @ if two bytes read, break loop, else go to top
    
    LDRB r4, [r2, #0x30]                 @ reading last byte (it should be a null char)
    STRB r4, [r0, r1]

    end_structured_read:
        POP {lr, r1-r4}
        BX lr

    


@ reads uart0 until string match is reached.  No timeout.
uart0_read_until_string:
    PUSH {lr, r1-r6}

    LDR r2, =UART0_CTRL_ADDR
    LDR r3, =UART1_CTRL_ADDR

    read_until_phrase_loop:
        LDRB r4, [r1]                        @ Loading first char from input string
        MOV r5, #1                          @ Input string iterator

        uart_char_compare_loop:
            LDRB r6, [r2, #0x30]             @ Loading byte from uart0
            CMP r6, #0
            BEQ uart_char_compare_loop
            STRB r6, [r3, #0x30]             @ Passing byte through to uart1 (console)  
            CMP r4, r6
            BNE read_until_phrase_loop      @ If input and uart0 chars don't match start over
            LDRB r4, [r1, r5]                @ Else get next char from input string
            ADD r5, r5, #1                  @ Increment string iterator
            CMP r4, #0
            BNE uart_char_compare_loop      @ If next char is null char let subroutine end
                                            @ Else continue matching chars
    POP {lr, r1-r6}
    BX lr

@************************************************************
@ Function: uart1_write_hex_chars
@ Description: Prints a hexadecimal value to the serial console.
@ Input parameters: 
@      - r1: The value to print
@ Returns: None
@************************************************************
uart1_write_hex_chars:
    PUSH {r1, r2, r3, r4, r5, lr}
    LDR r2, =UART1_CTRL_ADDR

    MOV r3, #28          @ Shift value
    MOV r4, #0           @ printing_started = false
    MOV r5, r1

    CMP r5, #0
    MOVEQ r3, #0
    BEQ print_hex_0_to_9

    print_hex_loop:
        BL check_for_full_tx_buffer
        MOV r5, r1           @ Copy the value to r1
        LSR r5, r5, r3       @ Shift the value to get the current nibble
        AND r5, r5, #0xF     @ Mask out all but the least significant nibble

        CMP r5, #0
        BEQ remove_leading_zeros

    calc_hex_range:
        CMP r5, #9
        BLE print_hex_0_to_9
        BGT print_hex_a_to_f

    remove_leading_zeros:
        CMP r4, #1
        BEQ calc_hex_range
        BNE print_hex_done

    print_hex_0_to_9:          
        ADD r5, r5, #48      @ Convert to ASCII ('0'-'9')
        STRB r5, [r2, #0x30]
        MOV r4, #1
        B print_hex_done

    print_hex_a_to_f:
        ADD r5, r5, #87      @ Convert to ASCII ('a'-'f')
        STRB r5, [r2, #0x30]
        MOV r4, #1

    print_hex_done:
        SUBS r3, r3, #4      @ Move to the next nibble
        BGE print_hex_loop   @ Repeat until all nibbles are processed

    POP {r1, r2, r3, r4, r5, lr}
    BX lr


@ input r2 base address because it makes everthing simpler
check_for_full_tx_buffer:
    PUSH {r1, r2, lr}

    @ checking full buffer flag
    LDR r1, [r2, #0x14]
    AND r1, r1, #0b10000
    CMP r1, #0
    BEQ end_check_tx_buffer

    @ clearing full flag if full
    LDR r1, [r2, #0x14]
    ORR r1, r1, #0b10000
    STR r1, [r2, #0x14]

    wait_for_empty_tx_buffer:
        LDR r1, [r2, #0x14]
        LSR r1, r1, #3
        AND r1, r1, #1
        CMP r1, #1
        BNE wait_for_empty_tx_buffer


    end_check_tx_buffer:
        POP {r1, r2, lr}
        BX lr

.endif @ UART_S