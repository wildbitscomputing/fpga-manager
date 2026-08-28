; k2uploader - stream a gzip FPGA image into an RP2040 flash slot.
;
; This is a one-block K2 KUP executable for the DOS external-program
; loader.  The shell passes argv through kernel.args.ext/extlen.  The program
; scans the file once to determine its compressed size and CRC-32, then opens
; it again and sends IMAGE_BEGIN, IMAGE_DATA, and IMAGE_END commands through
; the RP2040 supervisor mailbox.

            .cpu "65816"

            .weak
PGZ_BUILD   = 0                     ; 0 = KUP, 1 = PGZ (-D PGZ_BUILD=1)
            .endweak

; ---------------------------------------------------------------------------
; MicroKernel vectors and argument block
; ---------------------------------------------------------------------------

KERNEL_NEXT_EVENT       = $ff00
KERNEL_READ_DATA        = $ff04
KERNEL_YIELD            = $ff0c
KERNEL_PUTCH            = $ff10
KERNEL_FILE_OPEN        = $ff5c
KERNEL_FILE_READ        = $ff60
KERNEL_FILE_CLOSE       = $ff68

KARGS_EVENT_DEST        = $f0
KARGS_EVENT_PENDING     = $f2
KARGS_FILE_STREAM       = $f3
KARGS_FILE_DRIVE        = $f3
KARGS_FILE_COOKIE       = $f4
KARGS_FILE_READ_LEN     = $f4
KARGS_FILE_MODE         = $f5
KARGS_EXT               = $f8
KARGS_EXTLEN            = $fa
KARGS_BUF               = $fb
KARGS_BUFLEN            = $fd

FILE_MODE_READ          = 0

EVENT_FILE_NOT_FOUND    = $28
EVENT_FILE_OPENED       = $2a
EVENT_FILE_DATA         = $2c
EVENT_FILE_EOF          = $30
EVENT_FILE_CLOSED       = $32
EVENT_FILE_ERROR        = $38

EVENT_TYPE              = event_buffer+0
EVENT_FILE_STREAM       = event_buffer+3
EVENT_FILE_READ_COUNT   = event_buffer+6

; ---------------------------------------------------------------------------
; RP2040 mailbox registers and protocol
; ---------------------------------------------------------------------------

MMU_IO_CTRL             = $0001

MAILBOX_CONTROL         = $dde0
MAILBOX_STATUS          = $dde1
MAILBOX_COMMAND_REG     = $dde2
MAILBOX_REMOTE_STATUS   = $dde3
MAILBOX_TX_COUNT_LO      = $dde4
MAILBOX_TX_COUNT_HI      = $dde5
MAILBOX_RX_COUNT_LO      = $dde6
MAILBOX_RX_COUNT_HI      = $dde7
MAILBOX_TX_DATA         = $dde8
MAILBOX_RX_DATA         = $dde9
MAILBOX_LAST_ERROR      = $ddee
MAILBOX_VERSION         = $ddef

MAILBOX_CONTROL_ENABLE  = $01
MAILBOX_CONTROL_CLEAR   = $02
MAILBOX_CONTROL_RESET   = $80

MAILBOX_STATUS_ONLINE   = $01
MAILBOX_STATUS_BUSY     = $08
MAILBOX_STATUS_TX_EMPTY = $20

COMMAND_IMAGE_BEGIN     = $02
COMMAND_IMAGE_DATA      = $03
COMMAND_IMAGE_END       = $04
COMMAND_IMAGE_ABORT     = $05
COMMAND_IMAGE_STATUS    = $07
COMMAND_PING            = $01

TARGET_FLASH_GZIP       = $02
MAX_PAYLOAD             = 240
FLASH_SLOT_SIZE_2       = $20       ; 2 MiB = $00:20:00:00

; Expected gzip ISIZE: the uncompressed FPGA bitstream size, 9,730,652
; bytes ($00947A5C).
FPGA_SIZE_0             = $5c
FPGA_SIZE_1             = $7a
FPGA_SIZE_2             = $94
FPGA_SIZE_3             = $00

PHASE_SCAN              = 0
PHASE_UPLOAD            = 1

; Application direct-page scratch is saved and restored before returning to
; DOS.  The kernel permanently owns $f0-$ff.
ZP_POINTER              = $20
ZP_ARGUMENT             = $22
ZP_TIMEOUT0             = $24
ZP_TIMEOUT1             = $25
ZP_TIMEOUT2             = $26
ZP_TIMEOUT3             = $27

; ---------------------------------------------------------------------------
; K2 one-block executable header
; ---------------------------------------------------------------------------

*           = $8000
            .if PGZ_BUILD == 0
            .byte   $f2,$56             ; KUP signature
            .byte   1                   ; one 8 KiB block
            .byte   4                   ; mount in slot 4 at $8000
            .word   RUN
            .byte   1                   ; header version
            .fill   3,0
            .text   "k2uploader",0
            .text   "<slot 1-4> <file.gz>",0
            .text   "Program an RP2040 FPGA flash slot",0
            .endif

RUN:
            sep     #$30
            .as
            .xs
            cld

            ldx     #15
