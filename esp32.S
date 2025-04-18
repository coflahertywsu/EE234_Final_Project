.ifndef ESP32_S
.set ESP32_S, 1

.include "../src/uart.S"
.include "../src/timers.S"

.set GPIO_BASEADDR, 0xE000A000

.data
esp32_config_mux_cmd: .asciz "AT+CIPMUX=0\r\n"
esp32_start_TCP_cmd: .asciz "AT+CIPSTART=\"TCP\",\"192.168.5.1\",80\r\n"
esp32_passthrough_mode_cmd: .asciz "AT+CIPMODE=1\r\n"
esp32_start_open_send_cmd:   .asciz "AT+CIPSEND\r\n"
esp32_return_newline_str: .asciz "\r\n"
esp32_marco_polo_str: .byte 0x51, 0x0


.text

esp32_init:
    PUSH {lr, r1, r2}
    # set MIO26 (ESP32_EN) as output, enable its output, drive the pin high
    LDR r1, =GPIO_BASEADDR
    LDR r2, =0x4000000 @ 0b1 << 26
    STR r2, [r1, #0x204] @ GPIO_DIRM_0; set the pin as an output
    STR r2, [r1, #0x208] @ GPIO_OUTE_0; enable the output pin
    STR r2, [r1, #0x40]  @ GPIO_MASK_DATA_0_MSW; drive the output pin high

    # Now the ESP32_EN should be driven high and the radio should be turned on
    POP {lr, r1, r2}
    BX lr

esp32_read_response:
    PUSH {lr, r1-r3}
    LDR r2, =100000000
    MOV r3, #0
    
    esp32_boot_loop:
        BL uart_wifi_to_usb
        ADD r3, r3, #1
        CMP r3, r2
        BNE esp32_boot_loop

    POP {lr, r1-r3}
    BX lr

@ inifinite blocking function, only for debugging/console access to esp32
esp32_debug:
    BL uart_wifi_to_usb
    BL uart_usb_to_wifi
    B esp32_debug

esp32_config_mux:
    PUSH {lr, r1}
    LDR r1, =esp32_config_mux_cmd
    BL uart0_wifi_write
    POP {lr, r1} 
    BX lr

esp32_start_TCP:
    PUSH {lr, r1}
    LDR r1, =esp32_start_TCP_cmd
    BL uart0_wifi_write
    POP {lr, r1} 
    BX lr

esp32_config_passthrough_mode:
    PUSH {lr, r1}
    LDR r1, =esp32_passthrough_mode_cmd
    BL uart0_wifi_write
    POP {lr, r1} 
    BX lr

esp32_start_open_send:
    PUSH {lr, r1}
    LDR r1, =esp32_start_open_send_cmd
    BL uart0_wifi_write
    POP {lr, r1} 
    BX lr

esp32_marco:
    PUSH {lr, r1, r2}

    esp32_marco_loop:
        LDR r1, =esp32_marco_polo_str
        BL uart0_wifi_write
        LDR r1, =1000
        BL blocking_delay
        BL uart0_wifi_read
        esp32_marco_read_loop:
            LDRB r2, [r0], #1
            CMP r2, #0xAA
            BEQ esp32_marco_end
            CMP r2, #0
            BEQ esp32_marco_loop
            B esp32_marco_read_loop
        
        esp32_marco_end:

    POP {lr, r1, r2}
    BX lr


esp32_polo:



@ esp32_read:
@     PUSH {lr}
@     BL uart0_wifi_read
@     ADD r0, r0, #9
@     PUSH {lr}

@ esp32_client_write:
@     PUSH {lr, r1}
@     BL esp32_config_client_write
@     BL uart0_wifi_write
@     LDR r1, =esp32_return_newline_str
@     BL uart0_wifi_write
@     POP {lr, r1}
@     BX lr

@ esp32_server_write:
@     PUSH {lr, r1}
@     BL esp32_config_server_write
@     BL uart0_wifi_write
@     LDR r1, =esp32_return_newline_str
@     BL uart0_wifi_write
@     POP {lr, r1}
@     BX lr

@ esp32_config_client_write:
@     PUSH {lr, r1}
@     LDR r1, =esp32_client_write_cmd
@     BL uart0_wifi_write
@     POP {lr, r1}

@ esp32_config_server_write:
@     PUSH {lr, r1}
@     LDR r1, =esp32_server_write_cmd
@     BL uart0_wifi_write
@     POP {lr, r1}



.endif @ ESP32_S