; K2 FPGA Manager - inspect and select RP2040 FPGA boot images.
;
; PGZ application for the F256K2.  It queries the manager-side SD catalog,
; replaceable flash slot, embedded golden image, persistent selection, and
; currently running source through the supervisor mailbox.

            .cpu "65816"

            .weak
CORE_MGR_AUTOTEST = 0
CORE_MGR_AUTOTEST_RECONFIGURE = 0
CORE_MGR_AUTOTEST_LOCAL = 0
CORE_MGR_AUTOTEST_COPY = 0
CORE_MGR_AUTOTEST_DIRECT_FLASH = 0
CORE_MGR_AUTOTEST_LOG = 0
CORE_MGR_AUTOTEST_DELETE = 0
CORE_MGR_AUTOTEST_GOLDEN_ONCE = 0
CORE_MGR_AUTOTEST_CONTEXT = 3
CORE_MGR_LOCAL_DRIVE = 0
            .endweak

KERNEL_NEXT_EVENT       = $ff00
KERNEL_READ_DATA        = $ff04
KERNEL_READ_EXT         = $ff08
KERNEL_YIELD            = $ff0c
KERNEL_PUTCH            = $ff10
KERNEL_FILE_OPEN        = $ff5c
KERNEL_FILE_READ        = $ff60
KERNEL_FILE_WRITE       = $ff64
KERNEL_FILE_CLOSE       = $ff68
KERNEL_FILE_RENAME      = $ff6c
KERNEL_FILE_DELETE      = $ff70
KERNEL_DIRECTORY_OPEN   = $ff78
KERNEL_DIRECTORY_READ   = $ff7c
KERNEL_DIRECTORY_CLOSE  = $ff80

KARGS_EVENT_DEST        = $f0
KARGS_FILE_STREAM       = $f3
KARGS_FILE_DRIVE        = $f3
KARGS_FILE_COOKIE       = $f4
KARGS_FILE_READ_LEN     = $f4
KARGS_FILE_MODE         = $f5
KARGS_EXT               = $f8
KARGS_EXTLEN            = $fa
KARGS_DIRECTORY_STREAM  = $f3
KARGS_DIRECTORY_DRIVE   = $f3
KARGS_BUF               = $fb
KARGS_BUFLEN            = $fd

EVENT_KEY_PRESSED       = $08
EVENT_FILE_NOT_FOUND    = $28
EVENT_FILE_OPENED       = $2a
EVENT_FILE_DATA         = $2c
EVENT_FILE_WROTE        = $2e
EVENT_FILE_EOF          = $30
EVENT_FILE_CLOSED       = $32
EVENT_FILE_RENAMED      = $34
EVENT_FILE_DELETED      = $36
EVENT_FILE_ERROR        = $38
EVENT_DIRECTORY_OPENED  = $3c
EVENT_DIRECTORY_VOLUME  = $3e
EVENT_DIRECTORY_FILE    = $40
EVENT_DIRECTORY_FREE    = $42
EVENT_DIRECTORY_EOF     = $44
EVENT_DIRECTORY_CLOSED  = $46
EVENT_DIRECTORY_ERROR   = $48
EVENT_TYPE              = event_buffer+0
EVENT_KEY_RAW           = event_buffer+4
EVENT_KEY_ASCII         = event_buffer+5
EVENT_STREAM            = event_buffer+3
EVENT_DATA_LENGTH       = event_buffer+5
EVENT_FILE_READ_COUNT   = event_buffer+6
EVENT_FILE_WRITE_COUNT  = event_buffer+6
EVENT_DIRECTORY_FLAGS   = event_buffer+6

KEY_F1                  = $81
KEY_F2                  = $82
KEY_F3                  = $83
KEY_F5                  = $85
KEY_F7                  = $87
KEY_F8                  = $88
KEY_DELETE              = $91
KEY_BACKSPACE           = $92
KEY_TAB                 = $93
KEY_ESC                 = $95
KEY_UP                  = $b6
KEY_DOWN                = $b7
KEY_LEFT                = $b8
KEY_RIGHT               = $b9
KEY_ENTER               = 13
ASCII_TAB               = 9

ATTR_HIDDEN             = $02
ATTR_DIRECTORY          = $10

MMU_IO_CTRL             = $0001
VKY_SYS0                = $d6a0
VKY_RESET_KEY0          = $d6a2
VKY_RESET_KEY1          = $d6a3

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
MAILBOX_REMOTE_SD       = $04

COMMAND_PING            = $01
COMMAND_CATALOG_BEGIN   = $08
COMMAND_CATALOG_GET     = $09
COMMAND_GET_SELECTION   = $0a
COMMAND_SET_SELECTION   = $0b
COMMAND_RECONFIGURE     = $0c
COMMAND_GET_BOOT_STATUS = $0e
COMMAND_COPY_TO_FLASH   = $0f
COMMAND_GET_BOOT_LOG    = $10
COMMAND_COPY_BEGIN      = $11
COMMAND_COPY_STEP       = $12
COMMAND_DELETE_SD       = $13
COMMAND_RECONFIGURE_ONCE = $14
COMMAND_RESTART_SUPERVISOR = $15
COMMAND_READ_SD_BEGIN   = $16
COMMAND_READ_SD_DATA    = $17
COMMAND_READ_SD_END     = $18
COMMAND_IMAGE_BEGIN     = $02
COMMAND_IMAGE_DATA      = $03
COMMAND_IMAGE_END       = $04
COMMAND_IMAGE_ABORT     = $05
COMMAND_IMAGE_STATUS    = $07

TARGET_SD_NAMED         = 3
TARGET_FLASH_GZIP       = 2
FORMAT_RAW              = 1
FORMAT_GZIP             = 2
MAX_PAYLOAD             = 240
READ_SD_CHUNK_SIZE      = 232

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

TEXT_BUFFER             = $c000
; Three-color UI shared with the generated logo: green/cream on black.
UI_COLOR_NORMAL         = $30            ; green on black
UI_COLOR_HIGHLIGHT      = $03            ; black on green
UI_COLOR_FRAME          = $60            ; cream on black
UI_COLOR_KEY_BAR        = $06            ; black on cream
UI_BOX_LEFT             = 5
UI_BOX_RIGHT            = 74
UI_LIST_LINE            = 11
UI_MAX_ENTRIES          = 32
HELP_LINE_COUNT         = 14
UI_BOTTOM_LINE          = UI_LIST_LINE+UI_MAX_ENTRIES
UI_PROGRESS_LABEL_LINE = UI_BOTTOM_LINE+4
UI_PROGRESS_BAR_LINE   = UI_BOTTOM_LINE+6
UI_PROGRESS_DETAIL_LINE = UI_BOTTOM_LINE+8
; One cell for each column between the catalog's left and right borders.
UI_PROGRESS_BAR_WIDTH  = UI_BOX_RIGHT-UI_BOX_LEFT-1
UI_KEY_LINE             = 59
LOCAL_PAGE_JUMP         = 10

COPY_STATE_ERASING      = 1
COPY_STATE_WRITING      = 2
COPY_STATE_FINALIZING   = 3
COPY_STATE_DONE         = 4
COPY_STATE_FAILED       = 5

BOX_TL                  = 169
BOX_TR                  = 170
BOX_BL                  = 171
BOX_BR                  = 172
BOX_H                   = 173
BOX_V                   = 174

ENTRY_SIZE              = 64
ENTRY_SOURCE            = 0
ENTRY_FLAGS             = 1
ENTRY_SIZE_BYTES        = 2
ENTRY_NAME_LENGTH       = 6
ENTRY_NAME               = 7
ENTRY_NAME_CAPACITY      = ENTRY_SIZE-ENTRY_NAME

VIEW_CATALOG            = 0
VIEW_LOCAL              = 1
LOCAL_ENTRY_BUFFER      = $2000
LOCAL_ENTRY_SIZE        = 64
LOCAL_ENTRY_FLAGS       = 0
LOCAL_ENTRY_NAME        = 1
LOCAL_ENTRY_NAME_MAX    = 62
LOCAL_MAX_ENTRIES       = 64
LOCAL_FLAG_DIRECTORY    = $01
LOCAL_FLAG_IMAGE        = $02

; Large work areas live below the PGZ image. The export pathname buffers
; intentionally overlay the local-directory cache: exporting is available
; only in catalog view, and the local directory is reread afterward.
EXPORT_PATH             = $2000
EXPORT_DESTINATION      = $20c0
EXPORT_TEMPORARY        = $2140
EXPORT_BASENAME         = $21c0
CRC_TABLE0              = $3000
CRC_TABLE1              = $3100
CRC_TABLE2              = $3200
CRC_TABLE3              = $3300
CATALOG_ENTRIES         = $3400

*           = $8000

RUN:
            sep     #$30
            .as
            .xs
            cld

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
            .if CORE_MGR_AUTOTEST_COPY != 0 || CORE_MGR_AUTOTEST_DIRECT_FLASH != 0
            lda     #1                  ; use otherwise-empty context 2 in copy test
            .elsif CORE_MGR_AUTOTEST_GOLDEN_ONCE != 0
            lda     #CORE_MGR_AUTOTEST_CONTEXT
            .else
            lda     #3                  ; context 4 until boot status says otherwise
            .endif
            sta     context
            stz     view_mode
            lda     #CORE_MGR_LOCAL_DRIVE
            sta     local_drive
            lda     #'/'
            sta     local_path
            stz     local_path+1
            stz     local_loaded

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
            cmp     #$ff
            beq     supervisor_offline
            cmp     #1
            beq     supervisor_version_ok
            jmp     supervisor_version
supervisor_version_ok:

            .if CORE_MGR_AUTOTEST != 0
            .if CORE_MGR_AUTOTEST_GOLDEN_ONCE != 0
            ; Deterministically find the selected context's embedded golden row
            ; and exercise the non-persistent reconfiguration command.
            jsr     catalog_begin
            bcs     autotest_failed
            stz     catalog_index
autotest_find_golden:
            lda     catalog_index
            cmp     catalog_count
            bcs     autotest_failed
            jsr     catalog_get
            bcs     autotest_failed
            lda     response_buffer+10
            cmp     #SOURCE_GOLDEN
            beq     autotest_golden_found
            inc     catalog_index
            bra     autotest_find_golden
autotest_golden_found:
            lda     catalog_index
            sta     selected_index
            jsr     reconfigure_catalog_entry_once
            bcs     autotest_failed
            bra     autotest_wait
            .elsif CORE_MGR_AUTOTEST_LOG != 0
            ; Hardware integration test: render the complete boot-log screen,
            ; exercising every entry through the mailbox and UI path.
            jsr     draw_boot_log_screen
            bcs     autotest_failed
            lda     boot_log_count
            beq     autotest_failed
            .elsif CORE_MGR_AUTOTEST_LOCAL != 0
            ; Hardware integration test: find fe.gz on the 65816-visible SD,
            ; stream it through the mailbox, and verify it appears in the
            ; RP2040 context-4 catalog.
            jsr     read_local_directory
            bcs     autotest_failed
            stz     local_cursor
autotest_find_local:
            lda     local_cursor
            cmp     local_count
            bcs     autotest_failed
            jsr     local_entry_is_test_image
            bcs     autotest_local_found
            inc     local_cursor
            bra     autotest_find_local
autotest_local_found:
            .if CORE_MGR_AUTOTEST_DIRECT_FLASH != 0
            lda     #TARGET_FLASH_GZIP
            .else
            lda     #TARGET_SD_NAMED
            .endif
            sta     transfer_target
            jsr     install_local_entry
            bcs     autotest_failed
            lda     #1
            sta     highlight_pending
            jsr     load_catalog
            bcs     autotest_failed
            lda     cursor_index
            sta     catalog_index
            jsr     catalog_get
            bcs     autotest_failed
            jsr     catalog_matches_local_filename
            bcc     autotest_failed
            .if CORE_MGR_AUTOTEST_DIRECT_FLASH != 0
            lda     response_buffer+10
            cmp     #SOURCE_FLASH
            bne     autotest_failed
            .endif
            .if CORE_MGR_AUTOTEST_COPY != 0
            jsr     copy_catalog_entry_to_flash
            bcs     autotest_failed
            jsr     catalog_begin
            bcs     autotest_failed
            stz     catalog_index
autotest_find_copied_flash:
            lda     catalog_index
            cmp     catalog_count
            bcs     autotest_failed
            jsr     catalog_get
            bcs     autotest_failed
            lda     response_buffer+10
            cmp     #SOURCE_FLASH
            beq     autotest_copy_verified
            inc     catalog_index
            bra     autotest_find_copied_flash
autotest_copy_verified:
            .if CORE_MGR_AUTOTEST_DELETE != 0
            ; Remove the disposable manager-SD copy after proving that the
            ; flash copy exists. The flash slot remains as the copy-test
            ; result, while the RP2040 SD card is returned to its prior state.
            jsr     catalog_begin
            bcs     autotest_failed
            stz     catalog_index
autotest_find_delete_source:
            lda     catalog_index
            cmp     catalog_count
            bcs     autotest_failed
            jsr     catalog_get
            bcs     autotest_failed
            lda     response_buffer+10
            cmp     #SOURCE_SD
            bne     autotest_delete_next
            jsr     catalog_matches_local_filename
            bcs     autotest_delete_found
autotest_delete_next:
            inc     catalog_index
            bra     autotest_find_delete_source
autotest_delete_found:
            lda     catalog_index
            sta     cursor_index
            jsr     prepare_delete_entry
            bcs     autotest_failed
            jsr     request_delete_entry
            bcs     autotest_failed
            jsr     catalog_begin
            bcs     autotest_failed
            stz     catalog_index
autotest_verify_deleted:
            lda     catalog_index
            cmp     catalog_count
            bcs     autotest_delete_verified
            jsr     catalog_get
            bcs     autotest_failed
            lda     response_buffer+10
            cmp     #SOURCE_SD
            bne     autotest_verify_delete_next
            jsr     catalog_matches_local_filename
            bcs     autotest_failed
autotest_verify_delete_next:
            inc     catalog_index
            bra     autotest_verify_deleted
autotest_delete_verified:
            .endif
            .endif
            .else
            ; Headless manufacturing/development check: catalog context 4 and
            ; persist its flash entry. The host verifies
            ; autotest_result through the debug port, then reboots the RP2040
            ; and checks the UART log for a FLASH boot.
            jsr     catalog_begin
            bcs     autotest_failed
            stz     catalog_index
autotest_find_flash:
            lda     catalog_index
            cmp     catalog_count
            bcs     autotest_failed
            jsr     catalog_get
            bcs     autotest_failed
            lda     response_buffer+10
            cmp     #SOURCE_FLASH
            beq     autotest_flash_found
            inc     catalog_index
            bra     autotest_find_flash
autotest_flash_found:
            lda     catalog_index
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
            lda     view_mode
            bne     refresh_local
            jsr     load_catalog
            bcc     +
            jmp     command_failure
+
            jsr     draw_screen
            bra     menu_loop
refresh_local:
            jsr     read_local_directory
            bcs     local_directory_failure
            jsr     draw_local_screen
menu_loop:
            jsr     wait_key
            lda     EVENT_KEY_ASCII
            cmp     #ASCII_TAB
            beq     switch_view
            ; Prefer MicroKernel's cooked function-key value. Some keyboards
            ; report a different raw F-key when Shift selects the cooked key.
            cmp     #KEY_F1
            beq     show_help
            cmp     #KEY_F2
            beq     show_boot_log
            cmp     #KEY_F3
            beq     copy_highlighted_to_flash
            cmp     #KEY_F5
            beq     copy_between_sds
            cmp     #KEY_F7
            beq     save_default_highlighted
            cmp     #KEY_F8
            beq     restart_supervisor
            lda     EVENT_KEY_RAW
            cmp     #KEY_TAB
            beq     switch_view
            cmp     #KEY_UP
            beq     cursor_up
            cmp     #KEY_DOWN
            beq     cursor_down
            cmp     #KEY_LEFT
            beq     previous_context
            cmp     #KEY_RIGHT
            beq     next_context
            cmp     #KEY_F1
            beq     show_help
            cmp     #KEY_F2
            beq     show_boot_log
            cmp     #KEY_F3
            beq     copy_highlighted_to_flash
            cmp     #KEY_F5
            beq     copy_between_sds
            cmp     #KEY_F7
            beq     save_default_highlighted
            cmp     #KEY_F8
            beq     restart_supervisor
            cmp     #KEY_DELETE
            beq     delete_key
            cmp     #KEY_BACKSPACE
            beq     parent_key
            cmp     #KEY_ESC
            bne     +
            jmp     restart_computer