save_zp:    lda     $20,x
            sta     saved_zp,x
            dex
            bpl     save_zp

            lda     MMU_IO_CTRL
            sta     saved_io_page
            stz     MMU_IO_CTRL

            ; Preserve pexec's argument descriptor before making any kernel
            ; calls, then print it so loader/version differences are visible
            ; on the real machine.
            lda     KARGS_EXT
            sta     startup_args_ext
            lda     KARGS_EXT+1
            sta     startup_args_ext+1
            lda     KARGS_EXTLEN
            sta     startup_args_extlen

            lda     #<event_buffer
            sta     KARGS_EVENT_DEST
            lda     #>event_buffer
            sta     KARGS_EVENT_DEST+1

            .if PGZ_BUILD == 1
            jsr     use_test_defaults
            .else
            jsr     debug_arguments
            jsr     parse_arguments
            bcc     arguments_ok
            lda     #<usage_text
            ldx     #>usage_text
            jsr     puts
            jmp     exit_program
            .endif

arguments_ok:
            lda     #<banner_text
            ldx     #>banner_text
            jsr     puts
            lda     slot
            clc
            adc     #'1'
            jsr     putchar
            lda     #<newline_text
            ldx     #>newline_text
            jsr     puts

            ; Reset the hardware FIFOs, clear stale errors, and enable polling.
            lda     #(MAILBOX_CONTROL_ENABLE | MAILBOX_CONTROL_CLEAR | MAILBOX_CONTROL_RESET)
            sta     MAILBOX_CONTROL
            lda     #MAILBOX_CONTROL_ENABLE
            sta     MAILBOX_CONTROL
            jsr     mailbox_wait_online
            bcc     mailbox_online
            lda     #<offline_text
            ldx     #>offline_text
            jsr     puts
            jmp     exit_program

mailbox_online:
            lda     MAILBOX_VERSION
            cmp     #1
            beq     mailbox_version_ok
            lda     #<version_text
            ldx     #>version_text
            jsr     puts
            lda     MAILBOX_VERSION
            jsr     print_hex_byte
            jsr     print_newline
            jmp     exit_program

mailbox_version_ok:
            jsr     make_crc_table
            lda     #$ff
            sta     crc_value+0
            sta     crc_value+1
            sta     crc_value+2
            sta     crc_value+3
            stz     file_size+0
            stz     file_size+1
            stz     file_size+2
            stz     file_size+3
            stz     uploaded_size+0
            stz     uploaded_size+1
            stz     uploaded_size+2
            stz     uploaded_size+3
            stz     header_count
            stz     phase
            stz     stream
            stz     upload_started
            stz     upload_complete
            stz     failed
            stz     progress_count
            ldx     #7
clear_tail: stz     file_tail,x
            dex
            bpl     clear_tail

            lda     #<scan_text
            ldx     #>scan_text
            jsr     puts
            jsr     open_file
            bcc     event_loop
            lda     #<open_text
            ldx     #>open_text
            jsr     puts
            jmp     exit_program

; ---------------------------------------------------------------------------
; Asynchronous MicroKernel file state machine
; ---------------------------------------------------------------------------

event_loop:
            jsr     KERNEL_NEXT_EVENT
            bcc     have_event
            jsr     KERNEL_YIELD
            bra     event_loop

have_event:
            lda     EVENT_TYPE
            cmp     #EVENT_FILE_OPENED
            beq     event_opened
            cmp     #EVENT_FILE_DATA
            bne     +
            jmp     event_data
+
            cmp     #EVENT_FILE_EOF
            bne     +
            jmp     event_eof
+
            cmp     #EVENT_FILE_CLOSED
            bne     +
            jmp     event_closed
+
            cmp     #EVENT_FILE_NOT_FOUND
            bne     +
            jmp     event_file_failure
+
            cmp     #EVENT_FILE_ERROR
            bne     +
            jmp     event_file_failure
+           jmp     event_loop

event_opened:
            lda     EVENT_FILE_STREAM
            sta     stream
            lda     phase
            beq     opened_for_scan

            lda     #<erase_text
            ldx     #>erase_text
            jsr     puts
            ; Make repeated host-side test launches self-recovering if a prior
            ; run was interrupted after IMAGE_BEGIN.
            lda     #COMMAND_IMAGE_ABORT
            ldx     #0
            jsr     mailbox_command
            bcc     +
            jmp     mailbox_failure
+
            jsr     build_begin_payload
            stz     retry_count
begin_upload_retry:
            lda     #<begin_payload
            sta     ZP_POINTER
            lda     #>begin_payload
            sta     ZP_POINTER+1
            ; A timeout is ambiguous: BEGIN may already have erased the slot
            ; and entered upload state.  Mark it active before dispatch so the
            ; failure path always attempts IMAGE_ABORT.
            lda     #1
            sta     upload_started
            lda     #COMMAND_IMAGE_BEGIN
            ldx     begin_length
            jsr     mailbox_command
            bcc     begin_upload_query
            lda     mailbox_error
            cmp     #$10                ; a prior retry may already be active
            beq     begin_upload_query
            jmp     mailbox_failure
