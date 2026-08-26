; K2 Core Manager - inspect and select RP2040 FPGA boot images.
;
; PGZ application for the F256K2.  It queries the manager-side SD catalog,
; replaceable flash slot, embedded golden image, persistent selection, and
; currently running source through the supervisor mailbox.

            .cpu "65816"

            .weak
CORE_MGR_AUTOTEST = 0
CORE_MGR_AUTOTEST_INDEX = 30
CORE_MGR_AUTOTEST_RECONFIGURE = 0
            .endweak

KERNEL_NEXT_EVENT       = $ff00
KERNEL_YIELD            = $ff0c
KERNEL_PUTCH            = $ff10

KARGS_EVENT_DEST        = $f0

EVENT_KEY_PRESSED       = $08
EVENT_TYPE              = event_buffer+0
EVENT_KEY_ASCII         = event_buffer+5

MMU_IO_CTRL             = $0001

MAILBOX_CONTROL         = $dde0
MAILBOX_STATUS          = $dde1
MAILBOX_COMMAND_REG     = $dde2
MAILBOX_REMOTE_STATUS   = $dde3
MAILBOX_TX_COUNT_LO      = $dde4
MAILBOX_TX_COUNT_HI      = $dde5
MAILBOX_RX_COUNT_LO      = $dde6
MAILBOX_RX_COUNT_HI      = $dde7
MAILBOX_TX_DATA          = $dde8
MAILBOX_RX_DATA          = $dde9
MAILBOX_LAST_ERROR      = $ddee
MAILBOX_VERSION         = $ddef

MAILBOX_CONTROL_ENABLE  = $01
MAILBOX_CONTROL_CLEAR   = $02
MAILBOX_CONTROL_RESET   = $80
MAILBOX_STATUS_ONLINE   = $01
MAILBOX_STATUS_BUSY     = $08

COMMAND_PING            = $01
COMMAND_CATALOG_BEGIN   = $08
COMMAND_CATALOG_GET     = $09
COMMAND_GET_SELECTION   = $0a
COMMAND_SET_SELECTION   = $0b
COMMAND_RECONFIGURE     = $0c
COMMAND_GET_BOOT_STATUS = $0e

SOURCE_AUTO             = 0
SOURCE_SD               = 1
SOURCE_FLASH            = 2
SOURCE_GOLDEN           = 3

FLAG_SELECTED           = $01
FLAG_RUNNING            = $02

ZP_POINTER              = $20
ZP_TIMEOUT0             = $22
ZP_TIMEOUT1             = $23
ZP_TIMEOUT2             = $24
ZP_TIMEOUT3             = $25

*           = $8000

RUN:
            sep     #$30
            .as
            .xs
            cld

            ldx     #7
save_zp:    lda     $20,x
            sta     saved_zp,x
            dex
            bpl     save_zp
            lda     MMU_IO_CTRL
            sta     saved_io_page
            stz     MMU_IO_CTRL
            lda     #<event_buffer
            sta     KARGS_EVENT_DEST
            lda     #>event_buffer
            sta     KARGS_EVENT_DEST+1

            lda     #$01
            sta     nonce+0
            lda     #'M'
            sta     nonce+1
            lda     #'2'
            sta     nonce+2
            lda     #'K'
            sta     nonce+3
            lda     #3                  ; context 4 until boot status says otherwise
            sta     context

            .if CORE_MGR_AUTOTEST == 0
            lda     #<banner_text
            ldx     #>banner_text
            jsr     puts
            .endif
            lda     #(MAILBOX_CONTROL_ENABLE | MAILBOX_CONTROL_CLEAR | MAILBOX_CONTROL_RESET)
            sta     MAILBOX_CONTROL
            lda     #MAILBOX_CONTROL_ENABLE
            sta     MAILBOX_CONTROL
            jsr     mailbox_wait_online
            bcc     supervisor_online
            jmp     supervisor_offline
supervisor_online:
            lda     MAILBOX_VERSION
            cmp     #1
            beq     supervisor_version_ok
            jmp     supervisor_version