+
            lda     EVENT_KEY_ASCII
            cmp     #$10                ; MicroKernel cooked Up (Ctrl-P)
            beq     cursor_up
            cmp     #$0e                ; MicroKernel cooked Down (Ctrl-N)
            beq     cursor_down
            cmp     #$02                ; MicroKernel cooked Left (Ctrl-B)
            beq     previous_context
            cmp     #$06                ; MicroKernel cooked Right (Ctrl-F)
            beq     next_context
            cmp     #KEY_ENTER
            beq     run_highlighted
            cmp     #27
            bne     +
            jmp     restart_computer
+
            cmp     #'c'
            beq     next_context
            cmp     #'r'
            beq     refresh
            cmp     #'l'
            beq     show_boot_log
            cmp     #'d'
            beq     delete_key
            cmp     #'e'
            beq     copy_between_sds
            cmp     #'b'
            beq     run_highlighted
            cmp     #'s'
            beq     boot_highlighted
            cmp     #'q'
            bne     +
            jmp     restart_computer
+
            bra     menu_loop

cursor_up:
            lda     view_mode
            beq     catalog_cursor_up
            lda     local_cursor
            beq     menu_loop
            dec     local_cursor
            jsr     adjust_local_top
            jsr     draw_local_entries
            bra     menu_loop
catalog_cursor_up:
            lda     cursor_index
            beq     menu_loop
            dec     cursor_index
            jsr     draw_entries
            bra     menu_loop

cursor_down:
            lda     view_mode
            beq     catalog_cursor_down
            lda     local_cursor
            inc     a
            cmp     local_count
            bcs     menu_loop
            sta     local_cursor
            jsr     adjust_local_top
            jsr     draw_local_entries
            bra     menu_loop
catalog_cursor_down:
            lda     cursor_index
            inc     a
            cmp     catalog_count
            bcs     menu_loop
            sta     cursor_index
            jsr     draw_entries
            bra     menu_loop

next_context:
            lda     view_mode
            bne     local_page_down
            inc     context
            lda     context
            and     #3
            sta     context
            jmp     refresh

previous_context:
            lda     view_mode
            bne     local_page_up
            lda     context
            dec     a
            and     #3
            sta     context
            jmp     refresh

local_page_up:
            lda     local_cursor
            sec
            sbc     #LOCAL_PAGE_JUMP
            bcs     +
            lda     #0
+           sta     local_cursor
            jsr     adjust_local_top
            jsr     draw_local_entries
            jmp     menu_loop

local_page_down:
            lda     local_count
            beq     local_page_done
            lda     local_cursor
            clc
            adc     #LOCAL_PAGE_JUMP
            cmp     local_count
            bcc     +
            lda     local_count
            dec     a
+           sta     local_cursor
            jsr     adjust_local_top
            jsr     draw_local_entries
local_page_done:
            jmp     menu_loop

delete_key:
            lda     view_mode
            bne     local_parent
            jmp     delete_highlighted

parent_key:
            lda     view_mode
            bne     local_parent
            jmp     menu_loop

run_highlighted:
            lda     view_mode
            bne     local_enter_highlighted
            lda     catalog_count
            bne     +
            jmp     menu_loop
+
            jsr     require_active_context
            bcc     +
            jmp     menu_loop
+
            lda     cursor_index
            sta     selected_index
            lda     #<running_once_text
            ldx     #>running_once_text
            jsr     draw_status
            jsr     reconfigure_catalog_entry_once
            bcs     command_failure
            bra     boot_wait

boot_highlighted:
            lda     view_mode
            bne     boot_highlighted_done
            lda     catalog_count
            beq     boot_highlighted_done
            jsr     require_active_context
            bcs     boot_highlighted_done
            lda     cursor_index
            sta     selected_index
            jsr     select_catalog_entry
            bcs     command_failure
            lda     #<booting_text
            ldx     #>booting_text
            jsr     draw_status
            jsr     prepare_nonce
            lda     context
            sta     tx_buffer+4
            lda     #COMMAND_RECONFIGURE
            ldx     #5
            jsr     mailbox_command_response
            bcs     command_failure
boot_wait:  jsr     KERNEL_YIELD
            bra     boot_wait
boot_highlighted_done:
            jmp     menu_loop

; Runtime FPGA reconfiguration cannot change the DIP-selected NOR context.
; Browsing and maintaining another context remains allowed; only Run and
; Save+Run are rejected. The RP2040 independently enforces the same rule.
require_active_context:
            lda     running_valid
            beq     require_active_context_ok
            lda     context
            cmp     running_context
            beq     require_active_context_ok
            lda     #<context_mismatch_text
            ldx     #>context_mismatch_text
            jsr     draw_status
            sec
            rts
require_active_context_ok:
            clc
            rts

save_default_highlighted:
            lda     view_mode
            bne     save_default_done
            lda     catalog_count
            beq     save_default_done
            lda     cursor_index
            sta     selected_index
            jsr     select_catalog_entry
            bcs     command_failure
            jsr     load_catalog
            bcs     command_failure
            jsr     draw_screen
            lda     #<default_saved_text
            ldx     #>default_saved_text
            jsr     draw_status
save_default_done:
            jmp     menu_loop

restart_supervisor:
            lda     #<restart_supervisor_text
            ldx     #>restart_supervisor_text
            jsr     draw_status
            jsr     prepare_nonce
            lda     #COMMAND_RESTART_SUPERVISOR
            ldx     #4
            jsr     mailbox_command_response
            bcs     command_failure
            jmp     boot_wait

switch_view:
            lda     view_mode
            eor     #1
            sta     view_mode
            beq     switch_to_catalog
            lda     local_loaded
            bne     switch_draw_local
            jsr     read_local_directory
            bcs     local_directory_failure
switch_draw_local:
            jsr     draw_local_screen
            jmp     menu_loop
switch_to_catalog:
            jsr     draw_screen
            jmp     menu_loop

show_help:
            jsr     draw_help_screen
            jsr     wait_key
            lda     view_mode
            beq     show_help_catalog
            jsr     draw_local_screen
            jmp     menu_loop
show_help_catalog:
            jsr     draw_screen
            jmp     menu_loop

show_boot_log:
            jsr     draw_boot_log_screen
            bcs     show_boot_log_error
            jsr     wait_key
show_boot_log_restore:
            lda     view_mode
            beq     show_boot_log_catalog
            jsr     draw_local_screen
            jmp     menu_loop
show_boot_log_catalog:
            jsr     draw_screen
            jmp     menu_loop
show_boot_log_error:
            lda     view_mode
            beq     show_boot_log_error_catalog
            jsr     draw_local_screen
            bra     show_boot_log_error_done
show_boot_log_error_catalog:
            jsr     draw_screen
show_boot_log_error_done:
            jmp     command_failure

copy_highlighted_to_flash:
            lda     view_mode
            bne     flash_local_highlighted
            jsr     copy_catalog_entry_to_flash
            bcs     command_failure
            jsr     load_catalog
            bcs     command_failure
            jsr     draw_screen
            lda     #<flash_copy_done_text
            ldx     #>flash_copy_done_text
            jsr     draw_status
            jmp     menu_loop

copy_between_sds:
            lda     view_mode
            bne     copy_local_to_manager_sd
            jmp     export_highlighted_to_local

export_highlighted_to_local:
            lda     view_mode
            bne     export_highlighted_done
            jsr     export_catalog_entry_to_local
            bcs     export_highlighted_failed
            stz     local_loaded
            jsr     draw_screen
            lda     #<export_done_text
            ldx     #>export_done_text
            jsr     draw_status
            jmp     menu_loop
export_highlighted_failed:
            jsr     draw_screen
            jmp     command_failure
export_highlighted_done:
            jmp     menu_loop

delete_highlighted:
            lda     view_mode
            bne     menu_loop
            jsr     prepare_delete_entry
            bcc     delete_show_confirmation
            lda     mailbox_error
            cmp     #$e7
            bne     command_failure
            lda     #<delete_unavailable_text
            ldx     #>delete_unavailable_text
            jsr     draw_status
            jmp     menu_loop
delete_show_confirmation:
            jsr     draw_delete_confirmation
            jsr     wait_key
            lda     EVENT_KEY_ASCII
            ora     #$20
            cmp     #'y'
            beq     delete_confirmed
            jsr     draw_screen
            lda     #<delete_cancelled_text
            ldx     #>delete_cancelled_text
            jsr     draw_status
            jmp     menu_loop
delete_confirmed:
            jsr     request_delete_entry
            bcc     delete_refresh
            jsr     draw_screen
            jmp     command_failure
delete_refresh:
            jsr     load_catalog
            bcs     command_failure
            jsr     draw_screen
            lda     #<delete_done_text
            ldx     #>delete_done_text
            jsr     draw_status
            jmp     menu_loop

local_enter_highlighted:
            lda     local_count
            beq     menu_loop
            jsr     local_entry_pointer
            ldy     #LOCAL_ENTRY_FLAGS
            lda     (ZP_POINTER),y
            and     #LOCAL_FLAG_DIRECTORY
            bne     local_enter_directory
            jmp     menu_loop

copy_local_to_manager_sd:
            lda     local_count
            beq     menu_loop
            jsr     local_entry_pointer
            ldy     #LOCAL_ENTRY_FLAGS
            lda     (ZP_POINTER),y
            and     #LOCAL_FLAG_IMAGE
            beq     menu_loop
            lda     manager_sd_available
            beq     manager_sd_unavailable
            lda     #TARGET_SD_NAMED
            sta     transfer_target
            jsr     install_local_entry
            bcs     command_failure
            lda     #1
            sta     highlight_pending
            stz     view_mode
            jsr     load_catalog
            bcs     command_failure
            jsr     draw_screen
            lda     #<install_done_text
            ldx     #>install_done_text
            jsr     draw_status
            jmp     menu_loop
manager_sd_unavailable:
            lda     #<manager_sd_unavailable_text
            ldx     #>manager_sd_unavailable_text
            jsr     draw_status
            jmp     menu_loop

flash_local_highlighted:
            lda     local_count
            beq     menu_loop
            jsr     local_entry_pointer
            ldy     #LOCAL_ENTRY_FLAGS
            lda     (ZP_POINTER),y
            and     #LOCAL_FLAG_IMAGE
            beq     local_flash_unavailable
            jsr     prepare_transfer_filename
            bcs     command_failure
            lda     transfer_format
            cmp     #FORMAT_GZIP
            bne     local_flash_unavailable
            lda     #TARGET_FLASH_GZIP
            sta     transfer_target
            jsr     install_prepared_entry
            bcs     local_flash_failed
            jsr     load_catalog
            bcs     command_failure
            jsr     draw_local_screen
            lda     #<direct_flash_done_text
            ldx     #>direct_flash_done_text
            jsr     draw_status
            jmp     menu_loop
local_flash_failed:
            lda     mailbox_error
            cmp     #$e6
            bne     command_failure
local_flash_unavailable:
            jsr     draw_local_screen
            lda     #<direct_flash_unavailable_text
            ldx     #>direct_flash_unavailable_text
            jsr     draw_status
            jmp     menu_loop
local_enter_directory:
            jsr     local_append_directory
            bcs     menu_loop
            jsr     read_local_directory
            bcs     local_directory_failure
            jsr     draw_local_screen
            jmp     menu_loop

local_parent:
            jsr     local_parent_directory
            bcs     menu_loop
            jsr     read_local_directory
            bcs     local_directory_failure
            jsr     draw_local_screen
            jmp     menu_loop

local_directory_failure:
            ; Directory errors are emitted by MicroKernel for the K2-side SD
            ; card. Keep the local view active so Tab can return to the core
            ; catalog and R can retry after inserting a readable card.
            jsr     draw_local_screen
            lda     #<local_sd_error_text
            ldx     #>local_sd_error_text
            jsr     draw_status
            jmp     menu_loop

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
            lda     mailbox_error
            cmp     #$28
            bne     command_failure_generic
            lda     #<context_mismatch_text
            ldx     #>context_mismatch_text
            jsr     draw_status
            jmp     menu_loop
command_failure_generic:
            lda     #<error_text
            ldx     #>error_text
            jsr     draw_status
            lda     #2
            sta     MMU_IO_CTRL
            lda     #' '
            jsr     ui_putc
            lda     #'$'
            jsr     ui_putc
            lda     mailbox_error
            jsr     ui_print_hex_byte
            stz     MMU_IO_CTRL
            jmp     menu_loop

restart_computer:
            lda     #<restart_computer_text
            ldx     #>restart_computer_text
            jsr     draw_status
            stz     MMU_IO_CTRL
            lda     #$de
            sta     VKY_RESET_KEY0
            lda     #$ad
            sta     VKY_RESET_KEY1
            lda     #$f0
            sta     VKY_SYS0
            stz     VKY_SYS0
restart_computer_wait:
            bra     restart_computer_wait

exit_program:
            lda     #<exit_text
            ldx     #>exit_text
            jsr     draw_status
            jsr     wait_key
            jmp     restart_computer
            .endif

; ---------------------------------------------------------------------------
; Catalog and persistent-selection commands
; ---------------------------------------------------------------------------

load_catalog:
            jsr     catalog_begin
            bcs     load_catalog_done
            stz     cursor_index
            stz     catalog_index
load_catalog_loop:
            lda     catalog_index
            cmp     catalog_count
            bcs     load_catalog_runtime
            jsr     catalog_get
            bcs     load_catalog_done
            jsr     cache_catalog_entry
            lda     highlight_pending
            beq     load_catalog_selected
            jsr     catalog_matches_local_filename
            bcc     load_catalog_next
            lda     catalog_index
            sta     cursor_index
            bra     load_catalog_next
load_catalog_selected:
            lda     response_buffer+13
            and     #FLAG_SELECTED
            beq     +
            lda     catalog_index
            sta     cursor_index
+
load_catalog_next:
            inc     catalog_index
            bra     load_catalog_loop

load_catalog_runtime:
            stz     highlight_pending
            stz     running_valid
            stz     running_name
            jsr     get_boot_status
            bcs     load_catalog_ok
            lda     response_buffer+4
            sta     running_valid
            lda     response_buffer+5
            sta     running_context
            lda     response_buffer+6
            sta     running_source
            lda     response_buffer+7
            cmp     #ENTRY_NAME_CAPACITY
            bcc     +
            lda     #ENTRY_NAME_CAPACITY-1
+           sta     running_name_length
            ldy     #0
load_running_name:
            cpy     running_name_length
            beq     load_running_done
            lda     response_buffer+8,y
            sta     running_name,y
            iny
            bra     load_running_name
load_running_done:
            lda     #0
            sta     running_name,y
load_catalog_ok:
            clc
load_catalog_done:
            rts

catalog_matches_local_filename:
            lda     response_buffer+18
            cmp     install_name_length
            beq     catalog_basename_compare
            lda     install_name_length
            clc
            adc     #6                  ; "CNTXn/"
            cmp     response_buffer+18
            bne     catalog_name_mismatch
            ldy     #0
catalog_sd_name_compare:
            cpy     install_name_length
            beq     catalog_name_match
            lda     response_buffer+25,y
            cmp     install_name,y
            bne     catalog_name_mismatch
            iny
            bra     catalog_sd_name_compare
catalog_basename_compare:
            ldy     #0
catalog_basename_loop:
            cpy     install_name_length
            beq     catalog_name_match
            lda     response_buffer+19,y
            cmp     install_name,y
            bne     catalog_name_mismatch
            iny
            bra     catalog_basename_loop
catalog_name_match:
            sec
            rts
catalog_name_mismatch:
            clc
            rts