begin_upload_query:
            lda     #COMMAND_IMAGE_STATUS
            ldx     #0
            jsr     mailbox_command
            bcs     begin_upload_not_confirmed
            jsr     mailbox_read_upload_size
            bcs     begin_upload_not_confirmed
            lda     MAILBOX_REMOTE_STATUS
            and     #$02                ; upload active
            beq     begin_upload_not_confirmed
            jsr     remote_matches_uploaded
            bcc     begin_upload_confirmed
begin_upload_not_confirmed:
            inc     retry_count
            lda     retry_count
            cmp     #8
            bcc     begin_upload_retry
            lda     #$fc
            sta     mailbox_error
            jmp     mailbox_failure
begin_upload_confirmed:
            jsr     request_read
            bcs     +
            jmp     event_loop
+           jmp     event_file_failure

opened_for_scan:
            jsr     request_read
            bcs     +
            jmp     event_loop
+           jmp     event_file_failure

event_data:
            lda     EVENT_FILE_STREAM
            cmp     stream
            beq     +
            jmp     event_loop
+
            lda     EVENT_FILE_READ_COUNT
            sta     chunk_length
            sta     KARGS_BUFLEN
            lda     #<io_buffer
            sta     KARGS_BUF
            lda     #>io_buffer
            sta     KARGS_BUF+1
            jsr     KERNEL_READ_DATA
            bcc     +
            jmp     event_file_failure
+

            lda     phase
            bne     upload_data
            jsr     scan_chunk
            bra     request_next_chunk

upload_data:
            stz     retry_count
upload_data_retry:
            ; The mailbox uses an 8-bit pipelined response sequence. A
            ; zero-payload transaction before each payload command prevents
            ; a wrapped stale response from acknowledging an unsent DATA
            ; frame. The cumulative byte count below remains authoritative.
            lda     #COMMAND_PING
            ldx     #0
            jsr     mailbox_command
            bcc     +
            jmp     mailbox_failure
+
            lda     #<io_buffer
            sta     ZP_POINTER
            lda     #>io_buffer
            sta     ZP_POINTER+1
            lda     #COMMAND_IMAGE_DATA
            ldx     chunk_length
            jsr     mailbox_command
            bcc     +
            jmp     mailbox_failure
+
            jsr     build_expected_upload_size
            jsr     mailbox_read_upload_size
            bcc     +
            jmp     mailbox_failure
+
            jsr     remote_matches_expected
            bcc     upload_data_accepted
            jsr     remote_matches_uploaded
            bcs     mailbox_sync_failure
            inc     retry_count
            lda     retry_count
            cmp     #8
            bcc     upload_data_retry
            bra     mailbox_sync_failure

upload_data_accepted:
            ldx     #3
copy_accepted_size:
            lda     expected_upload_size,x
            sta     uploaded_size,x
            dex
            bpl     copy_accepted_size
            inc     progress_count
            lda     progress_count
            and     #$3f
            bne     request_next_chunk
            lda     #'.'
            jsr     putchar

            bra     request_next_chunk

mailbox_sync_failure:
            lda     #$fc
            sta     mailbox_error
            jmp     mailbox_failure

request_next_chunk:
            jsr     request_read
            bcs     +
            jmp     event_loop
+           jmp     event_file_failure

event_eof:
            lda     EVENT_FILE_STREAM
            cmp     stream
            beq     +
            jmp     event_loop
+
            lda     phase
            beq     close_current_file

            stz     retry_count
end_upload_retry:
            lda     #COMMAND_IMAGE_END
            ldx     #0
            jsr     mailbox_command
            bcc     end_upload_query
            lda     mailbox_error
            cmp     #$18                ; a prior END may have committed it
            bne     end_upload_failed
end_upload_query:
            lda     #COMMAND_IMAGE_STATUS
            ldx     #0
            jsr     mailbox_command
            bcs     end_upload_not_confirmed
            jsr     mailbox_read_upload_size
            bcs     end_upload_not_confirmed
            lda     MAILBOX_REMOTE_STATUS
            and     #$02                ; upload active must now be clear
            bne     end_upload_not_confirmed
            jsr     remote_matches_uploaded
            bcc     end_upload_confirmed
end_upload_not_confirmed:
            inc     retry_count
            lda     retry_count
            cmp     #8
            bcc     end_upload_retry
end_upload_failed:
            jmp     mailbox_failure

end_upload_confirmed:
            stz     upload_started
            lda     #1
            sta     upload_complete

close_current_file:
            jsr     close_file
            bcs     +
            jmp     event_loop
+           jmp     event_file_failure

event_closed:
            lda     EVENT_FILE_STREAM
            cmp     stream
            beq     +
            jmp     event_loop
+
            stz     stream
            lda     failed
            beq     close_success_path
            jmp     exit_program

close_success_path:
            lda     phase
            bne     upload_closed
            jsr     finish_scan
            bcc     scan_valid
            jmp     exit_program

scan_valid:
            lda     #PHASE_UPLOAD
            sta     phase
            jsr     open_file
            bcs     +
            jmp     event_loop