supervisor_version_ok:

            .if CORE_MGR_AUTOTEST != 0
            ; Headless manufacturing/development check: catalog context 4 and
            ; persist its reserved flash entry (index 30). The host verifies
            ; autotest_result through the debug port, then reboots the RP2040
            ; and checks the UART log for a FLASH boot.
            jsr     catalog_begin
            bcs     autotest_failed
            lda     #CORE_MGR_AUTOTEST_INDEX
            sta     selected_index
            jsr     select_catalog_entry
            bcs     autotest_failed
            .if CORE_MGR_AUTOTEST_RECONFIGURE != 0
            jsr     prepare_nonce
            lda     context
            sta     tx_buffer+4
            lda     #COMMAND_RECONFIGURE
            ldx     #5
            jsr     mailbox_command_response
            bcs     autotest_failed
            .endif
            lda     #$a5
            sta     autotest_result
            bra     autotest_wait
autotest_failed:
            lda     mailbox_error
            ora     #$e0
            sta     autotest_result
autotest_wait:
            jsr     KERNEL_YIELD
            bra     autotest_wait
supervisor_offline:
            lda     #$ee
            sta     autotest_result
            bra     autotest_wait
supervisor_version:
            lda     #$ed
            sta     autotest_result
            bra     autotest_wait
            .else

            jsr     get_boot_status
            bcs     refresh
            lda     response_buffer+4
            beq     refresh
            lda     response_buffer+5
            cmp     #4
            bcs     refresh
            sta     context

refresh:
            jsr     print_screen
menu_loop:
            jsr     wait_key
            cmp     #'c'
            beq     next_context
            cmp     #'r'
            beq     refresh
            cmp     #'n'
            beq     next_page
            cmp     #'p'
            beq     previous_page
            cmp     #'b'
            beq     boot_selected
            cmp     #'q'
            bne     menu_decode_selection
            jmp     exit_program
menu_decode_selection:
            jsr     decode_catalog_index
            bcs     menu_loop
            cmp     catalog_count
            bcs     menu_loop
            sta     selected_index
            jsr     select_catalog_entry
            bcs     command_failure
            lda     #<selection_saved_text
            ldx     #>selection_saved_text
            jsr     puts
            bra     refresh

next_context:
            inc     context
            lda     context
            and     #3
            sta     context
            stz     page_start
            bra     refresh

next_page:
            lda     page_start
            clc
            adc     #12
            cmp     catalog_count
            bcs     menu_loop
            sta     page_start
            bra     refresh

previous_page:
            lda     page_start
            sec
            sbc     #12
            bcs     +
            lda     #0
+           sta     page_start
            bra     refresh

boot_selected:
            jsr     prepare_nonce
            lda     context
            sta     tx_buffer+4
            lda     #COMMAND_RECONFIGURE
            ldx     #5
            jsr     mailbox_command_response
            bcs     command_failure
            lda     #<reconfigure_text
            ldx     #>reconfigure_text
            jsr     puts
boot_wait:  jsr     KERNEL_YIELD
            bra     boot_wait

supervisor_offline:
            lda     #<offline_text
            ldx     #>offline_text
            jsr     puts
            bra     exit_program
supervisor_version:
            lda     #<version_text
            ldx     #>version_text
            jsr     puts
            lda     MAILBOX_VERSION
            jsr     print_hex_byte
            jsr     print_newline
            bra     exit_program
command_failure:
            lda     #<error_text
            ldx     #>error_text
            jsr     puts
            lda     mailbox_error
            jsr     print_hex_byte
            jsr     print_newline
            jmp     menu_loop

exit_program:
            lda     #<exit_text
            ldx     #>exit_text
            jsr     puts
            lda     saved_io_page
            sta     MMU_IO_CTRL
            ldx     #7
restore_zp: lda     saved_zp,x
            sta     $20,x
            dex
            bpl     restore_zp
exit_wait:  jsr     KERNEL_YIELD
            bra     exit_wait
            .endif