cache_catalog_entry:
            jsr     catalog_entry_pointer
            ldy     #ENTRY_SOURCE
            lda     response_buffer+10
            sta     (ZP_POINTER),y
            iny
            lda     response_buffer+13
            sta     (ZP_POINTER),y
            ldx     #0
cache_size:
            txa
            clc
            adc     #ENTRY_SIZE_BYTES
            tay
            lda     response_buffer+14,x
            sta     (ZP_POINTER),y
            inx
            cpx     #4
            bne     cache_size
            lda     response_buffer+18
            cmp     #ENTRY_NAME_CAPACITY
            bcc     +
            lda     #ENTRY_NAME_CAPACITY-1
+           ldy     #ENTRY_NAME_LENGTH
            sta     (ZP_POINTER),y
            ldx     #0
cache_name:
            cpx     #ENTRY_NAME_CAPACITY-1
            bcs     cache_name_done
            cpx     response_buffer+18
            bcs     cache_name_done
            txa
            clc
            adc     #ENTRY_NAME
            tay
            lda     response_buffer+19,x
            sta     (ZP_POINTER),y
            inx
            bra     cache_name
cache_name_done:
            txa
            clc
            adc     #ENTRY_NAME
            tay
            lda     #0
            sta     (ZP_POINTER),y
            rts

catalog_entry_pointer:
            lda     catalog_index
            and     #3
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            sta     ZP_POINTER
            lda     catalog_index
            lsr     a
            lsr     a
            clc
            adc     #>CATALOG_ENTRIES
            sta     ZP_POINTER+1
            rts

; ---------------------------------------------------------------------------
; Local MicroKernel SD directory browser
; ---------------------------------------------------------------------------

read_local_directory:
            stz     local_count
            stz     local_cursor
            stz     local_top
            stz     local_loaded
            stz     local_failed
            lda     local_drive
            sta     KARGS_DIRECTORY_DRIVE
            stz     KARGS_FILE_COOKIE
            lda     #<local_path
            sta     KARGS_BUF
            lda     #>local_path
            sta     KARGS_BUF+1
            jsr     local_path_length
            sta     KARGS_BUFLEN
            jsr     KERNEL_DIRECTORY_OPEN
            bcc     local_directory_events
            lda     #$e1
            sta     mailbox_error
            sec
            rts

local_directory_events:
            lda     #<event_buffer
            sta     KARGS_EVENT_DEST
            lda     #>event_buffer
            sta     KARGS_EVENT_DEST+1
            jsr     KERNEL_NEXT_EVENT
            bcc     local_directory_event
            jsr     KERNEL_YIELD
            bra     local_directory_events
local_directory_event:
            lda     EVENT_TYPE
            cmp     #EVENT_DIRECTORY_OPENED
            beq     local_directory_opened
            cmp     #EVENT_DIRECTORY_VOLUME
            beq     local_directory_volume
            cmp     #EVENT_DIRECTORY_FILE
            beq     local_directory_file
            cmp     #EVENT_DIRECTORY_FREE
            beq     local_directory_free
            cmp     #EVENT_DIRECTORY_EOF
            beq     local_directory_eof
            cmp     #EVENT_DIRECTORY_ERROR
            beq     local_directory_error
            cmp     #EVENT_DIRECTORY_CLOSED
            beq     local_directory_closed
            bra     local_directory_events

local_directory_opened:
            lda     EVENT_STREAM
            sta     local_stream
            jsr     local_directory_read_next
            bra     local_directory_events

local_directory_volume:
            lda     #<local_trash
            sta     KARGS_BUF
            lda     #>local_trash
            sta     KARGS_BUF+1
            lda     EVENT_DATA_LENGTH
            sta     KARGS_BUFLEN
            jsr     KERNEL_READ_DATA
            jsr     local_directory_read_next
            bra     local_directory_events

local_directory_file:
            lda     EVENT_DIRECTORY_FLAGS
            sta     local_event_flags
            lda     EVENT_DATA_LENGTH
            sta     local_name_length
            lda     local_event_flags
            and     #ATTR_HIDDEN
            bne     local_directory_discard
            lda     local_count
            cmp     #LOCAL_MAX_ENTRIES
            bcs     local_directory_discard
            lda     local_name_length
            beq     local_directory_discard
            cmp     #LOCAL_ENTRY_NAME_MAX+1
            bcs     local_directory_discard
            lda     local_count
            jsr     local_entry_pointer_a
            inc     ZP_POINTER
            bne     +
            inc     ZP_POINTER+1
+           lda     ZP_POINTER
            sta     KARGS_BUF
            lda     ZP_POINTER+1
            sta     KARGS_BUF+1
            lda     local_name_length
            sta     KARGS_BUFLEN
            jsr     KERNEL_READ_DATA
            ldy     local_name_length
            lda     #0
            sta     (ZP_POINTER),y
            ldy     #0
            lda     (ZP_POINTER),y
            cmp     #'.'
            beq     local_directory_discard_ext
            jsr     local_read_directory_ext
            lda     local_count
            jsr     local_entry_pointer_a
            ldy     #LOCAL_ENTRY_FLAGS
            lda     local_event_flags
            and     #ATTR_DIRECTORY
            beq     local_check_image
            lda     #LOCAL_FLAG_DIRECTORY
            bra     local_store_flags
local_check_image:
            jsr     local_filename_is_image
            bcc     +
            lda     #LOCAL_FLAG_IMAGE
            bra     local_store_flags
+           lda     #0
local_store_flags:
            ldy     #LOCAL_ENTRY_FLAGS
            sta     (ZP_POINTER),y
            inc     local_count
            jsr     local_directory_read_next
            bra     local_directory_events

local_directory_discard:
            lda     #<local_trash
            sta     KARGS_BUF
            lda     #>local_trash
            sta     KARGS_BUF+1
            lda     local_name_length
            sta     KARGS_BUFLEN
            jsr     KERNEL_READ_DATA
local_directory_discard_ext:
            jsr     local_read_directory_ext
            jsr     local_directory_read_next
            bra     local_directory_events

local_directory_free:
            jsr     local_read_directory_ext
local_directory_eof:
            lda     local_stream
            sta     KARGS_DIRECTORY_STREAM
            jsr     KERNEL_DIRECTORY_CLOSE
            bra     local_directory_events

local_directory_error:
            lda     #1
            sta     local_failed
            lda     #$e2
            sta     mailbox_error
            bra     local_directory_eof

local_directory_closed:
            lda     local_failed
            bne     local_directory_closed_error
            lda     #1
            sta     local_loaded
            clc
            rts
local_directory_closed_error:
            sec
            rts

local_directory_read_next:
            lda     local_stream
            sta     KARGS_DIRECTORY_STREAM
            jmp     KERNEL_DIRECTORY_READ

local_read_directory_ext:
            lda     #<local_trash
            sta     KARGS_BUF
            lda     #>local_trash
            sta     KARGS_BUF+1
            lda     #2
            sta     KARGS_BUFLEN
            jmp     KERNEL_READ_EXT

local_path_length:
            ldy     #0
-           lda     local_path,y
            beq     +
            iny
            bne     -
+           tya
            rts

local_entry_pointer:
            lda     local_cursor
local_entry_pointer_a:
            sta     ZP_POINTER
            stz     ZP_POINTER+1
            ldx     #6
-           asl     ZP_POINTER
            rol     ZP_POINTER+1
            dex
            bne     -
            clc
            lda     ZP_POINTER
            adc     #<LOCAL_ENTRY_BUFFER
            sta     ZP_POINTER
            lda     ZP_POINTER+1
            adc     #>LOCAL_ENTRY_BUFFER
            sta     ZP_POINTER+1
            rts

; ZP_POINTER addresses the flags byte of the entry.
local_filename_is_image:
            lda     local_name_length
            cmp     #3
            bcc     local_not_image
            tay
            lda     (ZP_POINTER),y
            ora     #$20
            cmp     #'z'
            bne     local_check_bin
            dey
            lda     (ZP_POINTER),y
            ora     #$20
            cmp     #'g'
            bne     local_check_bin
            dey
            lda     (ZP_POINTER),y
            cmp     #'.'
            bne     local_check_bin
            sec
            rts
local_check_bin:
            lda     local_name_length
            cmp     #4
            bcc     local_not_image
            tay
            lda     (ZP_POINTER),y
            ora     #$20
            cmp     #'n'
            bne     local_not_image
            dey
            lda     (ZP_POINTER),y
            ora     #$20
            cmp     #'i'
            bne     local_not_image
            dey
            lda     (ZP_POINTER),y
            ora     #$20
            cmp     #'b'
            bne     local_not_image
            dey
            lda     (ZP_POINTER),y
            cmp     #'.'
            bne     local_not_image
            sec
            rts
local_not_image:
            clc
            rts

local_entry_is_test_image:
            jsr     local_entry_pointer
            ldy     #LOCAL_ENTRY_NAME
            ldx     #0
-           lda     (ZP_POINTER),y
            cmp     autotest_image_name,x
            bne     +
            cmp     #0
            beq     local_test_image_match
            inx
            iny
            bra     -
+           clc
            rts
local_test_image_match:
            sec
            rts

adjust_local_top:
            lda     local_cursor
            cmp     local_top
            bcs     +
            sta     local_top
            rts
+           sec
            sbc     local_top
            cmp     #UI_MAX_ENTRIES
            bcc     +
            lda     local_cursor
            sec
            sbc     #UI_MAX_ENTRIES-1
            sta     local_top
+           rts

local_append_directory:
            jsr     local_entry_pointer
            jsr     local_path_length
            tax
            cpx     #126
            bcs     local_path_too_long
            cpx     #0
            beq     local_append_name
            lda     local_path-1,x
            cmp     #'/'
            beq     local_append_name
            lda     #'/'
            sta     local_path,x
            inx
local_append_name:
            ldy     #LOCAL_ENTRY_NAME
local_append_name_loop:
            lda     (ZP_POINTER),y
            beq     local_append_slash
            cpx     #126
            bcs     local_path_too_long
            sta     local_path,x
            inx
            iny
            bra     local_append_name_loop
local_append_slash:
            lda     #'/'
            sta     local_path,x
            inx
            stz     local_path,x
            clc
            rts
local_path_too_long:
            sec
            rts

local_parent_directory:
            jsr     local_path_length
            tax
            cpx     #1
            beq     local_at_root
            dex
            lda     local_path,x
            cmp     #'/'
            bne     +
            stz     local_path,x
+           dex
local_parent_scan:
            lda     local_path,x
            cmp     #'/'
            beq     local_parent_found
            dex
            bpl     local_parent_scan
local_parent_found:
            inx
            stz     local_path,x
            clc
            rts
local_at_root:
            sec
            rts

; ---------------------------------------------------------------------------
; Two-pass local-SD to manager-SD transfer
; ---------------------------------------------------------------------------

install_local_entry:
            jsr     prepare_transfer_filename
            bcs     transfer_return_error
install_prepared_entry:
            jsr     make_crc_table
            ldx     #3
            lda     #$ff
-           sta     crc_value,x
            stz     file_size,x
            stz     uploaded_size,x
            dex
            bpl     -
            stz     header_count
            stz     transfer_phase
            stz     transfer_stream
            stz     upload_started
            stz     transfer_failed
            stz     transfer_progress
            stz     progress_activity
            ldx     #7
-           stz     file_tail,x
            dex
            bpl     -
            lda     #<scan_text
            ldx     #>scan_text
            jsr     draw_status
            jsr     draw_scan_progress
            jsr     open_transfer_file
            bcs     transfer_open_error

transfer_event_loop:
            lda     #<event_buffer
            sta     KARGS_EVENT_DEST
            lda     #>event_buffer
            sta     KARGS_EVENT_DEST+1
            jsr     KERNEL_NEXT_EVENT
            bcc     transfer_have_event
            jsr     KERNEL_YIELD
            bra     transfer_event_loop
transfer_have_event:
            lda     EVENT_TYPE
            cmp     #EVENT_FILE_OPENED
            beq     transfer_opened
            cmp     #EVENT_FILE_DATA
            beq     transfer_data
            cmp     #EVENT_FILE_EOF
            beq     transfer_eof
            cmp     #EVENT_FILE_CLOSED
            beq     transfer_closed
            cmp     #EVENT_FILE_NOT_FOUND
            beq     transfer_file_failure
            cmp     #EVENT_FILE_ERROR
            beq     transfer_file_failure
            bra     transfer_event_loop

transfer_opened:
            lda     EVENT_STREAM
            sta     transfer_stream
            lda     transfer_phase
            beq     transfer_request_next
            lda     transfer_target
            cmp     #TARGET_FLASH_GZIP
            beq     transfer_opened_flash
            lda     #<install_text
            ldx     #>install_text
            bra     transfer_opened_status
transfer_opened_flash:
            lda     #<direct_flash_text
            ldx     #>direct_flash_text
transfer_opened_status:
            jsr     draw_status
            lda     #COMMAND_IMAGE_ABORT
            ldx     #0
            jsr     mailbox_command
            bcs     transfer_mailbox_failure
            jsr     build_begin_payload
            stz     transfer_retry
transfer_begin_retry:
            lda     #<begin_payload
            sta     ZP_POINTER
            lda     #>begin_payload
            sta     ZP_POINTER+1
            lda     #1
            sta     upload_started
            lda     #COMMAND_IMAGE_BEGIN
            ldx     begin_length
            jsr     mailbox_command
            bcc     transfer_begin_query
            lda     mailbox_error
            cmp     #$10
            bne     transfer_mailbox_failure
transfer_begin_query:
            lda     #COMMAND_IMAGE_STATUS
            ldx     #0
            jsr     mailbox_command
            bcs     transfer_begin_not_confirmed
            jsr     transfer_read_remote_size
            bcs     transfer_begin_not_confirmed
            lda     MAILBOX_REMOTE_STATUS
            and     #$02
            beq     transfer_begin_not_confirmed
            jsr     remote_matches_uploaded
            bcc     transfer_request_next
transfer_begin_not_confirmed:
            inc     transfer_retry
            lda     transfer_retry
            cmp     #8
            bcc     transfer_begin_retry
            lda     #$fc
            sta     mailbox_error
            bra     transfer_mailbox_failure

transfer_data:
            lda     EVENT_STREAM
            cmp     transfer_stream
            bne     transfer_event_loop
            lda     EVENT_FILE_READ_COUNT
            sta     chunk_length
            sta     KARGS_BUFLEN
            lda     #<io_buffer
            sta     KARGS_BUF
            lda     #>io_buffer
            sta     KARGS_BUF+1
            jsr     KERNEL_READ_DATA
            bcs     transfer_file_failure
            lda     transfer_phase
            bne     transfer_upload_data
            jsr     scan_chunk
            inc     transfer_progress
            lda     transfer_progress
            and     #$7f
            bne     transfer_request_next
            jsr     draw_scan_progress
            bra     transfer_request_next

transfer_upload_data:
            stz     transfer_retry
transfer_data_retry:
            lda     #COMMAND_PING
            ldx     #0
            jsr     mailbox_command
            bcs     transfer_mailbox_failure
            lda     #<io_buffer
            sta     ZP_POINTER
            lda     #>io_buffer
            sta     ZP_POINTER+1
            lda     #COMMAND_IMAGE_DATA
            ldx     chunk_length
            jsr     mailbox_command
            bcs     transfer_mailbox_failure
            jsr     build_expected_upload_size
            jsr     transfer_read_remote_size
            bcs     transfer_mailbox_failure
            jsr     remote_matches_expected
            bcc     transfer_data_accepted
            jsr     remote_matches_uploaded
            bcs     transfer_sync_failure
            inc     transfer_retry
            lda     transfer_retry
            cmp     #8
            bcc     transfer_data_retry
transfer_sync_failure:
            lda     #$fc
            sta     mailbox_error
            bra     transfer_mailbox_failure
transfer_data_accepted:
            ldx     #3
-           lda     expected_upload_size,x
            sta     uploaded_size,x
            dex
            bpl     -
            inc     transfer_progress
            lda     transfer_progress
            and     #$7f
            bne     transfer_progress_resync_check
            jsr     draw_install_progress