+
            lda     #<open_text
            ldx     #>open_text
            jsr     puts
            jmp     exit_program

upload_closed:
            lda     upload_complete
            bne     +
            jmp     exit_program
+
            jsr     print_newline
            lda     #<success_text
            ldx     #>success_text
            jsr     puts
            lda     slot
            clc
            adc     #'1'
            jsr     putchar
            jsr     print_newline
            jmp     exit_program

event_file_failure:
            lda     #1
            sta     failed
            lda     #<file_error_text
            ldx     #>file_error_text
            jsr     puts
            jsr     abort_if_needed
            lda     stream
            bne     +
            jmp     exit_program
+
            jsr     close_file
            bcs     +
            jmp     event_loop
+           jmp     exit_program

mailbox_failure:
            lda     #1
            sta     failed
            lda     #<mailbox_error_text
            ldx     #>mailbox_error_text
            jsr     puts
            lda     mailbox_error
            jsr     print_hex_byte
            jsr     print_newline
            lda     #<mailbox_diag_command_text
            ldx     #>mailbox_diag_command_text
            jsr     puts
            lda     pending_command
            jsr     print_hex_byte
            lda     #<mailbox_diag_sent_text
            ldx     #>mailbox_diag_sent_text
            jsr     puts
            lda     uploaded_size+3
            jsr     print_hex_byte
            lda     uploaded_size+2
            jsr     print_hex_byte
            lda     uploaded_size+1
            jsr     print_hex_byte
            lda     uploaded_size+0
            jsr     print_hex_byte
            lda     #<mailbox_diag_chunk_text
            ldx     #>mailbox_diag_chunk_text
            jsr     puts
            lda     pending_length
            jsr     print_hex_byte
            jsr     print_newline
            lda     #<mailbox_diag_remote_text
            ldx     #>mailbox_diag_remote_text
            jsr     puts
            lda     MAILBOX_REMOTE_STATUS
            jsr     print_hex_byte
            lda     #<mailbox_diag_remote_size_text
            ldx     #>mailbox_diag_remote_size_text
            jsr     puts
            lda     remote_upload_size+3
            jsr     print_hex_byte
            lda     remote_upload_size+2
            jsr     print_hex_byte
            lda     remote_upload_size+1
            jsr     print_hex_byte
            lda     remote_upload_size+0
            jsr     print_hex_byte
            jsr     print_newline
            jsr     abort_if_needed
            lda     stream
            beq     exit_program
            jsr     close_file
            bcs     exit_program
            jmp     event_loop

exit_program:
            .if PGZ_BUILD == 1
            lda     #<pgz_exit_text
            ldx     #>pgz_exit_text
            jsr     puts
            .endif
            lda     saved_io_page
            sta     MMU_IO_CTRL
            ldx     #15
restore_zp: lda     saved_zp,x
            sta     $20,x
            dex
            bpl     restore_zp
            .if PGZ_BUILD == 1
pgz_exit_loop:
            jsr     KERNEL_YIELD          ; pexec chain-jumps; there is no RTS caller
            bra     pgz_exit_loop
            .else
            clc                         ; return to DOS; do not reboot
            rts
            .endif

open_file:
            lda     drive
            sta     KARGS_FILE_DRIVE
            stz     KARGS_FILE_COOKIE
            stz     KARGS_FILE_MODE
            lda     #<filename
            sta     KARGS_BUF
            lda     #>filename
            sta     KARGS_BUF+1
            lda     filename_length
            sta     KARGS_BUFLEN
            jsr     KERNEL_FILE_OPEN
            rts

request_read:
            lda     stream
            sta     KARGS_FILE_STREAM
            lda     #MAX_PAYLOAD
            sta     KARGS_FILE_READ_LEN
            jsr     KERNEL_FILE_READ
            rts

close_file:
            lda     stream
            sta     KARGS_FILE_STREAM
            jsr     KERNEL_FILE_CLOSE
            rts

abort_if_needed:
            lda     upload_started
            beq     abort_done
            stz     upload_started
            lda     #COMMAND_IMAGE_ABORT
            ldx     #0
            jsr     mailbox_command
abort_done: rts

; ---------------------------------------------------------------------------
; Argument parsing
; ---------------------------------------------------------------------------

; Host-launched PGZ test builds have no command-line argument vector. Keep the
; SD card in the K2 and always use the current hardware-test candidate.
use_test_defaults:
            lda     #3                  ; user-facing slot 4
            sta     slot
            stz     drive
            ldy     #0
copy_test_filename:
            lda     test_filename,y
            sta     filename,y
            beq     test_filename_copied
            iny
            bra     copy_test_filename
test_filename_copied:
            sty     filename_length
            rts

parse_arguments:
            lda     startup_args_extlen
            cmp     #4                  ; at least slot and image pathname
            bcs     +
            jmp     parse_failed
