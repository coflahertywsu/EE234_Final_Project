.ifndef ESP32_S
.set ESP32_S, 1

.include "../src/uart.S"
.include "../src/timers.S"

.set GPIO_BASEADDR, 0xE000A000

.data
esp32_config_mux_cmd: .asciz "AT+CIPMUX=1\r\n"
esp32_config_TCP_server_cmd: .asciz "AT+CIPSERVER=1,80\r\n"
esp32_start_TCP_cmd: .asciz "AT+CIPSTART=\"TCP\",\"192.168.5.1\",80\r\n"
esp32_passthrough_mode_cmd: .asciz "AT+CIPMODE=1\r\n"
esp32_send_packet_str: .asciz "AT+CIPSEND=0,3\r\n"
esp32_return_newline_str: .asciz "\r\n"
esp32_marco_polo_str: .byte 0x51, 0x0
esp32_ready_str: .asciz "ready"
esp32_got_ip_str: .asciz "GOT IP"
esp32_ok_str: .asciz "OK"
esp32_prompt_str: .asciz ">"
esp32_connect_str: .asciz "CONNECT"
esp32_server_configured_str: .asciz "\nServer is Configured\n"
esp32_client_configured_str: .asciz "\nClient is Configured\n"


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

esp32_config_server:
    PUSH {lr, r1}

    LDR r1, =esp32_ready_str                
    BL uart0_read_until_string                  @ wait for 'ready'
    LDR r1, =esp32_config_mux_cmd
    BL uart0_write
    LDR r1, =esp32_ok_str                       @ config mux and wait for 'OK'
    BL uart0_read_until_string
    LDR r1, =esp32_config_TCP_server_cmd
    BL uart0_write                              @ config tcp server and wait for 'ok'
    LDR r1, =esp32_ok_str
    BL uart0_read_until_string
    LDR r1, =esp32_connect_str                  @ wait for tcp connection established from client
    BL uart0_read_until_string
    LDR r1, =esp32_server_configured_str
    BL uart0_write                              @ print 'Server is Configured' to console

    POP {lr, r1}
    BX lr

esp32_config_client:
    PUSH {lr, r1}
    
    LDR r1, =esp32_ready_str                
    BL uart0_read_until_string                  @ wait for 'ready'
    LDR r1, =esp32_got_ip_str
    BL uart0_read_until_string                  @ wait for 'GOT IP'
    LDR r1, =esp32_start_TCP_cmd
    BL uart0_write                              @ start tcp connection with server
                                                @ *** may need to read response here***
    LDR r1, =esp32_client_configured_str
    BL uart1_write                              @ print 'Client is Configured' to console

    POP {lr, r1}
    BX lr


esp32_send_packet:
    PUSH {lr}

    LDR r1, =esp32_send_packet_str      
    BL uart0_write
    LDR r1, =esp32_prompt_str
    BL uart0_read_until_string          @ Send command to initiate sending 3 bytes of data (2 bytes + null)
    BL uart0_write
    LDR r1, =esp32_ok_str
    BL uart0_read_until_string          @ Write data and wait for 'OK'

    POP {lr}
    BX lr

esp32_recieve_packet:
    PUSH {lr, r1, r2}

    BL uart0_wifi_read
    LDR r2, [r0]
    CMP r2, #'+'
    BNE end_read_hword
    LDR r2, [r0, #9]
    STR r2, [r1]
    LDR r2, [r0, #10]
    STR r2, [r1, #1]
    LDR r2, [r0, #11]
    STR r2, [r0, #2]

    end_read_hword:
        POP {lr, r1, r2}
        BX lr


@ inifinite blocking function, only for debugging/console access to esp32
esp32_debug:
    BL uart0_to_uart1
    BL uart1_to_uart0
    B esp32_debug

@ Long delay, but not infinite, while passing uart0 to uart1
esp32_read_response:                            
    PUSH {lr, r1-r3}
    LDR r2, =100000000
    MOV r3, #0
    
    esp32_boot_loop:
        BL uart0_to_uart1
        ADD r3, r3, #1
        CMP r3, r2
        BNE esp32_boot_loop

    POP {lr, r1-r3}
    BX lr

@ esp32_config_mux:                           @ Marked for delete
@     PUSH {lr, r1}
@     LDR r1, =esp32_config_mux_cmd
@     BL uart0_write
@     BL esp32_wait_for_ok
@     POP {lr, r1} 
@     BX lr

@ esp32_config_TCP_server:                    @ Marked for delete
@     PUSH {lr, r1}
@     LDR r1, =esp32_config_TCP_server_cmd
@     BL uart0_write
@     BL esp32_wait_for_ok
@     POP {lr, r1} 
@     BX lr

@ esp32_start_TCP:                            @ Marked for delete
@     PUSH {lr, r1}
@     LDR r1, =esp32_start_TCP_cmd
@     BL uart0_write
@     POP {lr, r1} 
@     BX lr


@ esp32_wait_for_ready:               @ Marked for delete
@     PUSH {lr, r1}
@     LDR r1, =esp32_ready_str
@     BL uart0_read_until_string
@     POP {lr, r1}
@     BX lr

@ esp32_wait_for_ip:                  @ Marked for delete
@     PUSH {lr, r1}
@     LDR r1, =esp32_got_ip_str
@     BL uart0_read_until_string
@     POP {lr, r1}
@     BX lr

@ esp32_wait_for_ok:                  @ Marked for delete
@     PUSH {lr, r1}
@     LDR r1, =esp32_ok_str
@     BL uart0_read_until_string
@     POP {lr, r1}
@     BX lr

@ esp32_wait_for_prompt:              @ Marked for delete
@     PUSH {lr, r1}
@     LDR r1, =esp32_prompt_str
@     BL uart0_read_until_string
@     POP {lr, r1}
@     BX lr

@ esp32_wait_for_connect:             @ Marked for delete
@     PUSH {lr, r1}
@     LDR r1, =esp32_connect_str
@     BL uart0_read_until_string
@     POP {lr, r1}
@     BX lr

@ esp32_server_send_cmd:              @ Marked for delete
@     PUSH {lr, r1}
@     LDR r1, =esp32_server_send_str
@     BL uart0_write
@     POP {lr, r1}
@     BX lr




.endif @ ESP32_S