transfer_progress_resync_check:
            lda     transfer_progress
            and     #$3f
            bne     transfer_request_next
            jsr     transfer_resync_mailbox
            bcs     transfer_mailbox_failure

transfer_request_next:
            lda     transfer_stream
            sta     KARGS_FILE_STREAM
            lda     #MAX_PAYLOAD
            sta     KARGS_FILE_READ_LEN
            jsr     KERNEL_FILE_READ
            bcs     transfer_file_failure
            jmp     transfer_event_loop

transfer_eof:
            lda     EVENT_STREAM
            cmp     transfer_stream
            bne     transfer_event_loop
            lda     transfer_phase
            beq     transfer_close_file
            stz     transfer_retry
transfer_end_retry:
            lda     #COMMAND_IMAGE_END
            ldx     #0
            jsr     mailbox_command
            bcc     transfer_end_query
            lda     mailbox_error
            cmp     #$18
            bne     transfer_mailbox_failure
transfer_end_query:
            lda     #COMMAND_IMAGE_STATUS
            ldx     #0
            jsr     mailbox_command
            bcs     transfer_end_not_confirmed
            jsr     transfer_read_remote_size
            bcs     transfer_end_not_confirmed
            lda     MAILBOX_REMOTE_STATUS
            and     #$02
            bne     transfer_end_not_confirmed
            jsr     remote_matches_uploaded
            bcc     transfer_end_confirmed
transfer_end_not_confirmed:
            inc     transfer_retry
            lda     transfer_retry
            cmp     #8
            bcc     transfer_end_retry
            lda     #$fc
            sta     mailbox_error
            bra     transfer_mailbox_failure
transfer_end_confirmed:
            stz     upload_started
            jsr     draw_install_progress
transfer_close_file:
            lda     transfer_stream
            sta     KARGS_FILE_STREAM
            jsr     KERNEL_FILE_CLOSE
            bcs     transfer_file_failure
            jmp     transfer_event_loop

transfer_closed:
            lda     EVENT_STREAM
            cmp     transfer_stream
            bne     transfer_event_loop
            stz     transfer_stream
            lda     transfer_failed
            bne     transfer_return_error
            lda     transfer_phase
            bne     transfer_return_ok
            jsr     finish_scan
            bcs     transfer_return_error
            lda     #1
            sta     transfer_phase
            stz     transfer_progress
            jsr     draw_install_progress
            jsr     open_transfer_file
            bcs     transfer_open_error
            jmp     transfer_event_loop
transfer_return_ok:
            clc
            rts

transfer_open_error:
            lda     #$e4
            sta     mailbox_error
transfer_return_error:
            sec
            rts

transfer_file_failure:
            lda     #$e5
            sta     mailbox_error
            lda     mailbox_error
            sta     transfer_saved_error
            jsr     abort_transfer_upload
            lda     transfer_saved_error
            sta     mailbox_error
            bra     transfer_fail_and_close
transfer_mailbox_failure:
            lda     mailbox_error
            sta     transfer_saved_error
            jsr     abort_transfer_upload
            lda     transfer_saved_error
            sta     mailbox_error
transfer_fail_and_close:
            lda     #1
            sta     transfer_failed
            lda     transfer_stream
            beq     transfer_return_error
            sta     KARGS_FILE_STREAM
            jsr     KERNEL_FILE_CLOSE
            bcs     transfer_return_error
            jmp     transfer_event_loop

abort_transfer_upload:
            lda     upload_started
            beq     +
            stz     upload_started
            lda     #COMMAND_IMAGE_ABORT
            ldx     #0
            jsr     mailbox_command
+           rts

; The FPGA transport sequence is eight bits wide. Reset its local transport
; before it can wrap, then prove the RP2040 still has the exact accepted byte
; count. IMAGE_ABORT/IMAGE_BEGIN are intentionally not involved, so the
; transactional destination file remains open across this re-sync.
transfer_resync_mailbox:
            lda     #(MAILBOX_CONTROL_ENABLE | MAILBOX_CONTROL_CLEAR | MAILBOX_CONTROL_RESET)
            sta     MAILBOX_CONTROL
            lda     #MAILBOX_CONTROL_ENABLE
            sta     MAILBOX_CONTROL
            jsr     mailbox_wait_online
            bcs     transfer_resync_failed
            jsr     mailbox_delay
            lda     #COMMAND_IMAGE_STATUS
            ldx     #0
            jsr     mailbox_command
            bcs     transfer_resync_failed
            jsr     transfer_read_remote_size
            bcs     transfer_resync_failed
            jsr     remote_matches_uploaded
            bcs     transfer_resync_failed
            clc
            rts
transfer_resync_failed:
            lda     #$fc
            sta     mailbox_error
            sec
            rts

prepare_transfer_filename:
            jsr     local_entry_pointer
            ldy     #LOCAL_ENTRY_NAME
            ldx     #0
prepare_install_name:
            lda     (ZP_POINTER),y
            sta     install_name,x
            beq     install_name_done
            inx
            iny
            cpx     #LOCAL_ENTRY_NAME_MAX+1
            bcc     prepare_install_name
            sec
            rts
install_name_done:
            stx     install_name_length
            jsr     local_path_length
            sta     filename_length
            tay
            beq     prepare_path_base_done
            dey
prepare_path_base_copy:
            lda     local_path,y
            sta     filename,y
            dey
            bpl     prepare_path_base_copy
prepare_path_base_done:
            lda     filename_length
            tax
            ldy     #0
prepare_path_copy:
            cpy     install_name_length
            beq     prepare_path_done
            cpx     #126
            bcs     prepare_path_error
            lda     install_name,y
            sta     filename,x
            inx
            iny
            bra     prepare_path_copy
prepare_path_done:
            stz     filename,x
            stx     filename_length
            jsr     transfer_filename_is_gzip
            lda     #FORMAT_RAW
            bcc     +
            lda     #FORMAT_GZIP
+           sta     transfer_format
            clc
            rts
prepare_path_error:
            sec
            rts

transfer_filename_is_gzip:
            lda     install_name_length
            cmp     #3
            bcc     +
            tay
            dey
            lda     install_name,y
            ora     #$20
            cmp     #'z'
            bne     +
            dey
            lda     install_name,y
            ora     #$20
            cmp     #'g'
            bne     +
            dey
            lda     install_name,y
            cmp     #'.'
            bne     +
            sec
            rts
+           clc
            rts

open_transfer_file:
            lda     local_drive
            sta     KARGS_FILE_DRIVE
            stz     KARGS_FILE_COOKIE
            stz     KARGS_FILE_MODE
            lda     #<filename
            sta     KARGS_BUF
            lda     #>filename
            sta     KARGS_BUF+1
            lda     filename_length
            sta     KARGS_BUFLEN
            jmp     KERNEL_FILE_OPEN

scan_chunk:
            jsr     update_file_tail
            ldy     #0
scan_chunk_loop:
            cpy     chunk_length
            beq     scan_chunk_done
            lda     io_buffer,y
            jsr     update_crc
            lda     header_count
            cmp     #10
            bcs     +
            tax
            lda     io_buffer,y
            sta     image_header,x
            inc     header_count
+           iny
            bra     scan_chunk_loop
scan_chunk_done:
            clc
            lda     file_size
            adc     chunk_length
            sta     file_size
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

update_file_tail:
            lda     chunk_length
            cmp     #8
            bcc     update_short_tail
            sec
            sbc     #8
            tay
            ldx     #0
-           lda     io_buffer,y
            sta     file_tail,x
            iny
            inx
            cpx     #8
            bne     -
            rts
update_short_tail:
            ldy     #0
update_short_tail_byte:
            cpy     chunk_length
            beq     update_tail_done
            ldx     #0
-           lda     file_tail+1,x
            sta     file_tail,x
            inx
            cpx     #7
            bne     -
            lda     io_buffer,y
            sta     file_tail+7
            iny
            bra     update_short_tail_byte
update_tail_done:
            rts

finish_scan:
            ldx     #3
-           lda     crc_value,x
            eor     #$ff
            sta     crc_value,x
            dex
            bpl     -
            lda     transfer_format
            cmp     #FORMAT_GZIP
            beq     validate_gzip_scan
            lda     file_size
            cmp     #$5c
            bne     invalid_transfer_image
            lda     file_size+1
            cmp     #$7a
            bne     invalid_transfer_image
            lda     file_size+2
            cmp     #$94
            bne     invalid_transfer_image
            lda     file_size+3
            bne     invalid_transfer_image
            clc
            rts
validate_gzip_scan:
            lda     header_count
            cmp     #10
            bne     invalid_transfer_image
            lda     image_header
            cmp     #$1f
            bne     invalid_transfer_image
            lda     image_header+1
            cmp     #$8b
            bne     invalid_transfer_image
            lda     image_header+2
            cmp     #8
            bne     invalid_transfer_image
            lda     image_header+3
            and     #$e0
            bne     invalid_transfer_image
            ; Manager SD is not constrained by the 2 MiB flash-slot size.
            lda     file_tail+4
            cmp     #$5c
            bne     invalid_transfer_image
            lda     file_tail+5
            cmp     #$7a
            bne     invalid_transfer_image
            lda     file_tail+6
            cmp     #$94
            bne     invalid_transfer_image
            lda     file_tail+7
            bne     invalid_transfer_image
            lda     transfer_target
            cmp     #TARGET_FLASH_GZIP
            bne     valid_transfer_image
            ; Reject oversized direct uploads before IMAGE_BEGIN can erase
            ; the existing 2 MiB replaceable slot.
            lda     file_size+3
            bne     invalid_transfer_image
            lda     file_size+2
            cmp     #$20
            bcc     valid_transfer_image
            bne     invalid_transfer_image
            lda     file_size+1
            ora     file_size
            bne     invalid_transfer_image
valid_transfer_image:
            clc
            rts
invalid_transfer_image:
            lda     #$e6
            sta     mailbox_error
            sec
            rts

make_crc_table:
            ldx     #0
make_crc_byte:
            lda     #0
            sta     crc_value+2
            sta     crc_value+1
            stx     crc_value
            ldy     #8
make_crc_bit:
            lsr     a
            ror     crc_value+2
            ror     crc_value+1
            ror     crc_value
            bcc     make_crc_no_poly
            eor     #$ed
            pha
            lda     crc_value+2
            eor     #$b8
            sta     crc_value+2
            lda     crc_value+1
            eor     #$83
            sta     crc_value+1
            lda     crc_value
            eor     #$20
            sta     crc_value
            pla
make_crc_no_poly:
            dey
            bne     make_crc_bit
            sta     CRC_TABLE3,x
            lda     crc_value+2
            sta     CRC_TABLE2,x
            lda     crc_value+1
            sta     CRC_TABLE1,x
            lda     crc_value
            sta     CRC_TABLE0,x
            inx
            bne     make_crc_byte
            rts

update_crc:
            eor     crc_value
            tax
            lda     crc_value+1
            eor     CRC_TABLE0,x
            sta     crc_value
            lda     crc_value+2
            eor     CRC_TABLE1,x
            sta     crc_value+1
            lda     crc_value+3
            eor     CRC_TABLE2,x
            sta     crc_value+2
            lda     CRC_TABLE3,x
            sta     crc_value+3
            rts

build_begin_payload:
            lda     transfer_target
            sta     begin_payload
            lda     context
            sta     begin_payload+1
            ldx     #0
-           lda     file_size,x
            sta     begin_payload+2,x
            lda     crc_value,x
            sta     begin_payload+6,x
            inx
            cpx     #4
            bne     -
            lda     install_name_length
            sta     begin_payload+10
            clc
            adc     #11
            sta     begin_length
            ldy     #0
-           cpy     install_name_length
            beq     +
            lda     install_name,y
            sta     begin_payload+11,y
            iny
            bra     -
+           rts

build_expected_upload_size:
            clc
            lda     uploaded_size
            adc     chunk_length
            sta     expected_upload_size
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
-           lda     remote_upload_size,x
            cmp     expected_upload_size,x
            bne     remote_size_mismatch
            dex
            bpl     -
            clc
            rts
remote_matches_uploaded:
            ldx     #3
-           lda     remote_upload_size,x
            cmp     uploaded_size,x
            bne     remote_size_mismatch
            dex
            bpl     -
            clc
            rts
remote_size_mismatch:
            sec
            rts

transfer_read_remote_size:
            ldy     #$ff
transfer_rx_wait_outer:
            ldx     #$ff
transfer_rx_wait_inner:
            lda     MAILBOX_RX_COUNT_HI
            bne     transfer_rx_ready
            lda     MAILBOX_RX_COUNT_LO
            cmp     #4
            bcs     transfer_rx_ready
            dex
            bne     transfer_rx_wait_inner
            dey
            bne     transfer_rx_wait_outer
            lda     #$fb
            sta     mailbox_error
            sec
            rts
transfer_rx_ready:
            ldx     #$ff
-           dex
            bne     -
            lda     MAILBOX_RX_COUNT_HI
            bne     transfer_rx_bad_count
            lda     MAILBOX_RX_COUNT_LO
            cmp     #4
            bcc     transfer_rx_bad_count
            sec
            sbc     #4
            tay
-           cpy     #0
            beq     transfer_rx_value
            lda     MAILBOX_RX_DATA
            dey
            bra     -
transfer_rx_value:
            ldx     #0
-           lda     MAILBOX_RX_DATA
            sta     remote_upload_size,x
            inx
            cpx     #4
            bne     -
            clc
            rts
transfer_rx_bad_count:
            lda     #$fa
            sta     mailbox_error
            sec
            rts

; ---------------------------------------------------------------------------
; Cursor-driven catalog UI, adapted from pexec's chooser interaction model.
; ---------------------------------------------------------------------------

draw_help_screen:
            jsr     ui_clear_screen
            lda     #2
            sta     MMU_IO_CTRL
            jsr     ui_draw_logo
            ldx     #32
            ldy     #5
            jsr     ui_set_xy
            lda     #<ui_help_title_text
            ldx     #>ui_help_title_text
            jsr     ui_puts
            ldx     #7
            ldy     #9
            jsr     ui_set_xy
            lda     #<help_columns_text
            ldx     #>help_columns_text
            jsr     ui_puts
            jsr     ui_draw_top_border
            stz     help_line_index
draw_help_frame_row:
            lda     help_line_index
            clc
            adc     #UI_LIST_LINE
            tay
            lda     #UI_COLOR_NORMAL
            jsr     ui_set_line_color
            ldx     #UI_BOX_LEFT
            ldy     ui_row
            jsr     ui_set_xy
            lda     #BOX_V
            jsr     ui_putc
            ldx     #UI_BOX_RIGHT
            ldy     ui_row
            jsr     ui_set_xy
            lda     #BOX_V
            jsr     ui_putc
            inc     help_line_index
            lda     help_line_index
            cmp     #UI_MAX_ENTRIES
            bcc     draw_help_frame_row
            stz     help_line_index
draw_help_line:
            lda     help_line_index
            asl     a
            tax
            lda     ui_help_line_ptrs,x
            sta     status_pointer
            inx
            lda     ui_help_line_ptrs,x
            sta     status_pointer+1
            ldx     #7
            lda     help_line_index
            clc
            adc     #UI_LIST_LINE
            tay
            jsr     ui_set_xy
            lda     status_pointer
            ldx     status_pointer+1
            jsr     ui_puts
            inc     help_line_index
            lda     help_line_index
            cmp     #HELP_LINE_COUNT
            bcc     draw_help_line
            jsr     ui_draw_bottom_border
            ldx     #5
            ldy     #UI_BOTTOM_LINE+2
            jsr     ui_set_xy
            lda     #<help_hint_text
            ldx     #>help_hint_text
            jsr     ui_puts
            lda     #UI_COLOR_KEY_BAR
            ldy     #UI_KEY_LINE
            jsr     ui_set_full_line_color
            ldx     #0
            ldy     #UI_KEY_LINE
            jsr     ui_set_xy
            lda     #<boot_log_key_bar_text
            ldx     #>boot_log_key_bar_text
            jsr     ui_puts
            stz     MMU_IO_CTRL
            rts