+
            lda     startup_args_ext
            sta     ZP_POINTER
            lda     startup_args_ext+1
            sta     ZP_POINTER+1
            ora     ZP_POINTER
            beq     parse_failed

            ; Current pexec passes [program, slot, pathname], while some
            ; installed versions pass only [slot, pathname].  Recognize the
            ; slot token rather than depending on one specific convention.
            ldy     #0
            jsr     parse_slot_argument
            bcc     slot_is_argv0
            lda     startup_args_extlen
            cmp     #6
            bcc     parse_failed
            ldy     #2
            jsr     parse_slot_argument
            bcs     parse_failed
            ldy     #4                  ; argv[2] = image pathname
            bra     load_filename_pointer

slot_is_argv0:
            ldy     #2                  ; argv[1] = image pathname
load_filename_pointer:
            lda     (ZP_POINTER),y
            sta     ZP_ARGUMENT
            iny
            lda     (ZP_POINTER),y
            sta     ZP_ARGUMENT+1
            ora     ZP_ARGUMENT
            beq     parse_failed
            ldy     #0
copy_filename:
            lda     (ZP_ARGUMENT),y
            sta     filename,y
            beq     filename_copied
            iny
            cpy     #127
            bne     copy_filename
            bra     parse_failed

filename_copied:
            sty     filename_length
            tya
            beq     parse_failed
            stz     drive
            cpy     #2
            bcc     parse_ok
            lda     filename+1
            cmp     #':'
            bne     parse_ok
            lda     filename
            cmp     #'0'
            bcc     parse_failed
            cmp     #'8'
            bcs     parse_failed
            and     #7
            sta     drive
            ldy     #0
strip_drive:
            lda     filename+2,y
            sta     filename,y
            beq     drive_stripped
            iny
            cpy     #125
            bne     strip_drive
drive_stripped:
            sty     filename_length
            tya
            beq     parse_failed
parse_ok:   clc
            rts
parse_failed:
            sec
            rts

; Parse the argv pointer at byte offset Y as a single-character slot number.
; Returns carry clear and stores the zero-based slot on success.
parse_slot_argument:
            lda     (ZP_POINTER),y
            sta     ZP_ARGUMENT
            iny
            lda     (ZP_POINTER),y
            sta     ZP_ARGUMENT+1
            ora     ZP_ARGUMENT
            beq     slot_argument_failed
            ldy     #0
            lda     (ZP_ARGUMENT),y
            cmp     #'1'
            bcc     slot_argument_failed
            cmp     #'5'
            bcs     slot_argument_failed
            sec
            sbc     #'1'
            sta     slot
            iny
            lda     (ZP_ARGUMENT),y
            bne     slot_argument_failed
            clc
            rts
slot_argument_failed:
            sec
            rts

; ---------------------------------------------------------------------------
; Argument diagnostics
; ---------------------------------------------------------------------------

debug_arguments:
            lda     #<args_ext_text
            ldx     #>args_ext_text
            jsr     puts
            lda     startup_args_ext+1
            jsr     print_hex_byte
            lda     startup_args_ext
            jsr     print_hex_byte
            lda     #<args_len_text
            ldx     #>args_len_text
            jsr     puts
            lda     startup_args_extlen
            jsr     print_hex_byte
            jsr     print_newline

            stz     debug_arg_offset
debug_argument_loop:
            lda     debug_arg_offset
            cmp     startup_args_extlen
            bcc     +
            jmp     debug_arguments_done
+
            cmp     #8                  ; cap diagnostic output at four args
            bcc     +
            jmp     debug_arguments_done
+

            lda     #<args_argv_text
            ldx     #>args_argv_text
            jsr     puts
            lda     debug_arg_offset
            lsr     a
            jsr     print_hex_byte
            lda     #<args_pointer_text
            ldx     #>args_pointer_text
            jsr     puts

            lda     startup_args_ext
            sta     ZP_POINTER
            lda     startup_args_ext+1
            sta     ZP_POINTER+1
            ora     ZP_POINTER
            beq     debug_bad_vector
            ldy     debug_arg_offset
            lda     (ZP_POINTER),y
            sta     ZP_ARGUMENT
            iny
            lda     (ZP_POINTER),y
            sta     ZP_ARGUMENT+1

            lda     ZP_ARGUMENT+1
            jsr     print_hex_byte
            lda     ZP_ARGUMENT
            jsr     print_hex_byte
            lda     ZP_ARGUMENT+1
            ora     ZP_ARGUMENT
            beq     debug_null_argument

            lda     #<args_value_text
            ldx     #>args_value_text
            jsr     puts
            ldy     #0
debug_argument_chars:
            cpy     #64
            beq     debug_argument_truncated
            lda     (ZP_ARGUMENT),y
            beq     debug_argument_end
            cmp     #$20
            bcc     debug_argument_nonprintable
            cmp     #$7f
            bcs     debug_argument_nonprintable
            jsr     putchar
            iny
            bra     debug_argument_chars
debug_argument_nonprintable:
            lda     #'.'
            jsr     putchar
            iny
            bra     debug_argument_chars
debug_argument_truncated:
            lda     #'.'
            jsr     putchar
            jsr     putchar
            jsr     putchar
debug_argument_end:
            lda     #'"'
            jsr     putchar
            jsr     print_newline
            bra     debug_next_argument

debug_null_argument:
            lda     #<args_null_text
            ldx     #>args_null_text
            jsr     puts
            bra     debug_next_argument