; ---------------------------------------------------------------------------
; Catalog and persistent-selection commands
; ---------------------------------------------------------------------------

print_screen:
            lda     #<separator_text
            ldx     #>separator_text
            jsr     puts
            lda     #<context_text
            ldx     #>context_text
            jsr     puts
            lda     context
            clc
            adc     #'1'
            jsr     putchar
            jsr     print_newline

            jsr     get_boot_status
            bcs     print_catalog
            lda     #<running_text
            ldx     #>running_text
            jsr     puts
            lda     response_buffer+4
            beq     no_running_image
            lda     response_buffer+5
            clc
            adc     #'1'
            jsr     putchar
            lda     #' '
            jsr     putchar
            lda     response_buffer+6
            jsr     print_source
            lda     #' '
            jsr     putchar
            ldy     #0
print_running_name:
            cpy     response_buffer+7
            beq     running_done
            lda     response_buffer+8,y
            jsr     putchar
            iny
            bra     print_running_name
no_running_image:
            lda     #'-'
            jsr     putchar
running_done:
            jsr     print_newline

print_catalog:
            jsr     catalog_begin
            bcc     catalog_begin_ok
            jmp     print_catalog_failed
catalog_begin_ok:
            lda     #<catalog_header_text
            ldx     #>catalog_header_text
            jsr     puts
            lda     page_start
            cmp     catalog_count
            bcc     +
            stz     page_start
+           lda     page_start
            sta     catalog_index
            clc
            adc     #12
            bcc     +
            lda     #32
+           sta     page_end
catalog_print_loop:
            lda     catalog_index
            cmp     catalog_count
            bcs     catalog_print_done
            cmp     page_end
            bcs     catalog_print_done
            jsr     catalog_get
            bcs     print_catalog_failed
            lda     catalog_index
            jsr     print_index_char
            lda     #' '
            jsr     putchar
            lda     response_buffer+13
            and     #FLAG_SELECTED
            beq     catalog_selected_no
            lda     #'*'
            bra     catalog_selected_print
catalog_selected_no:
            lda     #' '
catalog_selected_print:
            jsr     putchar
            lda     response_buffer+13
            and     #FLAG_RUNNING
            beq     catalog_running_no
            lda     #'>'
            bra     catalog_running_print
catalog_running_no:
            lda     #' '
catalog_running_print:
            jsr     putchar
            lda     #' '
            jsr     putchar
            lda     response_buffer+10
            jsr     print_source
            lda     #' '
            jsr     putchar
            lda     response_buffer+17
            jsr     print_hex_byte
            lda     response_buffer+16
            jsr     print_hex_byte
            lda     response_buffer+15
            jsr     print_hex_byte
            lda     response_buffer+14
            jsr     print_hex_byte
            lda     #' '
            jsr     putchar
            ldy     #0
catalog_name_loop:
            cpy     response_buffer+18
            beq     catalog_name_done
            lda     response_buffer+19,y
            jsr     putchar
            iny
            bra     catalog_name_loop
catalog_name_done:
            jsr     print_newline
            inc     catalog_index
            jmp     catalog_print_loop
catalog_print_done:
            lda     #<menu_text
            ldx     #>menu_text
            jsr     puts
            clc
            rts
print_catalog_failed:
            lda     #<catalog_error_text
            ldx     #>catalog_error_text
            jsr     puts
            lda     mailbox_error
            jsr     print_hex_byte
            jsr     print_newline
            sec
            rts

catalog_begin:
            jsr     prepare_nonce
            lda     context
            sta     tx_buffer+4
            lda     #COMMAND_CATALOG_BEGIN
            ldx     #5
            jsr     mailbox_command_response
            bcs     catalog_begin_done
            lda     response_length
            cmp     #11
            bcs     catalog_begin_length_ok
            jmp     response_short
catalog_begin_length_ok:
            ldx     #3