draw_boot_log_screen:
            jsr     ui_clear_screen
            lda     #2
            sta     MMU_IO_CTRL
            jsr     ui_draw_logo
            ldx     #32
            ldy     #5
            jsr     ui_set_xy
            lda     #<ui_boot_log_title_text
            ldx     #>ui_boot_log_title_text
            jsr     ui_puts
            ldx     #7
            ldy     #9
            jsr     ui_set_xy
            lda     #<boot_log_columns_text
            ldx     #>boot_log_columns_text
            jsr     ui_puts
            jsr     ui_draw_top_border
            stz     MMU_IO_CTRL
            stz     boot_log_index
            stz     boot_log_count
draw_boot_log_next:
            jsr     get_boot_log_entry
            bcs     draw_boot_log_error
            lda     response_buffer+4
            cmp     #UI_MAX_ENTRIES+1
            bcc     +
            lda     #UI_MAX_ENTRIES
+           sta     boot_log_count
            bne     draw_boot_log_line
            lda     #2
            sta     MMU_IO_CTRL
            ldx     #7
            ldy     #UI_LIST_LINE
            jsr     ui_set_xy
            lda     #<boot_log_empty_text
            ldx     #>boot_log_empty_text
            jsr     ui_puts
            bra     draw_boot_log_finish
draw_boot_log_line:
            ldy     boot_log_line_length
            lda     #0
            sta     response_buffer+7,y
            lda     #2
            sta     MMU_IO_CTRL
            ldx     #7
            ldy     boot_log_index
            tya
            clc
            adc     #UI_LIST_LINE
            tay
            jsr     ui_set_xy
            lda     #<(response_buffer+7)
            ldx     #>(response_buffer+7)
            jsr     ui_puts
            stz     MMU_IO_CTRL
            inc     boot_log_index
            lda     boot_log_index
            cmp     boot_log_count
            bcc     draw_boot_log_next
            lda     #2
            sta     MMU_IO_CTRL
draw_boot_log_finish:
            jsr     ui_draw_bottom_border
            ldx     #5
            ldy     #UI_BOTTOM_LINE+2
            jsr     ui_set_xy
            lda     #<boot_log_hint_text
            ldx     #>boot_log_hint_text
            jsr     ui_puts
            lda     #UI_COLOR_KEY_BAR
            ldy     #UI_KEY_LINE
            jsr     ui_set_full_line_color
            ldx     #0
            ldy     #UI_KEY_LINE
            jsr     ui_set_xy
            lda     #<boot_log_key_bar_text
            ldx     #>boot_log_key_bar_text
            jsr     ui_puts
            stz     MMU_IO_CTRL
            clc
            rts
draw_boot_log_error:
            stz     MMU_IO_CTRL
            sec
            rts

draw_local_screen:
            jsr     ui_clear_screen
            lda     #2
            sta     MMU_IO_CTRL
            jsr     ui_draw_logo
            ldx     #32
            ldy     #5
            jsr     ui_set_xy
            lda     #<ui_local_title_text
            ldx     #>ui_local_title_text
            jsr     ui_puts
            ldx     #5
            ldy     #7
            jsr     ui_set_xy
            lda     manager_sd_available
            beq     draw_local_no_manager_sd
            lda     #<local_target_text
            ldx     #>local_target_text
            jsr     ui_puts
            bra     draw_local_target_context
draw_local_no_manager_sd:
            lda     #<local_no_manager_sd_text
            ldx     #>local_no_manager_sd_text
            jsr     ui_puts
draw_local_target_context:
            lda     context
            clc
            adc     #'1'
            jsr     ui_putc
            ldx     #7
            ldy     #9
            jsr     ui_set_xy
            lda     #<ui_local_columns_text
            ldx     #>ui_local_columns_text
            jsr     ui_puts
            jsr     ui_draw_top_border
            ldx     #8
            ldy     #UI_LIST_LINE-1
            jsr     ui_set_xy
            lda     local_drive
            clc
            adc     #'0'
            jsr     ui_putc
            lda     #':'
            jsr     ui_putc
            lda     #<local_path
            ldx     #>local_path
            jsr     ui_puts
            stz     MMU_IO_CTRL
            jsr     draw_local_entries
            lda     #2
            sta     MMU_IO_CTRL
            jsr     ui_draw_bottom_border
            jsr     ui_draw_key_bar
            stz     MMU_IO_CTRL
            rts

draw_local_entries:
            lda     #2
            sta     MMU_IO_CTRL
            stz     ui_entry_index
draw_local_entries_loop:
            lda     ui_entry_index
            cmp     #UI_MAX_ENTRIES
            bcs     draw_local_entries_done
            clc
            adc     local_top
            sta     local_draw_index
            cmp     local_count
            bcs     draw_local_empty
            jsr     draw_local_entry
            bra     draw_local_next
draw_local_empty:
            jsr     draw_blank_entry
draw_local_next:
            inc     ui_entry_index
            bra     draw_local_entries_loop
draw_local_entries_done:
            stz     MMU_IO_CTRL
            rts

draw_local_entry:
            lda     local_draw_index
            jsr     local_entry_pointer_a
            ldy     #LOCAL_ENTRY_FLAGS
            lda     (ZP_POINTER),y
            sta     ui_entry_flags
            lda     local_draw_index
            cmp     local_cursor
            bne     +
            lda     #UI_COLOR_HIGHLIGHT
            bra     draw_local_color
+           lda     #UI_COLOR_NORMAL
draw_local_color:
            pha
            ldy     ui_entry_index
            tya
            clc
            adc     #UI_LIST_LINE
            tay
            pla
            jsr     ui_set_line_color
            ldx     #UI_BOX_LEFT
            ldy     ui_entry_index
            tya
            clc
            adc     #UI_LIST_LINE
            tay
            jsr     ui_set_xy
            lda     #BOX_V
            jsr     ui_putc
            lda     #' '
            jsr     ui_putc
            lda     local_draw_index
            cmp     local_cursor
            bne     +
            lda     #'>'
            bra     draw_local_marker
+           lda     #' '
draw_local_marker:
            jsr     ui_putc
            lda     #' '
            jsr     ui_putc
            lda     ui_entry_flags
            and     #LOCAL_FLAG_DIRECTORY
            beq     +
            lda     #'/'
            jsr     ui_putc
            bra     draw_local_name
+           lda     #' '
            jsr     ui_putc
draw_local_name:
            ; local_entry_pointer_a uses ZP_POINTER, which currently holds the
            ; text-screen destination established by ui_set_xy.  Preserve the
            ; destination while resolving the filename source; otherwise
            ; ui_puts and the row padding overwrite the directory-entry cache.
            lda     ZP_POINTER
            sta     status_pointer
            lda     ZP_POINTER+1
            sta     status_pointer+1
            lda     local_draw_index
            jsr     local_entry_pointer_a
            inc     ZP_POINTER
            bne     +
            inc     ZP_POINTER+1
+           lda     ZP_POINTER
            ldx     ZP_POINTER+1
            pha
            lda     status_pointer
            sta     ZP_POINTER
            lda     status_pointer+1
            sta     ZP_POINTER+1
            pla
            jsr     ui_puts
draw_local_pad:
            lda     ui_column
            cmp     #UI_BOX_RIGHT
            bcs     draw_local_border
            lda     #' '
            jsr     ui_putc
            bra     draw_local_pad
draw_local_border:
            lda     #BOX_V
            jmp     ui_putc

draw_screen:
            jsr     ui_clear_screen
            lda     #2
            sta     MMU_IO_CTRL
            jsr     ui_draw_logo
            ldx     #34
            ldy     #5
            jsr     ui_set_xy
            lda     #<ui_title_text
            ldx     #>ui_title_text
            jsr     ui_puts

            ldx     #5
            ldy     #7
            jsr     ui_set_xy
            lda     #<context_text
            ldx     #>context_text
            jsr     ui_puts
            lda     context
            clc
            adc     #'1'
            jsr     ui_putc

            ldx     #5
            ldy     #8
            jsr     ui_set_xy
            lda     #<running_text
            ldx     #>running_text
            jsr     ui_puts
            lda     running_valid
            beq     draw_no_running
            lda     running_context
            clc
            adc     #'1'
            jsr     ui_putc
            lda     #' '
            jsr     ui_putc
            lda     running_source
            jsr     ui_print_source
            lda     #' '
            jsr     ui_putc
            lda     #<running_name
            ldx     #>running_name
            jsr     ui_puts
            bra     draw_running_done
draw_no_running:
            lda     #'-'
            jsr     ui_putc
draw_running_done:
            ldx     #7
            ldy     #9
            jsr     ui_set_xy
            lda     #<ui_columns_text
            ldx     #>ui_columns_text
            jsr     ui_puts
            jsr     ui_draw_top_border
            stz     MMU_IO_CTRL
            jsr     draw_entries
            lda     #2
            sta     MMU_IO_CTRL
            jsr     ui_draw_bottom_border
            jsr     ui_draw_key_bar
            stz     MMU_IO_CTRL
            rts

draw_entries:
            lda     #2
            sta     MMU_IO_CTRL
            stz     ui_entry_index
draw_entries_loop:
            lda     ui_entry_index
            cmp     #UI_MAX_ENTRIES
            bcs     draw_entries_done
            cmp     catalog_count
            bcs     draw_empty_entry
            jsr     draw_catalog_entry
            bra     draw_entry_next
draw_empty_entry:
            jsr     draw_blank_entry
draw_entry_next:
            inc     ui_entry_index
            bra     draw_entries_loop
draw_entries_done:
            stz     MMU_IO_CTRL
            rts

draw_catalog_entry:
            lda     ui_entry_index
            sta     catalog_index
            jsr     catalog_entry_pointer
            ldy     #ENTRY_SOURCE
            lda     (ZP_POINTER),y
            sta     ui_entry_source
            iny
            lda     (ZP_POINTER),y
            sta     ui_entry_flags
            lda     ui_entry_index
            cmp     cursor_index
            bne     +
            lda     #UI_COLOR_HIGHLIGHT
            bra     draw_entry_color
+           lda     #UI_COLOR_NORMAL
draw_entry_color:
            pha
            ldy     ui_entry_index
            iny
            tya
            clc
            adc     #UI_LIST_LINE-1
            tay
            pla
            jsr     ui_set_line_color
            ldx     #UI_BOX_LEFT
            ldy     ui_entry_index
            iny
            tya
            clc
            adc     #UI_LIST_LINE-1
            tay
            jsr     ui_set_xy
            lda     #BOX_V
            jsr     ui_putc
            lda     #' '
            jsr     ui_putc
            lda     ui_entry_index
            cmp     cursor_index
            bne     +
            lda     #'>'
            bra     draw_cursor_marker
+           lda     #' '
draw_cursor_marker:
            jsr     ui_putc
            lda     ui_entry_flags
            and     #FLAG_SELECTED
            beq     +
            lda     #'*'
            bra     draw_selected_marker
+           lda     #' '
draw_selected_marker:
            jsr     ui_putc
            lda     ui_entry_flags
            and     #FLAG_RUNNING
            beq     +
            lda     #'+'
            bra     draw_running_marker
+           lda     #' '
draw_running_marker:
            jsr     ui_putc
            lda     #' '
            jsr     ui_putc
            lda     ui_entry_source
            jsr     ui_print_source
            lda     #' '
            jsr     ui_putc
            lda     ZP_POINTER
            sta     status_pointer
            lda     ZP_POINTER+1
            sta     status_pointer+1
            lda     ui_entry_index
            sta     catalog_index
            jsr     catalog_entry_pointer
            clc
            lda     ZP_POINTER
            adc     #ENTRY_NAME
            sta     ZP_POINTER
            bcc     +
            inc     ZP_POINTER+1
+           lda     ZP_POINTER
            ldx     ZP_POINTER+1
            pha
            lda     status_pointer
            sta     ZP_POINTER
            lda     status_pointer+1
            sta     ZP_POINTER+1
            pla
            jsr     ui_puts
draw_entry_pad:
            lda     ui_column
            cmp     #UI_BOX_RIGHT
            bcs     draw_entry_border
            lda     #' '
            jsr     ui_putc
            bra     draw_entry_pad
draw_entry_border:
            lda     #BOX_V
            jmp     ui_putc

draw_blank_entry:
            lda     #UI_COLOR_NORMAL
            pha
            ldy     ui_entry_index
            iny
            tya
            clc
            adc     #UI_LIST_LINE-1
            tay
            pla
            jsr     ui_set_line_color
            ldx     #UI_BOX_LEFT
            ldy     ui_entry_index
            iny
            tya
            clc
            adc     #UI_LIST_LINE-1
            tay
            jsr     ui_set_xy
            lda     #BOX_V
            jsr     ui_putc
draw_blank_pad:
            lda     ui_column
            cmp     #UI_BOX_RIGHT
            bcs     draw_blank_border
            lda     #' '
            jsr     ui_putc
            bra     draw_blank_pad
draw_blank_border:
            lda     #BOX_V
            jmp     ui_putc

draw_status:
            sta     status_pointer
            stx     status_pointer+1
            lda     #2
            sta     MMU_IO_CTRL
            ldy     #UI_BOTTOM_LINE+2
            jsr     ui_clear_full_row
            ldx     #5
            ldy     #UI_BOTTOM_LINE+2
            jsr     ui_set_xy
            lda     status_pointer
            ldx     status_pointer+1
            jsr     ui_puts
            stz     MMU_IO_CTRL
            rts

draw_delete_confirmation:
            lda     #2
            sta     MMU_IO_CTRL
            ldy     #UI_BOTTOM_LINE+2
            jsr     ui_clear_full_row
            ldy     #UI_PROGRESS_LABEL_LINE
            jsr     ui_clear_full_row
            ldy     #UI_PROGRESS_BAR_LINE
            jsr     ui_clear_full_row
            ldy     #UI_PROGRESS_DETAIL_LINE
            jsr     ui_clear_full_row
            ldx     #UI_BOX_LEFT
            ldy     #UI_BOTTOM_LINE+2
            jsr     ui_set_xy
            lda     #<delete_prompt_text
            ldx     #>delete_prompt_text
            jsr     ui_puts
            ldx     #UI_BOX_LEFT
            ldy     #UI_PROGRESS_LABEL_LINE
            jsr     ui_set_xy
            ldy     #0
draw_delete_path_loop:
            cpy     delete_path_length
            beq     draw_delete_instruction
            cpy     #68
            beq     draw_delete_instruction
            lda     delete_path,y
            jsr     ui_putc
            iny
            bra     draw_delete_path_loop
draw_delete_instruction:
            ldx     #UI_BOX_LEFT
            ldy     #UI_PROGRESS_BAR_LINE
            jsr     ui_set_xy
            lda     #<delete_confirm_text
            ldx     #>delete_confirm_text
            jsr     ui_puts
            stz     MMU_IO_CTRL
            rts

draw_scan_progress:
            ldx     #3
-           lda     file_size,x
            sta     progress_current,x
            stz     progress_total,x
            dex
            bpl     -
            lda     #<scan_progress_text
            ldx     #>scan_progress_text
            jmp     draw_progress

draw_install_progress:
            ldx     #3
-           lda     uploaded_size,x
            sta     progress_current,x
            lda     file_size,x
            sta     progress_total,x
            dex
            bpl     -
            lda     transfer_target
            cmp     #TARGET_FLASH_GZIP
            beq     draw_direct_flash_progress
            lda     #<install_progress_text
            ldx     #>install_progress_text
            bra     draw_progress
draw_direct_flash_progress:
            lda     #<direct_flash_progress_text
            ldx     #>direct_flash_progress_text