debug_bad_vector:
            lda     #<args_bad_vector_text
            ldx     #>args_bad_vector_text
            jsr     puts
            rts

debug_next_argument:
            inc     debug_arg_offset
            inc     debug_arg_offset
            jmp     debug_argument_loop
debug_arguments_done:
            rts

; ---------------------------------------------------------------------------
; File scan, CRC-32, and gzip validation
; ---------------------------------------------------------------------------

scan_chunk:
            jsr     update_tail
            ldy     #0
scan_byte_loop:
            cpy     chunk_length
            beq     scan_bytes_done
            lda     io_buffer,y
            jsr     update_crc
            lda     header_count
            cmp     #10
            bcs     header_done
            tax
            lda     io_buffer,y
            sta     image_header,x
            inc     header_count
header_done:
            iny
            bra     scan_byte_loop

scan_bytes_done:
            clc
            lda     file_size+0
            adc     chunk_length
            sta     file_size+0
            lda     file_size+1
            adc     #0
            sta     file_size+1
            lda     file_size+2
            adc     #0
            sta     file_size+2
            lda     file_size+3
            adc     #0
            sta     file_size+3
            rts

update_tail:
            lda     chunk_length
            cmp     #8
            bcc     short_tail
            sec
            sbc     #8
            tay
            ldx     #0
copy_tail:  lda     io_buffer,y
            sta     file_tail,x
            iny
            inx
            cpx     #8
            bne     copy_tail
            rts

short_tail:
            ldy     #0
short_tail_byte:
            cpy     chunk_length
            beq     tail_done
            ldx     #0
shift_tail: lda     file_tail+1,x
            sta     file_tail,x
            inx
            cpx     #7
            bne     shift_tail
            lda     io_buffer,y
            sta     file_tail+7
            iny
            bra     short_tail_byte
tail_done:  rts

finish_scan:
            lda     crc_value+0
            eor     #$ff
            sta     crc_value+0
            lda     crc_value+1
            eor     #$ff
            sta     crc_value+1
            lda     crc_value+2
            eor     #$ff
            sta     crc_value+2
            lda     crc_value+3
            eor     #$ff
            sta     crc_value+3

            lda     #<scan_result_text
            ldx     #>scan_result_text
            jsr     puts
            lda     file_size+3
            jsr     print_hex_byte
            lda     file_size+2
            jsr     print_hex_byte
            lda     file_size+1
            jsr     print_hex_byte
            lda     file_size+0
            jsr     print_hex_byte
            lda     #<crc_text
            ldx     #>crc_text
            jsr     puts
            lda     crc_value+3
            jsr     print_hex_byte
            lda     crc_value+2
            jsr     print_hex_byte
            lda     crc_value+1
            jsr     print_hex_byte
            lda     crc_value+0
            jsr     print_hex_byte
            jsr     print_newline

            lda     header_count
            cmp     #10
            bne     bad_gzip
            lda     image_header+0
            cmp     #$1f
            bne     bad_gzip
            lda     image_header+1
            cmp     #$8b
            bne     bad_gzip
            lda     image_header+2
            cmp     #8
            bne     bad_gzip
            lda     image_header+3
            and     #$e0                ; reserved gzip flags must be clear
            bne     bad_gzip

            ; Reject zero/oversize files.  Exactly 2 MiB is allowed.
            lda     file_size+0
            ora     file_size+1
            ora     file_size+2
            ora     file_size+3
            beq     bad_size
            lda     file_size+3
            bne     bad_size
            lda     file_size+2
            cmp     #FLASH_SLOT_SIZE_2
            bcc     size_ok
            bne     bad_size
            lda     file_size+1
            ora     file_size+0
            bne     bad_size
size_ok:
            ; A gzip member is at least ten header plus eight trailer bytes.
            lda     file_size+3
            ora     file_size+2
            ora     file_size+1
            bne     gzip_size_ok
            lda     file_size+0
            cmp     #18
            bcc     bad_size
gzip_size_ok:
            lda     file_tail+4         ; trailer ISIZE, little endian
            cmp     #FPGA_SIZE_0
            bne     bad_gzip
            lda     file_tail+5
            cmp     #FPGA_SIZE_1
            bne     bad_gzip
            lda     file_tail+6
            cmp     #FPGA_SIZE_2
            bne     bad_gzip
            lda     file_tail+7
            cmp     #FPGA_SIZE_3
            bne     bad_gzip
            clc
            rts

bad_gzip:   lda     #<gzip_text
            ldx     #>gzip_text
            jsr     puts
            sec
            rts
bad_size:   lda     #<size_text
            ldx     #>size_text
            jsr     puts
            sec
            rts

make_crc_table:
            ldx     #0
crc_byte_loop:
            lda     #0
            sta     crc_value+2
            sta     crc_value+1
            stx     crc_value+0
            ldy     #8
crc_bit_loop:
            lsr     a
            ror     crc_value+2
            ror     crc_value+1
            ror     crc_value+0
            bcc     crc_no_poly
            eor     #$ed
            pha
            lda     crc_value+2
            eor     #$b8
            sta     crc_value+2
            lda     crc_value+1
            eor     #$83
            sta     crc_value+1
            lda     crc_value+0
            eor     #$20
            sta     crc_value+0
            pla