copy_generation:
            lda     response_buffer+4,x
            sta     catalog_generation,x
            dex
            bpl     copy_generation
            lda     response_buffer+8
            cmp     #33
            bcc     +
            lda     #32
+           sta     catalog_count
            clc
catalog_begin_done:
            rts

catalog_get:
            jsr     prepare_nonce
            ldx     #0
copy_get_generation:
            lda     catalog_generation,x
            sta     tx_buffer+4,x
            inx
            cpx     #4
            bne     copy_get_generation
            lda     catalog_index
            sta     tx_buffer+8
            stz     tx_buffer+9
            lda     #COMMAND_CATALOG_GET
            ldx     #10
            jsr     mailbox_command_response
            bcs     catalog_get_done
            lda     response_length
            cmp     #19
            bcc     response_short
            clc
catalog_get_done:
            rts

get_boot_status:
            jsr     prepare_nonce
            lda     #COMMAND_GET_BOOT_STATUS
            ldx     #4
            jsr     mailbox_command_response
            bcs     get_status_done
            lda     response_length
            cmp     #8
            bcc     response_short
            clc
get_status_done:
            rts

select_catalog_entry:
            lda     selected_index
            sta     catalog_index
            jsr     catalog_get
            bcs     selection_done
            lda     response_buffer+10
            sta     selected_source
            jsr     prepare_nonce
            lda     context
            sta     tx_buffer+4
            lda     selected_source
            sta     tx_buffer+5
            stz     tx_buffer+6
            cmp     #SOURCE_SD
            bne     selection_payload_ready
            lda     response_buffer+18
            sta     tx_buffer+6
            tay
            beq     selection_payload_ready
            dey
copy_selection_path:
            lda     response_buffer+19,y
            sta     tx_buffer+7,y
            dey
            bpl     copy_selection_path
selection_payload_ready:
            lda     tx_buffer+6
            clc
            adc     #7
            tax
            lda     #COMMAND_SET_SELECTION
            jsr     mailbox_command_response
selection_done:
            rts

response_short:
            lda     #$f8
            sta     mailbox_error
            sec
            rts

; ---------------------------------------------------------------------------
; Generic nonce-protected mailbox request/response
; ---------------------------------------------------------------------------

prepare_nonce:
            ldx     #0
copy_nonce:
            lda     nonce,x
            sta     tx_buffer,x
            inx
            cpx     #4
            bne     copy_nonce
            inc     nonce+0
            bne     nonce_done
            inc     nonce+1
            bne     nonce_done
            inc     nonce+2
            bne     nonce_done
            inc     nonce+3
nonce_done: rts

; A=command, X=payload length. tx_buffer begins with the request nonce.
mailbox_command_response:
            sta     response_command
            stx     response_request_length
            jsr     drain_rx_fifo
            lda     #<tx_buffer
            sta     ZP_POINTER
            lda     #>tx_buffer
            sta     ZP_POINTER+1
            ; The current FPGA bridge pipelines RP2040 replies. A PING before
            ; each payload-bearing request prevents an old 8-bit transport
            ; sequence from consuming the request's reply.
            lda     #COMMAND_PING
            ldx     #0
            jsr     mailbox_command
            bcs     command_response_done
            jsr     drain_rx_fifo
            lda     response_command
            ldx     response_request_length
            jsr     mailbox_command
            bcs     command_response_done
            jsr     mailbox_read_response
            bcs     command_response_done
            lda     response_length
            cmp     #4
            bcc     response_short
            ldx     #3
validate_nonce:
            lda     response_buffer,x
            cmp     tx_buffer,x
            bne     nonce_mismatch
            dex
            bpl     validate_nonce
            clc
command_response_done:
            rts
nonce_mismatch:
            lda     #$f9
            sta     mailbox_error
            sec
            rts

; A=command, X=length, payload at ZP_POINTER.
mailbox_command:
            sta     pending_command
            stx     pending_length
            jsr     mailbox_wait_idle
            bcs     mailbox_timeout
            lda     MAILBOX_TX_COUNT_LO
            ora     MAILBOX_TX_COUNT_HI
            beq     mailbox_tx_ready
            lda     #$fe
            sta     mailbox_error
            sec
            rts