; A/X points to a stage label. progress_current/progress_total are little-endian
; byte counts. A zero total renders an activity marker and a scanned-byte count.
draw_progress:
            sta     progress_label
            stx     progress_label+1
            jsr     calculate_progress_values

            lda     #2
            sta     MMU_IO_CTRL
            ldy     #UI_PROGRESS_LABEL_LINE
            jsr     ui_clear_full_row
            ldy     #UI_PROGRESS_BAR_LINE
            jsr     ui_clear_full_row
            ldy     #UI_PROGRESS_DETAIL_LINE
            jsr     ui_clear_full_row

            ldx     #UI_BOX_LEFT
            ldy     #UI_PROGRESS_LABEL_LINE
            jsr     ui_set_xy
            lda     progress_label
            ldx     progress_label+1
            jsr     ui_puts

            ldx     #UI_BOX_LEFT
            ldy     #UI_PROGRESS_BAR_LINE
            jsr     ui_set_xy
            lda     #'['
            jsr     ui_putc
            ldx     #0
draw_progress_bar_loop:
            jsr     progress_total_is_zero
            bcc     draw_determinate_cell
            cpx     progress_activity
            bne     draw_activity_empty
            lda     #'>'
            bra     draw_progress_cell
draw_activity_empty:
            lda     #'.'
            bra     draw_progress_cell
draw_determinate_cell:
            cpx     progress_filled
            bcc     draw_progress_filled_cell
            lda     #'.'
            bra     draw_progress_cell
draw_progress_filled_cell:
            lda     #'='
draw_progress_cell:
            jsr     ui_putc
            inx
            cpx     #UI_PROGRESS_BAR_WIDTH
            bne     draw_progress_bar_loop
            lda     #']'
            jsr     ui_putc
            jsr     progress_total_is_zero
            bcc     draw_progress_detail
draw_progress_activity_done:
            inc     progress_activity
            lda     progress_activity
            cmp     #UI_PROGRESS_BAR_WIDTH
            bcc     draw_progress_detail
            stz     progress_activity

draw_progress_detail:
            ldx     #UI_BOX_LEFT
            ldy     #UI_PROGRESS_DETAIL_LINE
            jsr     ui_set_xy
            jsr     progress_total_is_zero
            bcs     draw_progress_current_detail
            stz     decimal_value+1
            lda     progress_percent
            sta     decimal_value
            jsr     ui_print_u16_decimal
            lda     #<progress_percent_text
            ldx     #>progress_percent_text
            jsr     ui_puts
draw_progress_current_detail:
            jsr     progress_current_to_kib
            jsr     ui_print_u16_decimal
            jsr     progress_total_is_zero
            bcc     draw_progress_total_detail
            lda     #<progress_scanned_text
            ldx     #>progress_scanned_text
            jsr     ui_puts
            bra     draw_progress_done
draw_progress_total_detail:
            lda     #<progress_separator_text
            ldx     #>progress_separator_text
            jsr     ui_puts
            jsr     progress_total_to_kib
            jsr     ui_print_u16_decimal
            lda     #<progress_kib_text
            ldx     #>progress_kib_text
            jsr     ui_puts
draw_progress_done:
            stz     MMU_IO_CTRL
            rts

progress_total_is_zero:
            lda     progress_total
            ora     progress_total+1
            ora     progress_total+2
            ora     progress_total+3
            beq     +
            clc
            rts
+           sec
            rts

; Compute both the numeric percentage and the independently scaled full-width
; bar. Index instructions modify carry on the 65816, so the four-byte add and
; subtract operations are intentionally unrolled.
calculate_progress_values:
            stz     progress_percent
            stz     progress_filled
            jsr     progress_total_is_zero
            bcc     +
            rts
+           lda     #100
            sta     progress_ratio_limit
            jsr     calculate_progress_ratio
            lda     progress_ratio_result
            sta     progress_percent
            lda     #UI_PROGRESS_BAR_WIDTH
            sta     progress_ratio_limit
            jsr     calculate_progress_ratio
            lda     progress_ratio_result
            sta     progress_filled
            rts

; Return min(limit, floor(current * limit / total)). current and total are
; bounded below 10 MiB, so multiplication by at most 100 fits in 32 bits.
calculate_progress_ratio:
            stz     progress_ratio_result
            stz     progress_work
            stz     progress_work+1
            stz     progress_work+2
            stz     progress_work+3
            ldy     progress_ratio_limit
progress_ratio_multiply_loop:
            clc
            lda     progress_work
            adc     progress_current
            sta     progress_work
            lda     progress_work+1
            adc     progress_current+1
            sta     progress_work+1
            lda     progress_work+2
            adc     progress_current+2
            sta     progress_work+2
            lda     progress_work+3
            adc     progress_current+3
            sta     progress_work+3
            dey
            bne     progress_ratio_multiply_loop
progress_ratio_divide_loop:
            lda     progress_ratio_result
            cmp     progress_ratio_limit
            bcs     progress_ratio_done
            ldx     #3
progress_ratio_compare_loop:
            lda     progress_work,x
            cmp     progress_total,x
            bcc     progress_ratio_done
            bne     progress_ratio_subtract
            dex
            bpl     progress_ratio_compare_loop
progress_ratio_subtract:
            sec
            lda     progress_work
            sbc     progress_total
            sta     progress_work
            lda     progress_work+1
            sbc     progress_total+1
            sta     progress_work+1
            lda     progress_work+2
            sbc     progress_total+2
            sta     progress_work+2
            lda     progress_work+3
            sbc     progress_total+3
            sta     progress_work+3
            inc     progress_ratio_result
            bra     progress_ratio_divide_loop
progress_ratio_done:
            rts

progress_current_to_kib:
            lda     progress_current+1
            lsr     a
            lsr     a
            sta     decimal_value
            lda     progress_current+2
            and     #3
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            ora     decimal_value
            sta     decimal_value
            lda     progress_current+2
            lsr     a
            lsr     a
            sta     decimal_value+1
            lda     progress_current+3
            and     #3
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            ora     decimal_value+1
            sta     decimal_value+1
            rts

progress_total_to_kib:
            lda     progress_total+1
            lsr     a
            lsr     a
            sta     decimal_value
            lda     progress_total+2
            and     #3
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            ora     decimal_value
            sta     decimal_value
            lda     progress_total+2
            lsr     a
            lsr     a
            sta     decimal_value+1
            lda     progress_total+3
            and     #3
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            asl     a
            ora     decimal_value+1
            sta     decimal_value+1
            rts

ui_print_u16_decimal:
            stz     decimal_started
            ldx     #0
decimal_power_loop:
            stz     decimal_digit
decimal_subtract_loop:
            lda     decimal_value+1
            cmp     decimal_powers_hi,x
            bcc     decimal_emit_digit
            bne     decimal_do_subtract
            lda     decimal_value
            cmp     decimal_powers_lo,x
            bcc     decimal_emit_digit
decimal_do_subtract:
            sec
            lda     decimal_value
            sbc     decimal_powers_lo,x
            sta     decimal_value
            lda     decimal_value+1
            sbc     decimal_powers_hi,x
            sta     decimal_value+1
            inc     decimal_digit
            bra     decimal_subtract_loop
decimal_emit_digit:
            lda     decimal_digit
            bne     decimal_print_digit
            lda     decimal_started
            bne     decimal_print_zero
            cpx     #4
            bne     decimal_next_power
decimal_print_zero:
            lda     #0
decimal_print_digit:
            ora     #'0'
            jsr     ui_putc
            lda     #1
            sta     decimal_started
decimal_next_power:
            inx
            cpx     #5
            bne     decimal_power_loop
            rts

ui_clear_screen:
            stz     MMU_IO_CTRL
            ldx     #63
ui_init_palette:
            lda     ui_text_palette,x
            sta     $d800,x
            sta     $d840,x
            dex
            bpl     ui_init_palette
            ldx     #2
ui_init_background:
            lda     ui_text_palette+4*0,x
            sta     $d005,x
            sta     $d00d,x
            dex
            bpl     ui_init_background
            lda     #$01                ; text-only display
            sta     $d000
            stz     $d001               ; 80 columns by 60 rows
            stz     $d010               ; hide the hardware text cursor
            lda     #3
            sta     MMU_IO_CTRL
            ldx     #0
            lda     #UI_COLOR_NORMAL
ui_clear_colors:
            .for page := 0, page < 19, page += 1
            sta     TEXT_BUFFER+page*$100,x
            .next
            inx
            bne     ui_clear_colors
            lda     #2
            sta     MMU_IO_CTRL
            ldx     #0
            lda     #' '
ui_clear_text:
            .for page := 0, page < 19, page += 1
            sta     TEXT_BUFFER+page*$100,x
            .next
            inx
            bne     ui_clear_text
            stz     MMU_IO_CTRL
            rts

; Draw the generated 80x5 F256-character-set wordmark.  The character and
; color-ID planes are kept verbatim in fpga_manager_logo_80x5.inc.  Palette
; indices 0, 3, 6, and 8 are black, logo green, logo cream, and dark trace.
ui_draw_logo:
            lda     #2
            sta     MMU_IO_CTRL
            ldx     #0
ui_draw_logo_chars_page_0:
            lda     ui_logo_chars,x
            sta     TEXT_BUFFER,x
            inx
            bne     ui_draw_logo_chars_page_0
            ldx     #0
ui_draw_logo_chars_page_1:
            lda     ui_logo_chars+$100,x
            sta     TEXT_BUFFER+$100,x
            inx
            cpx     #144                ; 400 cells total
            bne     ui_draw_logo_chars_page_1

            lda     #3
            sta     MMU_IO_CTRL
            ldx     #0
ui_draw_logo_colors_page_0:
            ldy     ui_logo_colors,x
            lda     ui_logo_color_attrs,y
            sta     TEXT_BUFFER,x
            inx
            bne     ui_draw_logo_colors_page_0
            ldx     #0
ui_draw_logo_colors_page_1:
            ldy     ui_logo_colors+$100,x
            lda     ui_logo_color_attrs,y
            sta     TEXT_BUFFER+$100,x
            inx
            cpx     #144
            bne     ui_draw_logo_colors_page_1
            lda     #2
            sta     MMU_IO_CTRL
            rts

ui_draw_top_border:
            lda     #BOX_TL
            sta     ui_border_left
            lda     #BOX_TR
            sta     ui_border_right
            ldy     #UI_LIST_LINE-1
            bra     ui_draw_border

ui_draw_bottom_border:
            lda     #BOX_BL
            sta     ui_border_left
            lda     #BOX_BR
            sta     ui_border_right
            ldy     #UI_BOTTOM_LINE

ui_draw_border:
            sty     ui_row
            lda     #UI_COLOR_FRAME
            jsr     ui_set_line_color
            ldx     #UI_BOX_LEFT
            ldy     ui_row
            jsr     ui_set_xy
            lda     ui_border_left
            jsr     ui_putc
            ldx     #UI_BOX_RIGHT-UI_BOX_LEFT-1
ui_border_fill:
            lda     #BOX_H
            jsr     ui_putc
            dex
            bne     ui_border_fill
            lda     ui_border_right
            jmp     ui_putc

ui_draw_key_bar:
            lda     #UI_COLOR_KEY_BAR
            ldy     #UI_KEY_LINE
            jsr     ui_set_full_line_color
            ldx     #0
            ldy     #UI_KEY_LINE
            jsr     ui_set_xy
            lda     view_mode
            bne     ui_local_key_bar
            lda     #<key_bar_text
            ldx     #>key_bar_text
            jmp     ui_puts
ui_local_key_bar:
            lda     #<local_key_bar_text
            ldx     #>local_key_bar_text
            jmp     ui_puts

ui_print_source:
            cmp     #SOURCE_AUTO
            bne     +
            lda     #<source_auto_text
            ldx     #>source_auto_text
            bra     ui_source_done
+           cmp     #SOURCE_SD
            bne     +
            lda     #<source_sd_text
            ldx     #>source_sd_text
            bra     ui_source_done
+           cmp     #SOURCE_FLASH
            bne     +
            lda     #<source_flash_text
            ldx     #>source_flash_text
            bra     ui_source_done
+           lda     #<source_golden_text
            ldx     #>source_golden_text
ui_source_done:
            jmp     ui_puts

ui_print_hex_byte:
            pha
            lsr     a
            lsr     a
            lsr     a
            lsr     a
            tax
            lda     hex_digits,x
            jsr     ui_putc
            pla
            and     #$0f
            tax
            lda     hex_digits,x
            jmp     ui_putc

ui_set_xy:
            stx     ui_column
            sty     ui_row
            txa
            clc
            adc     ui_line_lo,y
            sta     ZP_POINTER
            lda     #0
            adc     ui_line_hi,y
            sta     ZP_POINTER+1
            rts

ui_putc:
            sta     (ZP_POINTER)
            inc     ZP_POINTER
            bne     +
            inc     ZP_POINTER+1
+           inc     ui_column
            rts

ui_puts:
            sta     ZP_TIMEOUT0
            stx     ZP_TIMEOUT1
            ldy     #0
ui_puts_loop:
            lda     (ZP_TIMEOUT0),y
            beq     ui_puts_done
            jsr     ui_putc
            iny
            bne     ui_puts_loop
            inc     ZP_TIMEOUT1
            bra     ui_puts_loop
ui_puts_done:
            rts

ui_set_line_color:
            sta     ui_color
            sty     ui_row
            php
            sei
            lda     #3
            sta     MMU_IO_CTRL
            ldy     ui_row
            lda     ui_line_lo,y
            sta     ZP_POINTER
            lda     ui_line_hi,y
            sta     ZP_POINTER+1
            lda     ui_color
            ldy     #UI_BOX_RIGHT-1
ui_line_color_loop:
            sta     (ZP_POINTER),y
            dey
            cpy     #UI_BOX_LEFT
            bne     ui_line_color_loop
            ; The interior uses the requested row color, while both vertical
            ; frame cells remain cream even when the row is highlighted.
            lda     #UI_COLOR_FRAME
            ldy     #UI_BOX_LEFT
            sta     (ZP_POINTER),y
            ldy     #UI_BOX_RIGHT
            sta     (ZP_POINTER),y
            lda     #2
            sta     MMU_IO_CTRL
            plp
            rts

ui_set_full_line_color:
            sta     ui_color
            sty     ui_row
            php
            sei
            lda     #3
            sta     MMU_IO_CTRL
            ldy     ui_row
            lda     ui_line_lo,y
            sta     ZP_POINTER
            lda     ui_line_hi,y
            sta     ZP_POINTER+1
            lda     ui_color
            ldy     #79
ui_full_color_loop:
            sta     (ZP_POINTER),y
            dey
            bpl     ui_full_color_loop
            lda     #2
            sta     MMU_IO_CTRL
            plp
            rts

ui_clear_full_row:
            sty     ui_row
            lda     #UI_COLOR_NORMAL
            jsr     ui_set_full_line_color
            ldx     #0
            ldy     ui_row
            jsr     ui_set_xy
            ldx     #80
ui_clear_row_loop:
            lda     #' '
            jsr     ui_putc
            dex
            bne     ui_clear_row_loop
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

get_boot_log_entry:
            jsr     prepare_nonce
            lda     boot_log_index
            sta     tx_buffer+4
            lda     #COMMAND_GET_BOOT_LOG
            ldx     #5
            jsr     mailbox_command_response
            bcs     get_boot_log_done
            lda     response_length
            cmp     #7
            bcc     response_short
            lda     response_buffer+5
            cmp     boot_log_index
            bne     boot_log_response_bad
            lda     response_buffer+6
            cmp     #68
            bcs     boot_log_response_bad
            sta     boot_log_line_length
            clc
            adc     #7
            cmp     response_length
            bne     boot_log_response_bad
            clc
get_boot_log_done:
            rts
boot_log_response_bad:
            lda     #$f8
            sta     mailbox_error
            sec
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

; Request a one-shot reconfiguration using the highlighted catalog entry.
; The payload deliberately mirrors SET_SELECTION, but command $14 keeps the
; source/path only in the RP2040's pending request and never writes metadata.
reconfigure_catalog_entry_once:
            lda     selected_index
            sta     catalog_index
            jsr     catalog_get
            bcs     reconfigure_once_done
            lda     response_buffer+10
            sta     selected_source
            jsr     prepare_nonce
            lda     context
            sta     tx_buffer+4
            lda     selected_source
            sta     tx_buffer+5
            stz     tx_buffer+6
            cmp     #SOURCE_SD
            bne     reconfigure_once_payload_ready
            lda     response_buffer+18
            sta     tx_buffer+6
            tay
            beq     reconfigure_once_payload_ready
            dey