crc_no_poly:
            dey
            bne     crc_bit_loop
            sta     crc_table3,x
            lda     crc_value+2
            sta     crc_table2,x
            lda     crc_value+1
            sta     crc_table1,x
            lda     crc_value+0
            sta     crc_table0,x
            inx
            bne     crc_byte_loop
            rts

; A = next byte
update_crc:
            eor     crc_value+0
            tax
            lda     crc_value+1
            eor     crc_table0,x
            sta     crc_value+0
            lda     crc_value+2
            eor     crc_table1,x
            sta     crc_value+1
            lda     crc_value+3
            eor     crc_table2,x
            sta     crc_value+2
            lda     crc_table3,x
            sta     crc_value+3
            rts

; ---------------------------------------------------------------------------
; Mailbox commands
; ---------------------------------------------------------------------------

build_begin_payload:
            lda     #TARGET_FLASH_GZIP
            sta     begin_payload+0
            lda     slot
            sta     begin_payload+1
            ldx     #0
copy_begin_size:
            lda     file_size,x
            sta     begin_payload+2,x
            lda     crc_value,x
            sta     begin_payload+6,x
            inx
            cpx     #4
            bne     copy_begin_size
            lda     filename_length
            sta     begin_payload+10
            clc
            adc     #11
            sta     begin_length
            ldy     #0
copy_begin_label:
            cpy     filename_length
            beq     begin_payload_done
            lda     filename,y
            sta     begin_payload+11,y
            iny
            bra     copy_begin_label
begin_payload_done:
            rts

; A = command, X = payload length, ZP_POINTER = payload address.
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
mailbox_ok: jsr     mailbox_intercommand_delay
            clc
            rts
mailbox_timeout:
            lda     #$ff
            sta     mailbox_error
            sec
            rts

; COMMAND_BUSY clears as soon as the FPGA receives the RP2040 response. The
; RP2040 still needs a short interval to process the accompanying POLL request
; and rearm its SPI PIO/DMA before another command frame may start.
mailbox_intercommand_delay:
            ldy     #8
mailbox_delay_outer:
            ldx     #$ff
mailbox_delay_inner:
            dex
            bne     mailbox_delay_inner
            dey
            bne     mailbox_delay_outer
            rts

build_expected_upload_size:
            clc
            lda     uploaded_size+0
            adc     chunk_length
            sta     expected_upload_size+0
            lda     uploaded_size+1
            adc     #0
            sta     expected_upload_size+1
            lda     uploaded_size+2
            adc     #0
            sta     expected_upload_size+2
            lda     uploaded_size+3
            adc     #0
            sta     expected_upload_size+3
            rts

remote_matches_expected:
            ldx     #3
remote_expected_loop:
            lda     remote_upload_size,x
            cmp     expected_upload_size,x
            bne     remote_size_mismatch
            dex
            bpl     remote_expected_loop
            clc
            rts

remote_matches_uploaded:
            ldx     #3
remote_uploaded_loop:
            lda     remote_upload_size,x
            cmp     uploaded_size,x
            bne     remote_size_mismatch
            dex
            bpl     remote_uploaded_loop
            clc
            rts
remote_size_mismatch:
            sec
            rts

; Read the newest cumulative upload-size response. Multiple responses can be
; queued when a stale transport acknowledgement was observed, so discard all
; complete older 4-byte values and retain the last one.
mailbox_read_upload_size:
            ldy     #$ff
mailbox_rx_wait_outer:
            ldx     #$ff
mailbox_rx_wait_inner:
            lda     MAILBOX_RX_COUNT_HI
            bne     mailbox_rx_ready
            lda     MAILBOX_RX_COUNT_LO
            cmp     #4
            bcs     mailbox_rx_ready
            dex
            bne     mailbox_rx_wait_inner
            dey
            bne     mailbox_rx_wait_outer
            lda     #$fb
            sta     mailbox_error
            sec
            rts

mailbox_rx_ready:
            ; Allow the FPGA's four-cycle RX copy state to finish.
            ldx     #$ff
mailbox_rx_settle:
            dex
            bne     mailbox_rx_settle
            lda     MAILBOX_RX_COUNT_HI
            bne     mailbox_rx_bad_count
            lda     MAILBOX_RX_COUNT_LO
            cmp     #4
            bcc     mailbox_rx_bad_count
            sec
            sbc     #4
            tay
mailbox_rx_discard:
            cpy     #0
            beq     mailbox_rx_read_value
            lda     MAILBOX_RX_DATA
            dey
            bra     mailbox_rx_discard
mailbox_rx_read_value:
            ldx     #0
mailbox_rx_read_loop:
            lda     MAILBOX_RX_DATA
            sta     remote_upload_size,x
            inx
            cpx     #4
            bne     mailbox_rx_read_loop
            clc
            rts
mailbox_rx_bad_count:
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
            bne     online_ok
            dex
            bne     online_inner
            dey
            bne     online_outer
            sec
            rts
online_ok:  clc
            rts