mailbox_tx_ready:
            ldy     #0
mailbox_copy_payload:
            cpy     pending_length
            beq     mailbox_start
            lda     (ZP_POINTER),y
            sta     MAILBOX_TX_DATA
            iny
            bra     mailbox_copy_payload
mailbox_start:
            lda     pending_command
            sta     MAILBOX_COMMAND_REG
            jsr     mailbox_wait_busy
            bcs     mailbox_timeout
            jsr     mailbox_wait_idle
            bcs     mailbox_timeout
            lda     MAILBOX_LAST_ERROR
            sta     mailbox_error
            beq     mailbox_ok
            sec
            rts
mailbox_ok:
            jsr     mailbox_delay
            clc
            rts
mailbox_timeout:
            lda     #$ff
            sta     mailbox_error
            sec
            rts

mailbox_delay:
            ldy     #8
mailbox_delay_outer:
            ldx     #$ff
mailbox_delay_inner:
            dex
            bne     mailbox_delay_inner
            dey
            bne     mailbox_delay_outer
            rts

drain_rx_fifo:
            lda     MAILBOX_RX_COUNT_HI
            bne     drain_rx_byte
            lda     MAILBOX_RX_COUNT_LO
            beq     drain_done
drain_rx_byte:
            lda     MAILBOX_RX_DATA
            bra     drain_rx_fifo
drain_done: rts

mailbox_read_response:
            stz     ZP_TIMEOUT0
            stz     ZP_TIMEOUT1
            stz     ZP_TIMEOUT2
            lda     #2
            sta     ZP_TIMEOUT3
response_wait:
            lda     MAILBOX_RX_COUNT_HI
            bne     response_bad_count
            lda     MAILBOX_RX_COUNT_LO
            bne     response_ready
            inc     ZP_TIMEOUT0
            bne     response_wait
            inc     ZP_TIMEOUT1
            bne     response_wait
            inc     ZP_TIMEOUT2
            bne     response_wait
            dec     ZP_TIMEOUT3
            bne     response_wait
            lda     #$fb
            sta     mailbox_error
            sec
            rts
response_ready:
            sta     response_length
            ldx     #$ff
-           dex
            bne     -
            lda     MAILBOX_RX_COUNT_HI
            bne     response_bad_count
            lda     MAILBOX_RX_COUNT_LO
            cmp     response_length
            bne     response_bad_count
            ldy     #0
response_copy:
            lda     MAILBOX_RX_DATA
            sta     response_buffer,y
            iny
            cpy     response_length
            bne     response_copy
            clc
            rts
response_bad_count:
            lda     #$fa
            sta     mailbox_error
            sec
            rts

mailbox_wait_online:
            ldy     #$ff
online_outer:
            ldx     #$ff
online_inner:
            lda     MAILBOX_STATUS
            and     #MAILBOX_STATUS_ONLINE
            bne     +
            dex
            bne     online_inner
            dey
            bne     online_outer
            sec
            rts
+           clc
            rts

mailbox_wait_busy:
            ldy     #$ff
busy_outer:
            ldx     #$ff
busy_inner:
            lda     MAILBOX_STATUS
            and     #MAILBOX_STATUS_BUSY
            bne     +
            dex
            bne     busy_inner
            dey
            bne     busy_outer
            sec
            rts
+           clc
            rts

mailbox_wait_idle:
            stz     ZP_TIMEOUT0
            stz     ZP_TIMEOUT1
            stz     ZP_TIMEOUT2
            lda     #2
            sta     ZP_TIMEOUT3
-           lda     MAILBOX_STATUS
            and     #MAILBOX_STATUS_BUSY
            beq     +
            inc     ZP_TIMEOUT0
            bne     -
            inc     ZP_TIMEOUT1
            bne     -
            inc     ZP_TIMEOUT2
            bne     -
            dec     ZP_TIMEOUT3
            bne     -
            sec
            rts