reconfigure_once_copy_path:
            lda     response_buffer+19,y
            sta     tx_buffer+7,y
            dey
            bpl     reconfigure_once_copy_path
reconfigure_once_payload_ready:
            lda     tx_buffer+6
            clc
            adc     #7
            tax
            lda     #COMMAND_RECONFIGURE_ONCE
            jsr     mailbox_command_response
reconfigure_once_done:
            rts

copy_catalog_entry_to_flash:
            lda     catalog_count
            beq     copy_flash_invalid
            lda     cursor_index
            sta     catalog_index
            jsr     catalog_get
            bcs     copy_flash_done
            lda     response_buffer+10
            cmp     #SOURCE_SD
            bne     copy_flash_invalid
            lda     response_buffer+11
            cmp     #FORMAT_GZIP
            bne     copy_flash_invalid
            lda     #<flash_copy_text
            ldx     #>flash_copy_text
            jsr     draw_status
            jsr     prepare_nonce
            lda     context
            sta     tx_buffer+4
            lda     response_buffer+18
            sta     tx_buffer+5
            tay
            beq     copy_flash_invalid
            dey
copy_flash_path:
            lda     response_buffer+19,y
            sta     tx_buffer+6,y
            dey
            bpl     copy_flash_path
            lda     tx_buffer+5
            clc
            adc     #6
            tax
            lda     #COMMAND_COPY_BEGIN
            jsr     mailbox_command_response
            bcs     copy_flash_done
            lda     response_length
            cmp     #14
            bcc     response_short
            jsr     read_copy_progress_response
            bcs     copy_flash_done
            jsr     draw_copy_progress
copy_flash_step_loop:
            lda     copy_state
            cmp     #COPY_STATE_DONE
            beq     copy_flash_success
            cmp     #COPY_STATE_FAILED
            beq     copy_flash_operation_failed
            jsr     prepare_nonce
            lda     #COMMAND_COPY_STEP
            ldx     #4
            jsr     mailbox_command_response
            bcs     copy_flash_done
            lda     response_length
            cmp     #14
            bcc     response_short
            jsr     read_copy_progress_response
            bcs     copy_flash_done
            jsr     draw_copy_progress
            bra     copy_flash_step_loop
copy_flash_operation_failed:
            lda     copy_error
            sta     mailbox_error
            sec
            rts
copy_flash_success:
            clc
copy_flash_done:
            rts
copy_flash_invalid:
            lda     #$e3
            sta     mailbox_error
            sec
            rts

; Copy an exact visible manager-SD catalog image into the K2 SD browser's
; current directory. The local write is staged under a hidden .part name and
; is published only after the supervisor and K2 CRC/size values agree.
export_catalog_entry_to_local:
            jsr     prepare_export_entry
            bcs     export_return_error
            jsr     make_crc_table
            ldx     #3
            lda     #$ff
-           sta     crc_value,x
            stz     uploaded_size,x
            dex
            bpl     -
            stz     export_stream
            stz     export_stream_open
            stz     export_verified
            stz     transfer_progress

            ; Clear any abandoned transfer/read session before beginning.
            lda     #COMMAND_IMAGE_ABORT
            ldx     #0
            jsr     mailbox_command
            bcs     export_remote_failure

            jsr     prepare_nonce
            lda     context
            sta     tx_buffer+4
            lda     export_path_length
            sta     tx_buffer+5
            tay
            dey
export_begin_copy_path:
            lda     EXPORT_PATH,y
            sta     tx_buffer+6,y
            dey
            bpl     export_begin_copy_path
            lda     export_path_length
            clc
            adc     #6
            tax
            lda     #COMMAND_READ_SD_BEGIN
            jsr     mailbox_command_response
            bcs     export_remote_failure
            lda     response_length
            cmp     #9
            bcc     export_bad_response
            lda     response_buffer+4
            cmp     context
            bne     export_bad_response
            ldx     #3
-           lda     response_buffer+5,x
            sta     file_size,x
            sta     progress_total,x
            dex
            bpl     -
            lda     file_size
            ora     file_size+1
            ora     file_size+2
            ora     file_size+3
            beq     export_bad_response

            lda     #<export_start_text
            ldx     #>export_start_text
            jsr     draw_status
            ldx     #3
-           stz     progress_current,x
            dex
            bpl     -
            lda     #<export_progress_text
            ldx     #>export_progress_text
            jsr     draw_progress

            lda     local_drive
            sta     KARGS_FILE_DRIVE
            stz     KARGS_FILE_COOKIE
            lda     #1
            sta     KARGS_FILE_MODE
            lda     #<EXPORT_TEMPORARY
            sta     KARGS_BUF
            lda     #>EXPORT_TEMPORARY
            sta     KARGS_BUF+1
            lda     export_temporary_length
            sta     KARGS_BUFLEN
            jsr     KERNEL_FILE_OPEN
            bcs     export_local_failure

export_wait_open:
            jsr     export_next_event
            lda     EVENT_TYPE
            cmp     #EVENT_FILE_OPENED
            beq     export_opened
            cmp     #EVENT_FILE_NOT_FOUND
            beq     export_local_failure
            cmp     #EVENT_FILE_ERROR
            beq     export_local_failure
            bra     export_wait_open
export_opened:
            lda     EVENT_STREAM
            sta     export_stream
            lda     #1
            sta     export_stream_open

export_fetch_loop:
            ldx     #3
export_complete_compare:
            lda     uploaded_size,x
            cmp     file_size,x
            bne     export_fetch_data
            dex
            bpl     export_complete_compare
            jmp     export_finish_remote

export_fetch_data:
            jsr     prepare_nonce
            ldx     #3
-           lda     uploaded_size,x
            sta     tx_buffer+4,x
            dex
            bpl     -
            lda     #READ_SD_CHUNK_SIZE
            sta     tx_buffer+8
            stz     transfer_retry
export_read_retry:
            lda     #COMMAND_READ_SD_DATA
            ldx     #9
            jsr     mailbox_command_response
            bcc     export_read_response
            inc     transfer_retry
            lda     transfer_retry
            cmp     #8
            bcc     export_read_retry
            bra     export_remote_failure

export_read_response:
            lda     response_length
            cmp     #9
            bcc     export_bad_response
            sec
            sbc     #8
            sta     chunk_length
            cmp     #READ_SD_CHUNK_SIZE+1
            bcs     export_bad_response
            ldx     #3
-           lda     response_buffer+4,x
            cmp     uploaded_size,x
            bne     export_bad_response
            dex
            bpl     -
            jsr     build_expected_upload_size
            ; Reject a chunk which would cross the size declared by BEGIN.
            ldx     #3
export_size_compare:
            lda     expected_upload_size,x
            cmp     file_size,x
            bcc     export_size_ok
            bne     export_bad_response
            dex
            bpl     export_size_compare
export_size_ok:
            stz     export_write_offset
            lda     chunk_length
            sta     export_write_remaining

export_write_next:
            lda     export_stream
            sta     KARGS_FILE_STREAM
            clc
            lda     #<(response_buffer+8)
            adc     export_write_offset
            sta     KARGS_BUF
            lda     #>(response_buffer+8)
            adc     #0
            sta     KARGS_BUF+1
            lda     export_write_remaining
            sta     KARGS_BUFLEN
            jsr     KERNEL_FILE_WRITE
            bcs     export_local_failure
export_wait_write:
            jsr     export_next_event
            lda     EVENT_TYPE
            cmp     #EVENT_FILE_WROTE
            beq     export_wrote
            cmp     #EVENT_FILE_ERROR
            beq     export_local_failure
            bra     export_wait_write
export_wrote:
            lda     EVENT_STREAM
            cmp     export_stream
            bne     export_wait_write
            lda     EVENT_FILE_WRITE_COUNT
            beq     export_local_failure
            cmp     export_write_remaining
            bcc     export_partial_write
            bne     export_local_failure
            stz     export_write_remaining
            bra     export_chunk_written
export_partial_write:
            clc
            adc     export_write_offset
            sta     export_write_offset
            lda     export_write_remaining
            sec
            sbc     EVENT_FILE_WRITE_COUNT
            sta     export_write_remaining
            bra     export_write_next

export_chunk_written:
            ldy     #0
export_crc_loop:
            cpy     chunk_length
            beq     export_crc_done
            lda     response_buffer+8,y
            jsr     update_crc
            iny
            bra     export_crc_loop
export_crc_done:
            ldx     #3
-           lda     expected_upload_size,x
            sta     uploaded_size,x
            sta     progress_current,x
            dex
            bpl     -
            inc     transfer_progress
            lda     transfer_progress
            and     #$1f
            bne     export_fetch_loop
            lda     #<export_progress_text
            ldx     #>export_progress_text
            jsr     draw_progress
            jmp     export_fetch_loop

export_finish_remote:
            jsr     prepare_nonce
            lda     #COMMAND_READ_SD_END
            ldx     #4
            jsr     mailbox_command_response
            bcs     export_remote_failure
            lda     response_length
            cmp     #12
            bcc     export_bad_response
            ldx     #3
-           lda     response_buffer+4,x
            cmp     file_size,x
            bne     export_bad_response
            dex
            bpl     -
            ldx     #3
export_finalize_crc:
            lda     crc_value,x
            eor     #$ff
            sta     crc_value,x
            cmp     response_buffer+8,x
            bne     export_verify_failure
            dex
            bpl     export_finalize_crc
            lda     #1
            sta     export_verified
            ldx     #3
-           lda     uploaded_size,x
            sta     progress_current,x
            dex
            bpl     -
            lda     #<export_progress_text
            ldx     #>export_progress_text
            jsr     draw_progress

            jsr     export_close_local
            bcs     export_close_failure
            ; Renaming first is both atomic and avoids treating a missing
            ; destination as a delete failure. If the filesystem refuses to
            ; replace an existing file, remove that file and retry once.
            jsr     export_rename_temporary
            bcc     export_publish_done
            jsr     export_delete_destination
            bcs     export_delete_failure
            jsr     export_rename_temporary
            bcs     export_rename_failure
export_publish_done:
            clc
            rts

export_bad_response:
            lda     #$f8
            sta     mailbox_error
            bra     export_cleanup
export_remote_failure:
            ; mailbox_error already identifies the supervisor failure.
            bra     export_cleanup
export_verify_failure:
            lda     #$ea
            sta     mailbox_error
            bra     export_cleanup
export_close_failure:
            lda     #$eb
            sta     mailbox_error
            bra     export_cleanup
export_delete_failure:
            lda     #$ec
            sta     mailbox_error
            bra     export_cleanup
export_rename_failure:
            lda     #$ed
            sta     mailbox_error
            bra     export_cleanup
export_local_failure:
            lda     #$e9
            sta     mailbox_error
export_cleanup:
            lda     mailbox_error
            sta     transfer_saved_error
            lda     #COMMAND_IMAGE_ABORT
            ldx     #0
            jsr     mailbox_command
            lda     export_stream_open
            beq     export_cleanup_delete
            jsr     export_close_local
export_cleanup_delete:
            lda     export_verified
            bne     export_cleanup_restore
            jsr     export_delete_temporary
export_cleanup_restore:
            lda     transfer_saved_error
            sta     mailbox_error
export_return_error:
            sec
            rts

export_close_local:
            lda     export_stream_open
            beq     export_close_ok
            lda     export_stream
            sta     KARGS_FILE_STREAM
            jsr     KERNEL_FILE_CLOSE
            bcs     export_close_failed
export_wait_close:
            jsr     export_next_event
            lda     EVENT_TYPE
            cmp     #EVENT_FILE_CLOSED
            beq     export_closed
            cmp     #EVENT_FILE_ERROR
            beq     export_close_failed
            bra     export_wait_close
export_closed:
            lda     EVENT_STREAM
            cmp     export_stream
            bne     export_wait_close
            stz     export_stream_open
export_close_ok:
            clc
            rts
export_close_failed:
            stz     export_stream_open
            sec
            rts

export_delete_destination:
            lda     #<EXPORT_DESTINATION
            sta     KARGS_BUF
            lda     #>EXPORT_DESTINATION
            sta     KARGS_BUF+1
            lda     export_destination_length
            sta     KARGS_BUFLEN
            bra     export_delete_path
export_delete_temporary:
            lda     #<EXPORT_TEMPORARY
            sta     KARGS_BUF
            lda     #>EXPORT_TEMPORARY
            sta     KARGS_BUF+1
            lda     export_temporary_length
            sta     KARGS_BUFLEN
export_delete_path:
            lda     local_drive
            sta     KARGS_FILE_DRIVE
            stz     KARGS_FILE_COOKIE
            jsr     KERNEL_FILE_DELETE
            bcs     export_delete_failed
export_wait_delete:
            jsr     export_next_event
            lda     EVENT_TYPE
            cmp     #EVENT_FILE_DELETED
            beq     export_delete_ok
            cmp     #EVENT_FILE_NOT_FOUND
            beq     export_delete_ok
            cmp     #EVENT_FILE_ERROR
            beq     export_delete_failed
            bra     export_wait_delete
export_delete_ok:
            clc
            rts
export_delete_failed:
            sec
            rts

export_rename_temporary:
            lda     local_drive
            sta     KARGS_FILE_DRIVE
            stz     KARGS_FILE_COOKIE
            lda     #<EXPORT_TEMPORARY
            sta     KARGS_BUF
            lda     #>EXPORT_TEMPORARY
            sta     KARGS_BUF+1
            lda     export_temporary_length
            sta     KARGS_BUFLEN
            ; MicroKernel's FAT32 rename implementation resolves the new
            ; name in the source file's directory and requires a bare name;
            ; a full path is rejected as an illegal filename.
            lda     #<EXPORT_BASENAME
            sta     KARGS_EXT
            lda     #>EXPORT_BASENAME
            sta     KARGS_EXT+1
            lda     export_basename_length
            sta     KARGS_EXTLEN
            jsr     KERNEL_FILE_RENAME
            bcs     export_rename_failed
export_wait_rename:
            jsr     export_next_event
            lda     EVENT_TYPE
            cmp     #EVENT_FILE_RENAMED
            beq     export_rename_ok
            cmp     #EVENT_FILE_ERROR
            beq     export_rename_failed
            bra     export_wait_rename
export_rename_ok:
            clc
            rts
export_rename_failed:
            sec
            rts

export_next_event:
            lda     #<event_buffer
            sta     KARGS_EVENT_DEST
            lda     #>event_buffer
            sta     KARGS_EVENT_DEST+1
            jsr     KERNEL_NEXT_EVENT
            bcc     export_event_ready
            jsr     KERNEL_YIELD
            bra     export_next_event
export_event_ready:
            rts

prepare_export_entry:
            lda     catalog_count
            beq     export_entry_invalid
            lda     cursor_index
            sta     catalog_index
            jsr     catalog_get
            bcs     prepare_export_done
            lda     response_buffer+10
            cmp     #SOURCE_SD
            bne     export_entry_invalid
            lda     response_buffer+18
            beq     export_entry_invalid
            cmp     #192
            bcs     export_entry_invalid
            sta     export_path_length
            tay
            dey
prepare_export_path_loop:
            lda     response_buffer+19,y
            sta     EXPORT_PATH,y
            dey
            bpl     prepare_export_path_loop
            ldy     export_path_length
            lda     #0
            sta     EXPORT_PATH,y

            ldx     export_path_length
            dex
prepare_export_basename_scan:
            lda     EXPORT_PATH,x
            cmp     #'/'
            beq     prepare_export_basename_found
            dex
            bpl     prepare_export_basename_scan
            ldx     #$ff
prepare_export_basename_found:
            inx
            stx     export_basename_start
            lda     export_path_length
            sec
            sbc     export_basename_start
            beq     export_entry_invalid
            cmp     #LOCAL_ENTRY_NAME_MAX+1
            bcs     export_entry_invalid
            sta     export_basename_length
            ldy     #0
prepare_export_basename_loop:
            cpy     export_basename_length
            beq     prepare_export_basename_done
            lda     EXPORT_PATH,x
            sta     EXPORT_BASENAME,y
            inx
            iny
            bra     prepare_export_basename_loop