mailbox_wait_busy:
            ldy     #$ff
busy_outer:
            ldx     #$ff
busy_inner:
            lda     MAILBOX_STATUS
            and     #MAILBOX_STATUS_BUSY
            bne     busy_seen
            dex
            bne     busy_inner
            dey
            bne     busy_outer
            sec
            rts
busy_seen:  clc
            rts

; Approximately 80 seconds at a 6 MHz CPU in the worst case.  IMAGE_BEGIN
; may spend several seconds erasing the complete 2 MiB slot.
mailbox_wait_idle:
            stz     ZP_TIMEOUT0
            stz     ZP_TIMEOUT1
            stz     ZP_TIMEOUT2
            lda     #2
            sta     ZP_TIMEOUT3
idle_loop:  lda     MAILBOX_STATUS
            and     #MAILBOX_STATUS_BUSY
            beq     idle_ok
            inc     ZP_TIMEOUT0
            bne     idle_loop
            inc     ZP_TIMEOUT1
            bne     idle_loop
            inc     ZP_TIMEOUT2
            bne     idle_loop
            dec     ZP_TIMEOUT3
            bne     idle_loop
            sec
            rts
idle_ok:    clc
            rts

; ---------------------------------------------------------------------------
; Console helpers
; ---------------------------------------------------------------------------

putchar:    jsr     KERNEL_PUTCH
            rts

; AX points to a zero-terminated string.
puts:       sta     ZP_POINTER
            stx     ZP_POINTER+1
            ldy     #0
puts_loop:  lda     (ZP_POINTER),y
            beq     puts_done
            jsr     putchar
            iny
            bne     puts_loop
            inc     ZP_POINTER+1
            bra     puts_loop
puts_done:  rts

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
args_ext_text:      .text "Args ext=$",0
args_len_text:      .text " extlen=$",0
args_argv_text:     .text " argv[$",0
args_pointer_text:  .text "]=$",0
args_value_text:    .byte $20,$22,0
args_null_text:     .text " <null>",$0a,0
args_bad_vector_text: .text " <invalid vector>",$0a,0
test_filename:       .text "fe.gz",0
usage_text:         .text "Usage: k2uploader <slot 1-4> <file.gz>",$0a,0
banner_text:        .text "RP2040 FPGA flash uploader - slot ",0
newline_text:       .text $0a,0
offline_text:       .text "RP2040 supervisor is offline.",$0a,0
version_text:       .text "Unsupported supervisor version $",0
scan_text:          .text "Scanning image and calculating CRC...",$0a,0
scan_result_text:   .text "Compressed bytes: $",0
crc_text:           .text "  CRC32: $",0
open_text:          .text "Could not open image.",$0a,0
file_error_text:    .text "File I/O failed; upload aborted.",$0a,0
gzip_text:          .text "Not a valid gzip FPGA image.",$0a,0
size_text:          .text "Image does not fit in a 2 MiB slot.",$0a,0
erase_text:         .text "Erasing slot and uploading (do not power off)...",$0a,0
mailbox_error_text: .text "Supervisor command failed, error $",0
mailbox_diag_command_text: .text "Command $",0
mailbox_diag_sent_text: .text " local bytes $",0
mailbox_diag_chunk_text: .text " chunk $",0
mailbox_diag_remote_text: .text "Remote status $",0
mailbox_diag_remote_size_text: .text " bytes $",0
success_text:       .text "Upload verified by size/CRC. Flash slot ",0
            .if PGZ_BUILD == 1
pgz_exit_text:      .text "Reset the K2 to return to DOS.",$0a,0
            .endif

            .cerror * > $8fff, "k2uploader code exceeds the first 4 KiB"

; ---------------------------------------------------------------------------
; Fixed in-block workspace.  CRC tables are generated at startup.
; ---------------------------------------------------------------------------

*           = $9000
crc_table0:         .fill 256,0
crc_table1:         .fill 256,0
crc_table2:         .fill 256,0
crc_table3:         .fill 256,0

*           = $9400
io_buffer:          .fill MAX_PAYLOAD,0

*           = $9500
filename:           .fill 128,0
saved_zp:           .fill 16,0
event_buffer:       .fill 16,0
begin_payload:      .fill 139,0
file_size:          .fill 4,0
uploaded_size:      .fill 4,0
expected_upload_size: .fill 4,0
remote_upload_size: .fill 4,0
crc_value:          .fill 4,0
image_header:       .fill 10,0
file_tail:          .fill 8,0
saved_io_page:      .byte 0
filename_length:    .byte 0
drive:              .byte 0
slot:               .byte 0
phase:              .byte 0
stream:             .byte 0
chunk_length:       .byte 0
header_count:       .byte 0
upload_started:     .byte 0
upload_complete:    .byte 0
failed:             .byte 0
progress_count:     .byte 0
pending_command:    .byte 0
pending_length:     .byte 0
begin_length:       .byte 0
mailbox_error:      .byte 0
retry_count:        .byte 0
startup_args_ext:   .word 0
startup_args_extlen: .byte 0
debug_arg_offset:   .byte 0

*           = $9fff
            .byte 0