+           clc
            rts

; ---------------------------------------------------------------------------
; Console and keyboard helpers
; ---------------------------------------------------------------------------

wait_key:
            jsr     KERNEL_NEXT_EVENT
            bcc     +
            jsr     KERNEL_YIELD
            bra     wait_key
+           lda     EVENT_TYPE
            cmp     #EVENT_KEY_PRESSED
            bne     wait_key
            lda     EVENT_KEY_ASCII
            rts

; A ASCII -> A catalog index, carry clear; command/lowercase -> carry set.
decode_catalog_index:
            cmp     #'0'
            bcc     decode_failed
            cmp     #'9'+1
            bcs     decode_letter
            sec
            sbc     #'0'
            clc
            rts
decode_letter:
            cmp     #'A'
            bcc     decode_failed
            cmp     #'V'+1
            bcs     decode_failed
            sec
            sbc     #'A'-10
            clc
            rts
decode_failed:
            sec
            rts

print_index_char:
            cmp     #10
            bcc     +
            sec
            sbc     #10
            clc
            adc     #'A'
            jmp     putchar
+           clc
            adc     #'0'
            jmp     putchar

print_source:
            cmp     #SOURCE_AUTO
            bne     +
            lda     #'A'
            bra     print_source_done
+           cmp     #SOURCE_SD
            bne     +
            lda     #'S'
            bra     print_source_done
+           cmp     #SOURCE_FLASH
            bne     +
            lda     #'F'
            bra     print_source_done
+           lda     #'G'
print_source_done:
            jmp     putchar

putchar:    jsr     KERNEL_PUTCH
            rts

puts:       sta     ZP_POINTER
            stx     ZP_POINTER+1
            ldy     #0
-           lda     (ZP_POINTER),y
            beq     +
            jsr     putchar
            iny
            bne     -
            inc     ZP_POINTER+1
            bra     -
+           rts

print_newline:
            lda     #$0a
            jmp     putchar

print_hex_byte:
            pha
            lsr     a
            lsr     a
            lsr     a
            lsr     a
            tax
            lda     hex_digits,x
            jsr     putchar
            pla
            and     #$0f
            tax
            lda     hex_digits,x
            jmp     putchar

hex_digits:         .text "0123456789ABCDEF"
banner_text:        .text $0a,"K2 Core Manager",$0a,0
separator_text:     .text $0a,"----------------------------------------",$0a,0
context_text:       .text "Catalog context: ",0
running_text:       .text "Running: context ",0
catalog_header_text:.text "Key ** Source Size(hex) Image",$0a,0
menu_text:          .text "Key=select, n/p=page, c=context, r=refresh, b=boot, q=quit",$0a,0
selection_saved_text: .text "Selection saved persistently.",$0a,0
reconfigure_text:   .text "Reconfiguring from the selected source...",$0a,0
offline_text:       .text "RP2040 supervisor is offline.",$0a,0
version_text:       .text "Unsupported supervisor version $",0
error_text:         .text "Supervisor command failed, error $",0
catalog_error_text: .text "Could not read catalog, error $",0
exit_text:          .text "Reset the K2 to return to DOS.",$0a,0

; ---------------------------------------------------------------------------
; Workspace
; ---------------------------------------------------------------------------

            .align $100
tx_buffer:          .fill 240,0
            .align $100
response_buffer:    .fill 240,0
event_buffer:       .fill 16,0
saved_zp:           .fill 8,0
catalog_generation: .fill 4,0
nonce:              .fill 4,0
saved_io_page:      .byte 0
context:            .byte 0
catalog_count:      .byte 0
catalog_index:      .byte 0
page_start:         .byte 0
page_end:           .byte 0
selected_index:     .byte 0
selected_source:    .byte 0
response_length:    .byte 0
pending_command:    .byte 0
pending_length:     .byte 0
response_command:   .byte 0
response_request_length: .byte 0
mailbox_error:      .byte 0
autotest_result:    .byte 0