prepare_export_basename_done:
            lda     #0
            sta     EXPORT_BASENAME,y

            jsr     local_path_length
            sta     export_directory_length
            clc
            adc     export_basename_length
            sta     export_destination_length
            clc
            adc     #6                  ; leading dot plus .part
            cmp     #128
            bcs     export_entry_invalid
            sta     export_temporary_length

            ldx     #0
prepare_export_prefix_loop:
            cpx     export_directory_length
            beq     prepare_export_destination_name
            lda     local_path,x
            sta     EXPORT_DESTINATION,x
            sta     EXPORT_TEMPORARY,x
            inx
            bra     prepare_export_prefix_loop
prepare_export_destination_name:
            ldy     #0
prepare_export_destination_loop:
            cpy     export_basename_length
            beq     prepare_export_destination_done
            lda     EXPORT_BASENAME,y
            sta     EXPORT_DESTINATION,x
            inx
            iny
            bra     prepare_export_destination_loop
prepare_export_destination_done:
            stz     EXPORT_DESTINATION,x

            ldx     export_directory_length
            lda     #'.'
            sta     EXPORT_TEMPORARY,x
            inx
            ldy     #0
prepare_export_temporary_name:
            cpy     export_basename_length
            beq     prepare_export_temporary_suffix
            lda     EXPORT_BASENAME,y
            sta     EXPORT_TEMPORARY,x
            inx
            iny
            bra     prepare_export_temporary_name
prepare_export_temporary_suffix:
            ldy     #0
-           lda     export_part_suffix,y
            beq     prepare_export_temporary_done
            sta     EXPORT_TEMPORARY,x
            inx
            iny
            bra     -
prepare_export_temporary_done:
            stz     EXPORT_TEMPORARY,x
            clc
prepare_export_done:
            rts
export_entry_invalid:
            lda     #$e8
            sta     mailbox_error
            sec
            rts

prepare_delete_entry:
            lda     catalog_count
            beq     delete_entry_invalid
            lda     cursor_index
            sta     catalog_index
            jsr     catalog_get
            bcs     delete_entry_done
            lda     response_buffer+10
            cmp     #SOURCE_SD
            bne     delete_entry_invalid
            lda     response_buffer+18
            beq     delete_entry_invalid
            cmp     #192
            bcs     delete_entry_invalid
            sta     delete_path_length
            tay
            dey
prepare_delete_path_loop:
            lda     response_buffer+19,y
            sta     delete_path,y
            dey
            bpl     prepare_delete_path_loop
            ldy     delete_path_length
            lda     #0
            sta     delete_path,y
            clc
delete_entry_done:
            rts
delete_entry_invalid:
            lda     #$e7
            sta     mailbox_error
            sec
            rts

request_delete_entry:
            jsr     prepare_nonce
            lda     context
            sta     tx_buffer+4
            lda     delete_path_length
            sta     tx_buffer+5
            tay
            dey
request_delete_path_loop:
            lda     delete_path,y
            sta     tx_buffer+6,y
            dey
            bpl     request_delete_path_loop
            lda     delete_path_length
            clc
            adc     #6
            tax
            lda     #COMMAND_DELETE_SD
            jsr     mailbox_command_response
            bcs     request_delete_done
            lda     response_length
            cmp     #5
            bcc     response_short
            clc
request_delete_done:
            rts

read_copy_progress_response:
            lda     response_buffer+4
            sta     copy_state
            lda     response_buffer+5
            sta     copy_error
            ldx     #3
-           lda     response_buffer+6,x
            sta     progress_current,x
            lda     response_buffer+10,x
            sta     progress_total,x
            dex
            bpl     -
            lda     copy_state
            cmp     #COPY_STATE_ERASING
            bcc     copy_progress_bad_state
            cmp     #COPY_STATE_FAILED+1
            bcs     copy_progress_bad_state
            clc
            rts
copy_progress_bad_state:
            lda     #$f8
            sta     mailbox_error
            sec
            rts

draw_copy_progress:
            lda     copy_state
            cmp     #COPY_STATE_ERASING
            bne     +
            lda     #<flash_erase_progress_text
            ldx     #>flash_erase_progress_text
            jmp     draw_progress
+           cmp     #COPY_STATE_WRITING
            bne     +
            lda     #<flash_write_progress_text
            ldx     #>flash_write_progress_text
            jmp     draw_progress
+           cmp     #COPY_STATE_FINALIZING
            bne     +
            lda     #<flash_finalize_progress_text
            ldx     #>flash_finalize_progress_text
            jmp     draw_progress
+           cmp     #COPY_STATE_DONE
            bne     +
            lda     #<flash_done_progress_text
            ldx     #>flash_done_progress_text
            jmp     draw_progress
+           lda     #<flash_failed_progress_text
            ldx     #>flash_failed_progress_text
            jmp     draw_progress

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
            lda     MAILBOX_REMOTE_STATUS
            and     #MAILBOX_REMOTE_SD
            sta     manager_sd_available
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
            lda     #<event_buffer
            sta     KARGS_EVENT_DEST
            lda     #>event_buffer
            sta     KARGS_EVENT_DEST+1
            jsr     KERNEL_NEXT_EVENT
            bcc     +
            jsr     KERNEL_YIELD
            bra     wait_key
+           lda     EVENT_TYPE
            cmp     #EVENT_KEY_PRESSED
            bne     wait_key
            lda     EVENT_KEY_RAW
            rts

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
decimal_powers_lo:  .byte <10000,<1000,<100,<10,<1
decimal_powers_hi:  .byte >10000,>1000,>100,>10,>1
banner_text:        .text $0a,"K2 FPGA Manager",$0a,0
context_text:       .text "Catalog context: ",0
running_text:       .text "Running: context ",0
offline_text:       .text "RP2040 supervisor is offline.",$0a,0
version_text:       .text "Unsupported supervisor version $",0
error_text:         .text "Supervisor command failed, error",0
exit_text:          .text "Press any key to reset the system.",0
ui_title_text:      .text "Core Catalog",0
ui_local_title_text:.text "Local SD Browser",0
ui_help_title_text: .text "Keyboard Help",0
ui_boot_log_title_text: .text "RP2040 Boot Log",0
ui_columns_text:    .text ">*+ Source Core image",0
ui_local_columns_text: .text "> Local SD directory / FPGA image",0
help_columns_text:  .text "Key controls",0
boot_log_columns_text: .text "RP2040 diagnostics (oldest to newest)",0
local_sd_error_text: .text "Local SD unreadable or unsupported. Use a FAT-formatted card; R retries.",0
manager_sd_unavailable_text: .text "Manager SD is absent. Use F3 on a gzip image to write context flash.",0
boot_log_empty_text:.text "No boot diagnostics were recorded.",0
boot_log_hint_text: .text "Current boot and runtime reconfiguration attempts.",0
help_hint_text:     .text "Press any key to return to the previous manager view.",0
running_once_text:  .text "Running highlighted core once; saved default is unchanged...",0
context_mismatch_text: .text "Cannot run another context. Change DIP switches and restart the K2.",0
booting_text:       .text "Saving as default and reconfiguring...",0
default_saved_text: .text "Default saved; running core is unchanged.",0
restart_supervisor_text: .text "Restarting RP2040 and repeating FPGA loading...",0
restart_computer_text: .text "Restarting the K2...",0
key_bar_text:       .text " F1 Help  Tab Local SD  Enter Run  F3 Flash  F5 Copy  F7 Default  S Save+Run ",0
local_key_bar_text: .text " F1 Help  Tab Catalog  Enter Open  F3 Flash  F5 Copy to RP SD  Bksp Parent ",0
boot_log_key_bar_text: .text " Press any key to return to the manager ",0
local_target_text:  .text "Copy destination: manager SD context ",0
local_no_manager_sd_text: .text "Manager SD absent; direct-flash context ",0
scan_text:          .text "Scanning image and calculating CRC...",0
install_text:       .text "Installing to manager SD; do not power off...",0
install_done_text:  .text "Installed and highlighted in the manager catalog.",0
direct_flash_text:  .text "Erasing context flash, then writing local gzip; do not power off...",0
direct_flash_done_text: .text "Direct flash upload verified; manager SD was not used.",0
direct_flash_unavailable_text: .text "F3 requires a highlighted gzip image no larger than 2 MiB.",0
flash_copy_text:    .text "Copying selected manager-SD gzip to flash; do not power off...",0
flash_copy_done_text: .text "Flash copy verified and catalog refreshed.",0
export_start_text:  .text "Copying manager-SD image to local K2 SD; do not power off...",0
export_done_text:   .text "Export verified on local K2 SD.",0
delete_prompt_text: .text "Delete this image from RP2040 manager SD?",0
delete_confirm_text:.text "Press Y to delete permanently; any other key cancels.",0
delete_cancelled_text: .text "Delete cancelled.",0
delete_done_text:   .text "Image deleted from RP2040 manager SD.",0
delete_unavailable_text: .text "Only manager-SD core images can be deleted.",0
scan_progress_text: .text "Scanning and validating the local image",0
install_progress_text: .text "Copying local image to RP2040 manager SD",0
direct_flash_progress_text: .text "Copying local gzip directly to context flash",0
flash_erase_progress_text: .text "Erasing the replaceable flash slot",0
flash_write_progress_text: .text "Copying manager-SD image to flash",0
flash_finalize_progress_text: .text "Verifying flash and committing metadata",0
flash_done_progress_text: .text "Flash copy complete",0
flash_failed_progress_text: .text "Flash copy failed",0
export_progress_text: .text "Copying RP2040 manager-SD image to local K2 SD",0
progress_separator_text: .text " / ",0
progress_percent_text: .text "%   ",0
progress_kib_text:  .text " KiB",0
progress_scanned_text: .text " KiB scanned",0
autotest_image_name:.text "WildbitsK2_2x_B0C_020200FE_20260818.bin.gz",0
source_auto_text:   .text "AUTO  ",0
source_sd_text:     .text "SD    ",0
source_flash_text:  .text "FLASH ",0
source_golden_text: .text "GOLDEN",0
export_part_suffix: .text ".part",0

ui_help_line_ptrs:
            .word help_line_f1, help_line_f2, help_line_f3, help_line_f5
            .word help_line_f7, help_line_f8, help_line_enter, help_line_tab
            .word help_line_up_down, help_line_left_right, help_line_delete
            .word help_line_s, help_line_r, help_line_quit
help_line_f1:       .text "F1          Show this help screen",0
help_line_f2:       .text "F2          Show the RP2040 boot log",0
help_line_f3:       .text "F3          Copy highlighted gzip core to context flash",0
help_line_f5:       .text "F5          Copy selected image between the two SD cards",0
help_line_f7:       .text "F7          Save highlighted catalog entry as default; do not run",0
help_line_f8:       .text "F8          Restart RP2040 and repeat FPGA loading",0
help_line_enter:    .text "Enter       Catalog: run once; Local: open directory",0
help_line_tab:      .text "Tab         Switch between catalog and local SD",0
help_line_up_down:  .text "Up/Down     Move one entry",0
help_line_left_right: .text "Left/Right  Catalog: context; Local: move one page",0
help_line_delete:   .text "Del/Bksp    Catalog: delete SD image; Local: parent directory",0
help_line_s:        .text "S           Save selected default and run immediately",0
help_line_r:        .text "R           Refresh the current view",0
help_line_quit:     .text "Esc/Q       Restart the K2",0

; SuperBASIC-compatible text palette with the generated logo's requested
; green, cream, and dark trace in entries 3, 6, and 8.
ui_text_palette:
            .dword $ff000000, $ff666666, $ff0000aa, $ff59ff72
            .dword $ffc041ea, $ff874800, $ffffd166, $ff57dbff
            .dword $ff3f3f28, $ffaaaa8a, $ff5555ff, $ff55ff55
            .dword $ffff8ded, $ffff0000, $ffffff55, $ffffffff

; Color IDs from the generated logo become F256 text attributes.  Each logo
; cell uses black as its background; ID 0 is therefore invisible black.
ui_logo_color_attrs:
            .byte $00, $30, $60, $80

            .include "fpga_manager_logo_80x5.inc"

ui_line_lo:
            .for row := 0, row < 60, row += 1
            .byte <(TEXT_BUFFER+row*80)
            .next
ui_line_hi:
            .for row := 0, row < 60, row += 1
            .byte >(TEXT_BUFFER+row*80)
            .next

; ---------------------------------------------------------------------------
; Workspace
; ---------------------------------------------------------------------------

            .align $100
tx_buffer:          .fill 240,0
            .align $100
response_buffer:    .fill 240,0
event_buffer:       .fill 16,0
catalog_generation: .fill 4,0
nonce:              .fill 4,0
context:            .byte 0
catalog_count:      .byte 0
catalog_index:      .byte 0
cursor_index:       .byte 0
selected_index:     .byte 0
selected_source:    .byte 0
running_valid:      .byte 0
running_context:    .byte 0
running_source:     .byte 0
running_name_length:.byte 0
boot_log_count:     .byte 0
boot_log_index:     .byte 0
boot_log_line_length: .byte 0
help_line_index:    .byte 0
ui_entry_index:     .byte 0
ui_entry_source:    .byte 0
ui_entry_flags:     .byte 0
ui_column:          .byte 0
ui_row:             .byte 0
ui_color:           .byte 0
ui_border_left:     .byte 0
ui_border_right:    .byte 0
status_pointer:     .word 0
response_length:    .byte 0
pending_command:    .byte 0
pending_length:     .byte 0
response_command:   .byte 0
response_request_length: .byte 0
mailbox_error:      .byte 0
autotest_result:    .byte 0
running_name:       .fill ENTRY_NAME_CAPACITY,0
view_mode:          .byte 0
local_drive:        .byte 0
local_stream:       .byte 0
local_count:        .byte 0
local_cursor:       .byte 0
local_top:          .byte 0
local_draw_index:   .byte 0
local_loaded:       .byte 0
local_failed:       .byte 0
manager_sd_available: .byte 0
local_event_flags:  .byte 0
local_name_length:  .byte 0
highlight_pending:  .byte 0
transfer_phase:     .byte 0
transfer_stream:    .byte 0
transfer_failed:    .byte 0
transfer_format:    .byte 0
transfer_target:    .byte 0
upload_started:     .byte 0
transfer_retry:     .byte 0
transfer_saved_error: .byte 0
transfer_progress:  .byte 0
export_stream:      .byte 0
export_stream_open: .byte 0
export_verified:    .byte 0
export_path_length: .byte 0
export_basename_start: .byte 0
export_basename_length: .byte 0
export_directory_length: .byte 0
export_destination_length: .byte 0
export_temporary_length: .byte 0
export_write_offset: .byte 0
export_write_remaining: .byte 0
copy_state:         .byte 0
copy_error:         .byte 0
progress_activity:  .byte 0
progress_percent:   .byte 0
progress_filled:    .byte 0
progress_ratio_limit: .byte 0
progress_ratio_result: .byte 0
progress_label:     .word 0
progress_current:   .fill 4,0
progress_total:     .fill 4,0
progress_work:      .fill 4,0
decimal_value:      .fill 2,0
decimal_started:    .byte 0
decimal_digit:      .byte 0
delete_path_length: .byte 0
delete_path:        .fill 192,0
chunk_length:       .byte 0
header_count:       .byte 0
begin_length:       .byte 0
filename_length:    .byte 0
install_name_length:.byte 0
file_size:          .fill 4,0
uploaded_size:      .fill 4,0
expected_upload_size: .fill 4,0
remote_upload_size: .fill 4,0
crc_value:          .fill 4,0
image_header:       .fill 10,0
file_tail:          .fill 8,0
local_path:         .fill 128,0
filename:           .fill 128,0
install_name:       .fill LOCAL_ENTRY_NAME_MAX+1,0
local_trash:        .fill 128,0
begin_payload:      .fill LOCAL_ENTRY_NAME_MAX+12,0
io_buffer:          .fill MAX_PAYLOAD,0

            .cerror * > $c000, "K2 FPGA Manager overlaps the video buffer"
