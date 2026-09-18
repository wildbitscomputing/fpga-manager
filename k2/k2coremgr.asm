; K2 Core Manager - inspect and select RP2040 FPGA boot images.
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
CORE_MGR_AUTOTEST_CONTEXT = 0
CORE_MGR_LOCAL_DRIVE = 0
CORE_MGR_KUP = 0
            .endweak

KERNEL_NEXT_EVENT       = $ff00
KERNEL_READ_DATA        = $ff04
KERNEL_READ_EXT         = $ff08
KERNEL_YIELD            = $ff0c
KERNEL_PUTCH            = $ff10
KERNEL_CHDIR            = $ff1c
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
EVENT_KEY_RELEASED      = $0a
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
KEY_BREAK               = $bc            ; K2 RUN/STOP key
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
COMMAND_FIRMWARE_INFO   = $19
COMMAND_FIRMWARE_BEGIN  = $1a
COMMAND_FIRMWARE_DATA   = $1b
COMMAND_FIRMWARE_END    = $1c
COMMAND_FIRMWARE_ABORT  = $1d
COMMAND_FIRMWARE_APPLY  = $1e
COMMAND_IMAGE_BEGIN     = $02
COMMAND_IMAGE_DATA      = $03
COMMAND_IMAGE_END       = $04
COMMAND_IMAGE_ABORT     = $05
COMMAND_IMAGE_STATUS    = $07

TARGET_SD_NAMED         = 3
TARGET_FLASH_GZIP       = 2
TARGET_FIRMWARE         = 4
FORMAT_RAW              = 1
FORMAT_GZIP             = 2
FORMAT_FIRMWARE         = 3
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
; 80 x 60 Wildbits UI. Attribute nibbles are foreground/background palette
; indices respectively; palette entry 0 is the dark-blue canvas.
UI_COLOR_NORMAL         = $20            ; off-white on blue
UI_COLOR_LABEL          = $10            ; cyan on blue
UI_COLOR_ACCENT         = $30            ; amber on blue
UI_COLOR_ORANGE         = $40            ; orange on blue
UI_COLOR_SUCCESS        = $50            ; green on blue
UI_COLOR_ERROR          = $60            ; red on blue
UI_COLOR_DIM            = $70            ; muted blue on blue
UI_COLOR_HIGHLIGHT      = $38            ; amber on selection blue
UI_COLOR_SUCCESS_SELECTED = $58          ; green on selection blue
UI_COLOR_ORANGE_SELECTED  = $48          ; orange on selection blue
UI_COLOR_FRAME          = UI_COLOR_LABEL
UI_COLOR_KEY_BAR        = UI_COLOR_ACCENT
; Determinate progress uses green foreground glyphs for the completed side
; and plain spaces on the selection-blue background for the remainder.
UI_COLOR_PROGRESS_EMPTY  = $08
UI_COLOR_PROGRESS_ACTIVE = UI_COLOR_SUCCESS_SELECTED
KEY_BAR_TOGGLE          = $01
UI_SCREEN_ROWS          = 60
UI_HEADER_LINE          = 2
UI_STATUS_LINE          = 5
UI_PATH_LINE            = 7
UI_FRAME_TOP_LINE       = 10
UI_COLUMNS_LINE         = 11
UI_SEPARATOR_LINE       = 12
UI_BOX_LEFT             = 3
UI_BOX_RIGHT            = 76
UI_LIST_LINE            = 13
UI_MAX_ENTRIES          = 39
UI_BOTTOM_LINE          = UI_LIST_LINE+UI_MAX_ENTRIES
UI_STATUS_MESSAGE_LINE  = 54
UI_KEY_LINE             = 56
UI_KEY_LINE_2           = 57
UI_KEY_LINE_3           = 59
UI_HELP_LEFT            = 5
UI_HELP_RIGHT           = 74
UI_HELP_TOP             = 15
UI_HELP_BOTTOM          = 47
UI_MODAL_LEFT           = 10
UI_MODAL_RIGHT          = 69
UI_MODAL_TOP            = 20
UI_MODAL_BOTTOM         = 36
UI_PROGRESS_TITLE_LINE  = 22
UI_PROGRESS_NAME_LINE   = 25
UI_PROGRESS_STATUS_LINE = 28
UI_PROGRESS_BAR_LINE    = 31
UI_PROGRESS_HINT_LINE   = 34
UI_PROGRESS_BAR_WIDTH   = 31
LOCAL_PAGE_JUMP         = 10
PROGRESS_UPDATE_MASK    = $07            ; redraw every eight transfer chunks

PROGRESS_KIND_SCAN      = 1
PROGRESS_KIND_MANAGER   = 2
PROGRESS_KIND_FLASH     = 3
PROGRESS_KIND_EXPORT    = 4
PROGRESS_KIND_FIRMWARE  = 5

COPY_STATE_ERASING      = 1
COPY_STATE_WRITING      = 2
COPY_STATE_FINALIZING   = 3
COPY_STATE_DONE         = 4
COPY_STATE_FAILED       = 5

GLYPH_CURSOR            = 250            ; small right triangle
GLYPH_DEFAULT           = 222            ; check mark
GLYPH_BOOTED            = 180            ; filled circle
GLYPH_SEPARATOR         = 182            ; centered dot
GLYPH_PROGRESS_FIRST    = 134            ; 1/8 filled, left to right
GLYPH_PROGRESS_FULL     = 7              ; solid block

BOX_TL                  = 160
BOX_TR                  = 161
BOX_BL                  = 162
BOX_BR                  = 163
BOX_H                   = 150
BOX_V                   = 130
BOX_TEE_LEFT            = 154
BOX_TEE_TOP             = 155
BOX_CROSS               = 156
BOX_TEE_BOTTOM          = 157
BOX_TEE_RIGHT           = 158

ENTRY_SIZE              = 64
ENTRY_SOURCE            = 0
ENTRY_FLAGS             = 1
ENTRY_SIZE_BYTES        = 2
ENTRY_NAME_LENGTH       = 6
ENTRY_NAME               = 7
ENTRY_NAME_CAPACITY      = ENTRY_SIZE-ENTRY_NAME

VIEW_CATALOG            = 0
VIEW_LOCAL              = 1
; The local directory cache occupies the otherwise-unused RAM immediately
; below the PGZ load address at $8000.  Keep the count below 256 because the
; cursor and entry indices are bytes.
LOCAL_ENTRY_BUFFER      = $4000
LOCAL_ENTRY_SIZE        = 64
LOCAL_ENTRY_FLAGS       = 0
LOCAL_ENTRY_NAME        = 1
LOCAL_ENTRY_NAME_MAX    = 62
LOCAL_MAX_ENTRIES       = 255
LOCAL_FLAG_DIRECTORY    = $01
LOCAL_FLAG_IMAGE        = $02
LOCAL_FLAG_FIRMWARE     = $04

            .cerror LOCAL_ENTRY_BUFFER + LOCAL_ENTRY_SIZE * LOCAL_MAX_ENTRIES > $8000, "Local directory cache overlaps the PGZ image"

; Large work areas live below the PGZ image. Exporting is available only in
; catalog view, and the local directory is reread afterward.
EXPORT_PATH             = $2000
EXPORT_DESTINATION      = $20c0
EXPORT_TEMPORARY        = $2140
EXPORT_BASENAME         = $21c0
EXPORT_BACKUP           = $2240
EXPORT_BACKUP_NAME      = $22c0
tx_buffer               = $2400
response_buffer         = $2500
io_buffer               = $2600
local_trash             = $2700
delete_path             = $2800
local_path              = $2900
filename                = $2980
install_name            = $2a00
begin_payload           = $2a40
CRC_TABLE0              = $3000
CRC_TABLE1              = $3100
CRC_TABLE2              = $3200
CRC_TABLE3              = $3300
CATALOG_ENTRIES         = $3400

*           = $8000

            .if CORE_MGR_KUP != 0
            .byte   $f2,$56             ; KUP signature
            .byte   2                   ; two contiguous 8 KiB blocks
            .byte   4                   ; mount in slots 4-5 at $8000-$bfff
            .word   RUN
            .byte   1                   ; header version
            .fill   3,0
            .text   "coremgr",0
            .text   0                   ; no arguments
            .text   "K2 FPGA Core Manager",0
            .endif

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
            lda     #0                  ; context 1 until boot status says otherwise
            .endif
            sta     context
            stz     view_mode
            lda     #CORE_MGR_LOCAL_DRIVE
            sta     local_drive
            lda     #'/'
            sta     local_path
            stz     local_path+1
            stz     local_loaded
            stz     catalog_refreshing
            stz     highlight_found
            lda     #$ff
            sta     highlight_source

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
            ; RP2040 context-1 catalog.
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
            ; Headless manufacturing/development check: catalog context 1 and
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
            beq     delete_key
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
            cmp     #8                  ; DEL is reported as Backspace
            beq     delete_key
            cmp     #127
            beq     delete_key
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
            cmp     #'u'
            beq     update_firmware_highlighted
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
            jsr     adjust_catalog_top
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
            jsr     adjust_catalog_top
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
            jsr     wait_break_key
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
            jsr     wait_break_key
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
            ; Refresh the same selected directory now, while local_path still
            ; identifies the export target. Tab can then display the new file
            ; without relying on a deferred/stale directory cache refresh.
            jsr     read_local_directory
            bcs     export_highlighted_failed
            jsr     highlight_exported_local_file
            ; Exporting does not alter the RP2040 catalog. Keep its existing
            ; cursor and scroll position rather than attempting to match the
            ; local destination path against a manager-SD catalog entry.
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
delete_confirmation_key:
            jsr     wait_key
            lda     EVENT_KEY_ASCII
            ora     #$20
            cmp     #'y'
            beq     delete_confirmed
            lda     EVENT_KEY_RAW
            cmp     #KEY_BREAK
            beq     delete_cancelled
            cmp     #KEY_ESC             ; optional external-keyboard alias
            bne     delete_confirmation_key
delete_cancelled:
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
            bcc     copy_local_completed
            lda     transfer_cancelled
            beq     command_failure
            jsr     draw_local_screen
            lda     #<scan_cancelled_text
            ldx     #>scan_cancelled_text
            jsr     draw_status
            jmp     menu_loop
copy_local_completed:
            lda     #1
            sta     highlight_pending
            stz     highlight_found
            lda     #SOURCE_SD
            sta     highlight_source
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
            lda     transfer_cancelled
            beq     local_flash_error
            jsr     draw_local_screen
            lda     #<scan_cancelled_text
            ldx     #>scan_cancelled_text
            jsr     draw_status
            jmp     menu_loop
local_flash_error:
            lda     mailbox_error
            cmp     #$e6
            bne     command_failure
local_flash_unavailable:
            jsr     draw_local_screen
            lda     #<direct_flash_unavailable_text
            ldx     #>direct_flash_unavailable_text
            jsr     draw_status
            jmp     menu_loop

update_firmware_highlighted:
            lda     view_mode
            beq     firmware_update_wrong_view
            ; A verified pending candidate survives returning to the browser.
            ; Offer to apply it again without rescanning the source file.
            jsr     prepare_nonce
            lda     #COMMAND_FIRMWARE_INFO
            ldx     #4
            jsr     mailbox_command_response
            bcs     command_failure
            jsr     firmware_require_status
            bcs     command_failure
            lda     response_buffer+11
            cmp     #4                  ; READY
            beq     firmware_update_confirm
            lda     local_count
            beq     firmware_update_unavailable
            jsr     local_entry_pointer
            ldy     #LOCAL_ENTRY_FLAGS
            lda     (ZP_POINTER),y
            and     #LOCAL_FLAG_FIRMWARE
            beq     firmware_update_unavailable
            jsr     prepare_transfer_filename
            bcs     command_failure
            lda     #TARGET_FIRMWARE
            sta     transfer_target
            jsr     install_prepared_entry
            bcs     firmware_update_failed
firmware_update_confirm:
            jsr     draw_local_screen
            jsr     draw_firmware_apply_confirmation
firmware_update_confirmation_key:
            jsr     wait_key
            lda     EVENT_KEY_ASCII
            ora     #$20
            cmp     #'y'
            beq     firmware_update_apply
            lda     EVENT_KEY_RAW
            cmp     #KEY_BREAK
            beq     firmware_update_cancelled
            cmp     #KEY_ESC
            bne     firmware_update_confirmation_key
firmware_update_cancelled:
            jsr     draw_local_screen
            lda     #<firmware_staged_text
            ldx     #>firmware_staged_text
            jsr     draw_status
            jmp     menu_loop
firmware_update_apply:
            jsr     prepare_nonce
            lda     #COMMAND_FIRMWARE_APPLY
            ldx     #4
            jsr     mailbox_command_response
            bcs     command_failure
            lda     #<firmware_apply_text
            ldx     #>firmware_apply_text
            jsr     draw_status
            jmp     boot_wait
firmware_update_failed:
            lda     transfer_cancelled
            beq     command_failure
            jsr     draw_local_screen
            lda     #<scan_cancelled_text
            ldx     #>scan_cancelled_text
            jsr     draw_status
            jmp     menu_loop
firmware_update_unavailable:
            jsr     draw_local_screen
firmware_update_wrong_view:
            lda     #<firmware_update_unavailable_text
            ldx     #>firmware_update_unavailable_text
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
            lda     EVENT_KEY_RAW
            sta     restart_key_raw
            lda     #<restart_computer_text
            ldx     #>restart_computer_text
            jsr     draw_status
            jsr     wait_restart_key_release
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
            stz     catalog_top
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
            lda     highlight_source
            cmp     #$ff
            beq     load_catalog_highlight_name
            cmp     response_buffer+10
            bne     load_catalog_next
load_catalog_highlight_name:
            jsr     catalog_matches_local_filename
            bcc     load_catalog_next
            lda     catalog_index
            sta     cursor_index
            lda     #1
            sta     highlight_found
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
            lda     #$ff
            sta     highlight_source
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
            jsr     adjust_catalog_top
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
            stz     local_truncated
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
            bcs     local_directory_truncated
            lda     local_name_length
            beq     local_directory_discard
            cmp     #LOCAL_ENTRY_NAME_MAX+1
            bcc     local_directory_store
            lda     #1
            sta     local_truncated
            bra     local_directory_discard
local_directory_store:
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
+           jsr     local_filename_is_firmware
            bcc     +
            lda     #LOCAL_FLAG_FIRMWARE
            bra     local_store_flags
+           lda     #0
local_store_flags:
            ldy     #LOCAL_ENTRY_FLAGS
            sta     (ZP_POINTER),y
            inc     local_count
            jsr     local_directory_read_next
            bra     local_directory_events

local_directory_truncated:
            lda     #1
            sta     local_truncated
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

; Select the just-exported basename in the refreshed local directory cache so
; Tab makes the result visible even when the directory spans several pages.
highlight_exported_local_file:
            stz     local_draw_index
highlight_exported_local_loop:
            lda     local_draw_index
            cmp     local_count
            bcs     highlight_exported_local_done
            jsr     local_entry_pointer_a
            ldy     #LOCAL_ENTRY_NAME
            ldx     #0
highlight_exported_local_compare:
            lda     (ZP_POINTER),y
            cmp     EXPORT_BASENAME,x
            bne     highlight_exported_local_next
            cmp     #0
            beq     highlight_exported_local_found
            inx
            iny
            bra     highlight_exported_local_compare
highlight_exported_local_next:
            inc     local_draw_index
            bra     highlight_exported_local_loop
highlight_exported_local_found:
            lda     local_draw_index
            sta     local_cursor
            jsr     adjust_local_top
highlight_exported_local_done:
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

; ZP_POINTER addresses the flags byte and the NUL-terminated name follows it.
local_filename_is_firmware:
            lda     local_name_length
            cmp     #5
            bcc     local_not_firmware
            tay
            lda     (ZP_POINTER),y
            ora     #$20
            cmp     #'w'
            bne     local_not_firmware
            dey
            lda     (ZP_POINTER),y
            ora     #$20
            cmp     #'f'
            bne     local_not_firmware
            dey
            lda     (ZP_POINTER),y
            ora     #$20
            cmp     #'2'
            bne     local_not_firmware
            dey
            lda     (ZP_POINTER),y
            ora     #$20
            cmp     #'k'
            bne     local_not_firmware
            dey
            lda     (ZP_POINTER),y
            cmp     #'.'
            bne     local_not_firmware
            sec
            rts
local_not_firmware:
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

adjust_catalog_top:
            lda     cursor_index
            cmp     catalog_top
            bcs     +
            sta     catalog_top
            rts
+           sec
            sbc     catalog_top
            cmp     #UI_MAX_ENTRIES
            bcc     +
            lda     cursor_index
            sec
            sbc     #UI_MAX_ENTRIES-1
            sta     catalog_top
+           rts

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
            sta     local_append_base_length
            stz     local_append_name_length
            ldy     #LOCAL_ENTRY_NAME
local_append_measure_name:
            lda     (ZP_POINTER),y
            beq     local_append_measure_done
            inc     local_append_name_length
            iny
            bra     local_append_measure_name
local_append_measure_done:
            lda     local_append_base_length
            tax
            beq     local_append_measure_name_only
            lda     local_path-1,x
            cmp     #'/'
            beq     local_append_measure_name_only
            inx
local_append_measure_name_only:
            txa
            clc
            adc     local_append_name_length
            adc     #1                  ; trailing slash; NUL occupies next byte
            cmp     #128
            bcs     local_path_too_long

            ldx     local_append_base_length
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
            stz     transfer_cancelled
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
            cmp     #EVENT_KEY_PRESSED
            beq     transfer_key_pressed
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

; Validation is read-only and can be cancelled safely. Once the second pass
; starts changing manager SD or flash state, input remains deliberately locked.
transfer_key_pressed:
            lda     transfer_phase
            bne     transfer_event_loop
            lda     transfer_stream
            beq     transfer_event_loop
            lda     EVENT_KEY_RAW
            cmp     #KEY_BREAK
            beq     transfer_cancel_scan
            cmp     #KEY_ESC             ; optional external-keyboard alias
            bne     transfer_event_loop
transfer_cancel_scan:
            lda     #1
            sta     transfer_cancelled
            sta     transfer_failed
            jmp     transfer_close_file

transfer_opened:
            lda     EVENT_STREAM
            sta     transfer_stream
            lda     transfer_phase
            beq     transfer_request_next
            lda     transfer_target
            cmp     #TARGET_FIRMWARE
            beq     transfer_opened_firmware
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

transfer_opened_firmware:
            lda     #<firmware_stage_text
            ldx     #>firmware_stage_text
            jsr     draw_status
            jsr     prepare_nonce
            ldx     #3
-           lda     file_size,x
            sta     tx_buffer+4,x
            dex
            bpl     -
            lda     #1
            sta     upload_started
            lda     #COMMAND_FIRMWARE_BEGIN
            ldx     #8
            jsr     mailbox_command_response
            bcs     transfer_mailbox_failure
            jsr     firmware_require_status
            bcs     transfer_mailbox_failure
            lda     response_buffer+11
            cmp     #1                  ; MANIFEST
            bne     transfer_sync_failure
            jmp     transfer_request_next

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
            and     #PROGRESS_UPDATE_MASK
            bne     transfer_request_next
            jsr     draw_scan_progress
            bra     transfer_request_next

transfer_upload_data:
            lda     transfer_target
            cmp     #TARGET_FIRMWARE
            beq     transfer_firmware_data
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
            and     #PROGRESS_UPDATE_MASK
            bne     transfer_progress_resync_check
            jsr     draw_install_progress
transfer_progress_resync_check:
            lda     transfer_progress
            and     #$3f
            bne     transfer_request_next
            jsr     transfer_resync_mailbox
            bcs     transfer_mailbox_failure
            bra     transfer_request_next

transfer_firmware_data:
            ldx     #3
-           lda     uploaded_size,x
            sta     tx_buffer+4,x
            dex
            bpl     -
            ldy     #0
transfer_firmware_copy_chunk:
            cpy     chunk_length
            beq     transfer_firmware_chunk_ready
            lda     io_buffer,y
            sta     tx_buffer+8,y
            iny
            bra     transfer_firmware_copy_chunk
transfer_firmware_chunk_ready:
            jsr     build_expected_upload_size
            stz     transfer_retry
transfer_firmware_data_retry:
            jsr     prepare_nonce
            lda     chunk_length
            clc
            adc     #8
            tax
            lda     #COMMAND_FIRMWARE_DATA
            jsr     mailbox_command_response
            bcs     transfer_firmware_data_recover
            jsr     firmware_require_status
            bcs     transfer_firmware_data_recover
            jsr     firmware_response_matches_expected
            bcc     transfer_firmware_data_accepted
transfer_firmware_data_recover:
            inc     transfer_retry
            lda     transfer_retry
            cmp     #8
            bcs     transfer_mailbox_failure
            jsr     firmware_recover_data_position
            bcs     transfer_firmware_data_recover
            cmp     #1                  ; reply lost after chunk was accepted
            beq     transfer_firmware_data_accepted
            bra     transfer_firmware_data_retry
transfer_firmware_data_accepted:
            ldx     #3
-           lda     expected_upload_size,x
            sta     uploaded_size,x
            dex
            bpl     -
            jsr     draw_firmware_receive_progress
            lda     response_buffer+11
            cmp     #2                  ; ERASING
            bne     transfer_firmware_resync_check
            jsr     firmware_wait_for_payload
            bcs     transfer_mailbox_failure
transfer_firmware_resync_check:
            inc     transfer_progress
            lda     transfer_progress
            and     #$3f
            bne     transfer_request_next
            jsr     transfer_resync_firmware
            bcs     transfer_mailbox_failure

transfer_request_next:
            lda     transfer_stream
            sta     KARGS_FILE_STREAM
            lda     transfer_phase
            beq     transfer_request_full_chunk
            lda     transfer_target
            cmp     #TARGET_FIRMWARE
            bne     transfer_request_full_chunk
            jsr     firmware_next_read_length
            bra     transfer_request_length_ready
transfer_request_full_chunk:
            lda     #MAX_PAYLOAD
transfer_request_length_ready:
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
            lda     transfer_target
            cmp     #TARGET_FIRMWARE
            beq     transfer_firmware_end
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
            bra     transfer_close_file
transfer_firmware_end:
            jsr     prepare_nonce
            lda     #COMMAND_FIRMWARE_END
            ldx     #4
            jsr     mailbox_command_response
            bcs     transfer_mailbox_failure
            jsr     firmware_require_status
            bcs     transfer_mailbox_failure
            lda     response_buffer+11
            cmp     #4                  ; READY
            bne     transfer_sync_failure
            stz     upload_started
            jsr     draw_firmware_ready_progress
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
            lda     transfer_target
            cmp     #TARGET_FIRMWARE
            beq     transfer_draw_firmware_progress
            jsr     draw_install_progress
            bra     transfer_reopen_file
transfer_draw_firmware_progress:
            jsr     draw_firmware_receive_progress
transfer_reopen_file:
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
            lda     transfer_target
            cmp     #TARGET_FIRMWARE
            bne     abort_legacy_upload
            jsr     prepare_nonce
            lda     #COMMAND_FIRMWARE_ABORT
            ldx     #4
            jsr     mailbox_command_response
            bra     +
abort_legacy_upload:
            lda     #COMMAND_IMAGE_ABORT
            ldx     #0
            jsr     mailbox_command
+           rts

; The FPGA transport sequence is eight bits wide. Reset its local transport
; before it can wrap, then prove the RP2040 still has the exact accepted byte
; count. IMAGE_ABORT/IMAGE_BEGIN are intentionally not involved, so the
; transactional destination file remains open across this re-sync.
transfer_resync_mailbox:
            stz     MMU_IO_CTRL
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

transfer_resync_firmware:
            stz     MMU_IO_CTRL
            lda     #(MAILBOX_CONTROL_ENABLE | MAILBOX_CONTROL_CLEAR | MAILBOX_CONTROL_RESET)
            sta     MAILBOX_CONTROL
            lda     #MAILBOX_CONTROL_ENABLE
            sta     MAILBOX_CONTROL
            jsr     mailbox_wait_online
            bcs     transfer_resync_failed
            jsr     mailbox_delay
            jsr     prepare_nonce
            lda     #COMMAND_FIRMWARE_INFO
            ldx     #4
            jsr     mailbox_command_response
            bcs     transfer_resync_failed
            jsr     firmware_require_status
            bcs     transfer_resync_failed
            jsr     firmware_response_matches_uploaded
            bcs     transfer_resync_failed
            clc
            rts

firmware_require_status:
            lda     response_length
            cmp     #34
            bcc     firmware_bad_response
            clc
            rts
firmware_bad_response:
            lda     #$fa
            sta     mailbox_error
            sec
            rts

firmware_response_matches_expected:
            ldx     #3
-           lda     response_buffer+14,x
            cmp     expected_upload_size,x
            bne     firmware_position_bad
            dex
            bpl     -
            clc
            rts
firmware_response_matches_uploaded:
            ldx     #3
-           lda     response_buffer+14,x
            cmp     uploaded_size,x
            bne     firmware_position_bad
            dex
            bpl     -
            clc
            rts
firmware_position_bad:
            lda     #$fc
            sta     mailbox_error
            sec
            rts

; Recover a FIRMWARE_DATA transaction whose pipelined response was lost.
; The RP2040 receiver is offset-addressed, so its reported position proves
; whether the chunk was committed without ever writing it twice.
; Returns A=1 if the expected position was committed, A=0 if the original
; position is still current and the caller should resend, or carry set when
; the bridge/status query itself could not be recovered.
firmware_recover_data_position:
            stz     MMU_IO_CTRL
            lda     #(MAILBOX_CONTROL_ENABLE | MAILBOX_CONTROL_CLEAR | MAILBOX_CONTROL_RESET)
            sta     MAILBOX_CONTROL
            lda     #MAILBOX_CONTROL_ENABLE
            sta     MAILBOX_CONTROL
            jsr     mailbox_wait_online
            bcs     firmware_recover_position_failed
            jsr     mailbox_delay
            jsr     prepare_nonce
            lda     #COMMAND_FIRMWARE_INFO
            ldx     #4
            jsr     mailbox_command_response
            bcs     firmware_recover_position_failed
            jsr     firmware_require_status
            bcs     firmware_recover_position_failed
            lda     response_buffer+11
            cmp     #3                  ; PAYLOAD
            bne     firmware_recover_position_failed
            ldx     #3
firmware_recover_expected_loop:
            lda     response_buffer+14,x
            cmp     expected_upload_size,x
            bne     firmware_recover_check_uploaded
            dex
            bpl     firmware_recover_expected_loop
            lda     #1
            clc
            rts
firmware_recover_check_uploaded:
            ldx     #3
firmware_recover_uploaded_loop:
            lda     response_buffer+14,x
            cmp     uploaded_size,x
            bne     firmware_recover_position_failed
            dex
            bpl     firmware_recover_uploaded_loop
            lda     #0
            clc
            rts
firmware_recover_position_failed:
            lda     #$fc
            sta     mailbox_error
            sec
            rts

firmware_wait_for_payload:
            jsr     read_firmware_progress_response
            jsr     draw_firmware_erase_progress
firmware_wait_payload_loop:
            jsr     prepare_nonce
            lda     #COMMAND_FIRMWARE_INFO
            ldx     #4
            jsr     mailbox_command_response
            bcs     firmware_wait_payload_error
            jsr     firmware_require_status
            bcs     firmware_wait_payload_error
            lda     response_buffer+11
            cmp     #3                  ; PAYLOAD
            beq     firmware_wait_payload_done
            cmp     #2                  ; ERASING
            bne     firmware_receiver_failed
            jsr     read_firmware_progress_response
            jsr     draw_firmware_erase_progress
            bra     firmware_wait_payload_loop
firmware_wait_payload_done:
            jsr     firmware_response_matches_uploaded
            rts
firmware_receiver_failed:
            lda     response_buffer+12
            ora     #$d0
            sta     mailbox_error
firmware_wait_payload_error:
            sec
            rts

read_firmware_progress_response:
            ldx     #3
-           lda     response_buffer+18,x
            sta     progress_current,x
            lda     response_buffer+22,x
            sta     progress_total,x
            dex
            bpl     -
            rts

firmware_next_read_length:
            lda     uploaded_size+3
            ora     uploaded_size+2
            bne     firmware_full_read
            lda     uploaded_size+1
            cmp     #$10
            bcs     firmware_full_read
            cmp     #$0f
            bcc     firmware_full_read
            lda     uploaded_size
            cmp     #$18
            bcc     firmware_full_read
            eor     #$ff
            inc     a
            rts
firmware_full_read:
            lda     #232
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
            jsr     transfer_filename_is_firmware
            bcc     prepare_path_check_gzip
            lda     #FORMAT_FIRMWARE
            bra     prepare_path_format_done
prepare_path_check_gzip:
            jsr     transfer_filename_is_gzip
            lda     #FORMAT_RAW
            bcc     +
            lda     #FORMAT_GZIP
+
prepare_path_format_done:
            sta     transfer_format
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

transfer_filename_is_firmware:
            lda     install_name_length
            cmp     #5
            bcc     +
            tay
            dey
            lda     install_name,y
            ora     #$20
            cmp     #'w'
            bne     +
            dey
            lda     install_name,y
            ora     #$20
            cmp     #'f'
            bne     +
            dey
            lda     install_name,y
            ora     #$20
            cmp     #'2'
            bne     +
            dey
            lda     install_name,y
            ora     #$20
            cmp     #'k'
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
            cmp     #FORMAT_FIRMWARE
            beq     validate_firmware_scan
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
validate_firmware_scan:
            ; The RP2040 performs complete manifest, vector, and SHA-256
            ; validation. Locally reject only obviously wrong/truncated files
            ; before asking it to erase staging.
            lda     header_count
            cmp     #10
            bne     invalid_transfer_image
            lda     image_header+0
            cmp     #'K'
            bne     invalid_transfer_image
            lda     image_header+1
            cmp     #'2'
            bne     invalid_transfer_image
            lda     image_header+2
            cmp     #'F'
            bne     invalid_transfer_image
            lda     image_header+3
            cmp     #'W'
            bne     invalid_transfer_image
            ; package must exceed 4096 bytes and fit the 0x270000-byte slot
            lda     file_size+3
            bne     invalid_transfer_image
            lda     file_size+2
            cmp     #$27
            bcc     validate_firmware_minimum
            bne     invalid_transfer_image
            lda     file_size+1
            ora     file_size
            bne     invalid_transfer_image
validate_firmware_minimum:
            lda     file_size+2
            bne     valid_transfer_image
            lda     file_size+1
            cmp     #$10
            bcc     invalid_transfer_image
            bne     valid_transfer_image
            lda     file_size
            beq     invalid_transfer_image
            bra     valid_transfer_image
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
            jsr     ui_draw_header
            ldx     #20
            ldy     #UI_HEADER_LINE
            jsr     ui_set_xy
            lda     #UI_COLOR_LABEL
            sta     ui_color
            lda     #<ui_help_title_text
            ldx     #>ui_help_title_text
            jsr     ui_puts_colored
            jsr     ui_draw_help_frame
            stz     help_line_index
draw_help_layout_item:
            ldx     help_line_index
            lda     ui_help_layout,x
            cmp     #$ff
            beq     draw_help_layout_done
            tay
            inx
            lda     ui_help_layout,x
            sta     ZP_TIMEOUT2
            inx
            lda     ui_help_layout,x
            sta     ui_color
            inx
            lda     ui_help_layout,x
            sta     status_pointer
            inx
            lda     ui_help_layout,x
            sta     status_pointer+1
            inx
            stx     help_line_index
            ldx     ZP_TIMEOUT2
            jsr     ui_set_xy
            lda     status_pointer
            ldx     status_pointer+1
            jsr     ui_puts_colored
            bra     draw_help_layout_item
draw_help_layout_done:
            jsr     ui_draw_help_legend
            lda     #<boot_log_key_bar_text
            ldx     #>boot_log_key_bar_text
            jsr     ui_draw_key_line_1
            stz     MMU_IO_CTRL
            rts

draw_boot_log_screen:
            jsr     ui_clear_screen
            lda     #2
            sta     MMU_IO_CTRL
            jsr     ui_draw_header
            ldx     #3
            ldy     #UI_STATUS_LINE
            jsr     ui_set_xy
            lda     #<ui_boot_log_title_text
            ldx     #>ui_boot_log_title_text
            jsr     ui_puts
            ldx     #7
            ldy     #UI_COLUMNS_LINE
            jsr     ui_set_xy
            lda     #<boot_log_columns_text
            ldx     #>boot_log_columns_text
            jsr     ui_puts
            jsr     ui_draw_plain_top_border
            jsr     ui_draw_separator
            ; The diagnostic entries are plain text rather than catalog rows,
            ; so lay down the list interior and both vertical frame sides
            ; before fetching them. Text is then written inside this frame.
            stz     ui_entry_index
draw_boot_log_frame_row:
            jsr     draw_blank_entry
            inc     ui_entry_index
            lda     ui_entry_index
            cmp     #UI_MAX_ENTRIES
            bcc     draw_boot_log_frame_row
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
            jsr     ui_draw_plain_bottom_border
            ldx     #3
            ldy     #UI_STATUS_MESSAGE_LINE
            jsr     ui_set_xy
            lda     #<boot_log_hint_text
            ldx     #>boot_log_hint_text
            jsr     ui_puts
            jsr     ui_draw_return_hint
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
            jsr     ui_draw_header
            ldx     #3
            ldy     #UI_STATUS_LINE
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
            ldx     #3
            ldy     #UI_PATH_LINE
            jsr     ui_set_xy
            lda     #GLYPH_CURSOR
            jsr     ui_putc
            lda     #' '
            jsr     ui_putc
            lda     local_drive
            clc
            adc     #'0'
            jsr     ui_putc
            lda     #':'
            jsr     ui_putc
            lda     #<local_path
            ldx     #>local_path
            jsr     ui_puts
            ldx     #7
            ldy     #UI_COLUMNS_LINE
            jsr     ui_set_xy
            lda     #<ui_local_columns_text
            ldx     #>ui_local_columns_text
            jsr     ui_puts
            jsr     ui_draw_top_border
            jsr     ui_draw_separator
            stz     MMU_IO_CTRL
            jsr     draw_local_entries
            lda     #2
            sta     MMU_IO_CTRL
            jsr     ui_draw_bottom_border
            jsr     ui_draw_key_bar
            stz     MMU_IO_CTRL
            lda     local_truncated
            beq     draw_local_screen_done
            lda     #<local_truncated_text
            ldx     #>local_truncated_text
            jsr     draw_status
draw_local_screen_done:
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
            lda     #UI_COLOR_HIGHLIGHT
            sta     ui_color
            lda     #GLYPH_CURSOR
            jsr     ui_putc_colored
            bra     draw_local_marker_done
+           lda     #' '
draw_local_marker:
            jsr     ui_putc
draw_local_marker_done:
            lda     #' '
            jsr     ui_putc
            lda     ui_entry_flags
            and     #LOCAL_FLAG_DIRECTORY
            beq     +
            lda     #<source_dir_text
            ldx     #>source_dir_text
            bra     draw_local_source
+           lda     #<source_file_text
            ldx     #>source_file_text
draw_local_source:
            pha
            lda     local_draw_index
            cmp     local_cursor
            bne     +
            lda     #UI_COLOR_HIGHLIGHT
            bra     draw_local_source_color
+           lda     #UI_COLOR_LABEL
draw_local_source_color:
            sta     ui_color
            pla
            jsr     ui_puts_colored
            ldx     #6
draw_local_source_gap:
            lda     #' '
            jsr     ui_putc
            dex
            bne     draw_local_source_gap
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
            jsr     ui_draw_header
            ldx     #3
            ldy     #UI_STATUS_LINE
            jsr     ui_set_xy
            lda     #<context_text
            ldx     #>context_text
            jsr     ui_puts
            lda     context
            clc
            adc     #'1'
            jsr     ui_putc
            lda     #' '
            jsr     ui_putc
            lda     #GLYPH_SEPARATOR
            jsr     ui_putc
            lda     #' '
            jsr     ui_putc
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
            ldy     #0
draw_running_name:
            cpy     running_name_length
            beq     draw_running_done
            lda     ui_column
            cmp     #79
            bcs     draw_running_done
            lda     running_name,y
            jsr     ui_putc
            iny
            bra     draw_running_name
draw_no_running:
            lda     #'-'
            jsr     ui_putc
draw_running_done:
            ldx     #7
            ldy     #UI_COLUMNS_LINE
            jsr     ui_set_xy
            lda     #<ui_columns_text
            ldx     #>ui_columns_text
            jsr     ui_puts
            jsr     ui_draw_top_border
            jsr     ui_draw_separator
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
            clc
            adc     catalog_top
            sta     catalog_draw_index
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
            lda     catalog_draw_index
            sta     catalog_index
            jsr     catalog_entry_pointer
            ldy     #ENTRY_SOURCE
            lda     (ZP_POINTER),y
            sta     ui_entry_source
            iny
            lda     (ZP_POINTER),y
            sta     ui_entry_flags
            lda     catalog_draw_index
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
            lda     catalog_draw_index
            cmp     cursor_index
            bne     +
            lda     #UI_COLOR_HIGHLIGHT
            sta     ui_color
            lda     #GLYPH_CURSOR
            jsr     ui_putc_colored
            bra     draw_cursor_marker_done
+           lda     #' '
draw_cursor_marker:
            jsr     ui_putc
draw_cursor_marker_done:
            lda     ui_entry_flags
            and     #FLAG_SELECTED
            beq     +
            lda     catalog_draw_index
            cmp     cursor_index
            bne     draw_default_normal
            lda     #UI_COLOR_SUCCESS_SELECTED
            bra     draw_default_color
draw_default_normal:
            lda     #UI_COLOR_SUCCESS
draw_default_color:
            sta     ui_color
            lda     #GLYPH_DEFAULT
            jsr     ui_putc_colored
            bra     draw_selected_marker_done
+           lda     #' '
draw_selected_marker:
            jsr     ui_putc
draw_selected_marker_done:
            lda     ui_entry_flags
            and     #FLAG_RUNNING
            beq     +
            lda     catalog_draw_index
            cmp     cursor_index
            bne     draw_booted_normal
            lda     #UI_COLOR_ORANGE_SELECTED
            bra     draw_booted_color
draw_booted_normal:
            lda     #UI_COLOR_ORANGE
draw_booted_color:
            sta     ui_color
            lda     #GLYPH_BOOTED
            jsr     ui_putc_colored
            bra     draw_running_marker_done
+           lda     #' '
draw_running_marker:
            jsr     ui_putc
draw_running_marker_done:
            lda     #' '
            jsr     ui_putc
            lda     catalog_draw_index
            cmp     cursor_index
            bne     +
            lda     #UI_COLOR_HIGHLIGHT
            bra     draw_source_color
+           lda     #UI_COLOR_LABEL
draw_source_color:
            sta     ui_color
            lda     ui_entry_source
            jsr     ui_print_source_colored
            lda     #' '
            jsr     ui_putc
            lda     ZP_POINTER
            sta     status_pointer
            lda     ZP_POINTER+1
            sta     status_pointer+1
            lda     catalog_draw_index
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
            ldy     #UI_STATUS_MESSAGE_LINE
            jsr     ui_clear_full_row
            ldx     #3
            ldy     #UI_STATUS_MESSAGE_LINE
            jsr     ui_set_xy
            lda     status_pointer
            ldx     status_pointer+1
            jsr     ui_puts
            stz     MMU_IO_CTRL
            rts

draw_delete_confirmation:
            lda     #2
            sta     MMU_IO_CTRL
            jsr     ui_dim_screen
            lda     #UI_COLOR_ERROR
            sta     ui_modal_color
            jsr     ui_draw_modal
            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_MODAL_TOP+2
            jsr     ui_set_xy
            lda     #<delete_prompt_text
            ldx     #>delete_prompt_text
            jsr     ui_puts
            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_MODAL_TOP+5
            jsr     ui_set_xy
            ldy     #0
draw_delete_path_loop:
            cpy     delete_path_length
            beq     draw_delete_instruction
            cpy     #49
            beq     draw_delete_instruction
            lda     delete_path,y
            jsr     ui_putc
            iny
            bra     draw_delete_path_loop
draw_delete_instruction:
            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_MODAL_BOTTOM-2
            jsr     ui_set_xy
            lda     #<delete_confirm_text
            ldx     #>delete_confirm_text
            jsr     ui_puts
            stz     MMU_IO_CTRL
            rts

draw_firmware_apply_confirmation:
            lda     #2
            sta     MMU_IO_CTRL
            jsr     ui_dim_screen
            lda     #UI_COLOR_ACCENT
            sta     ui_modal_color
            jsr     ui_draw_modal
            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_MODAL_TOP+2
            jsr     ui_set_xy
            lda     #<firmware_ready_prompt_text
            ldx     #>firmware_ready_prompt_text
            jsr     ui_puts
            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_MODAL_TOP+5
            jsr     ui_set_xy
            lda     #<firmware_restart_warning_text
            ldx     #>firmware_restart_warning_text
            jsr     ui_puts
            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_MODAL_BOTTOM-2
            jsr     ui_set_xy
            lda     #<firmware_confirm_text
            ldx     #>firmware_confirm_text
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
            jmp     draw_progress

draw_firmware_receive_progress:
            ldx     #3
-           lda     uploaded_size,x
            sta     progress_current,x
            lda     file_size,x
            sta     progress_total,x
            dex
            bpl     -
            lda     #<firmware_receive_progress_text
            ldx     #>firmware_receive_progress_text
            jmp     draw_progress

draw_firmware_erase_progress:
            lda     #<firmware_erase_progress_text
            ldx     #>firmware_erase_progress_text
            jmp     draw_progress

draw_firmware_ready_progress:
            ldx     #3
-           lda     file_size,x
            sta     progress_current,x
            sta     progress_total,x
            dex
            bpl     -
            lda     #<firmware_ready_progress_text
            ldx     #>firmware_ready_progress_text
            jmp     draw_progress

; A/X points to a stage label. progress_current/progress_total are little-endian
; byte counts. A zero total renders an activity marker and a scanned-byte count.
draw_progress:
            sta     progress_label
            stx     progress_label+1
            jsr     calculate_progress_values

            lda     #2
            sta     MMU_IO_CTRL
            lda     progress_modal_visible
            bne     draw_progress_modal_ready
            jsr     ui_dim_screen
            lda     #UI_COLOR_FRAME
            sta     ui_modal_color
            jsr     ui_draw_modal
            stz     progress_modal_kind
            stz     progress_drawn_label
            stz     progress_drawn_label+1
            lda     #1
            sta     progress_modal_visible
draw_progress_modal_ready:
            jsr     progress_select_kind
            cmp     progress_modal_kind
            beq     draw_progress_static_ready
            sta     progress_modal_kind
            stz     progress_drawn_label
            stz     progress_drawn_label+1
            jsr     draw_progress_static
draw_progress_static_ready:
            lda     progress_label
            cmp     progress_drawn_label
            bne     draw_progress_status
            lda     progress_label+1
            cmp     progress_drawn_label+1
            beq     draw_progress_status_ready
draw_progress_status:
            ldy     #UI_PROGRESS_STATUS_LINE
            jsr     ui_clear_modal_row
            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_PROGRESS_STATUS_LINE
            jsr     ui_set_xy
            jsr     progress_select_status_color
            sta     ui_color
            lda     progress_label
            ldx     progress_label+1
            jsr     ui_puts_colored
            lda     progress_label
            sta     progress_drawn_label
            lda     progress_label+1
            sta     progress_drawn_label+1
draw_progress_status_ready:
            ; Every cell in the bar and fixed-width detail fields is replaced
            ; below. Do not flash the row by blanking it first.
            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_PROGRESS_BAR_LINE
            jsr     ui_set_xy
            ldx     #0
draw_progress_bar_loop:
            jsr     progress_total_is_zero
            bcc     draw_determinate_cell
            cpx     progress_activity
            bne     draw_activity_empty
            lda     #UI_COLOR_PROGRESS_ACTIVE
            sta     ui_color
            lda     #GLYPH_CURSOR
            bra     draw_progress_cell
draw_activity_empty:
            lda     #UI_COLOR_PROGRESS_EMPTY
            sta     ui_color
            lda     #' '
            bra     draw_progress_cell
draw_determinate_cell:
            cpx     progress_filled
            bcc     draw_progress_filled_cell
            bne     draw_progress_empty_cell
            lda     progress_partial
            beq     draw_progress_empty_cell
            clc
            adc     #GLYPH_PROGRESS_FIRST-1
            pha
            lda     #UI_COLOR_SUCCESS_SELECTED
            sta     ui_color
            pla
            bra     draw_progress_cell
draw_progress_empty_cell:
            lda     #UI_COLOR_PROGRESS_EMPTY
            sta     ui_color
            lda     #' '
            bra     draw_progress_cell
draw_progress_filled_cell:
            lda     #UI_COLOR_SUCCESS_SELECTED
            sta     ui_color
            lda     #GLYPH_PROGRESS_FULL
draw_progress_cell:
            jsr     ui_putc_colored
            inx
            cpx     #UI_PROGRESS_BAR_WIDTH
            bne     draw_progress_bar_loop
            jsr     progress_total_is_zero
            bcc     draw_progress_detail
draw_progress_activity_done:
            inc     progress_activity
            lda     progress_activity
            cmp     #UI_PROGRESS_BAR_WIDTH
            bcc     draw_progress_detail
            stz     progress_activity

draw_progress_detail:
            lda     #' '
            jsr     ui_putc
            lda     #' '
            jsr     ui_putc
            lda     #UI_COLOR_ACCENT
            sta     ui_color
            jsr     progress_total_is_zero
            bcs     draw_progress_current_detail
            stz     decimal_value+1
            lda     progress_percent
            sta     decimal_value
            lda     #3
            sta     decimal_width
            jsr     ui_print_u16_decimal
            lda     #<progress_percent_text
            ldx     #>progress_percent_text
            jsr     ui_puts_colored
draw_progress_current_detail:
            jsr     progress_current_to_kib
            lda     #4
            sta     decimal_width
            jsr     ui_print_u16_decimal
            jsr     progress_total_is_zero
            bcc     draw_progress_total_detail
            lda     #<progress_scanned_text
            ldx     #>progress_scanned_text
            jsr     ui_puts_colored
            bra     draw_progress_done
draw_progress_total_detail:
            lda     #<progress_separator_text
            ldx     #>progress_separator_text
            jsr     ui_puts_colored
            jsr     progress_total_to_kib
            lda     #4
            sta     decimal_width
            jsr     ui_print_u16_decimal
            lda     #<progress_kib_text
            ldx     #>progress_kib_text
            jsr     ui_puts_colored
draw_progress_done:
            stz     MMU_IO_CTRL
            rts

; Map stage labels to the four modal designs. Scan and upload are separate
; phases of a local transfer, so their static headings change exactly once.
progress_select_kind:
            lda     progress_label+1
            cmp     #>scan_progress_text
            bne     progress_select_manager
            lda     progress_label
            cmp     #<scan_progress_text
            beq     progress_return_scan_kind
progress_select_manager:
            lda     progress_label+1
            cmp     #>install_progress_text
            bne     progress_select_export
            lda     progress_label
            cmp     #<install_progress_text
            beq     progress_return_manager_kind
progress_select_export:
            lda     progress_label+1
            cmp     #>export_progress_text
            bne     progress_select_firmware
            lda     progress_label
            cmp     #<export_progress_text
            beq     progress_return_export_kind
progress_select_firmware:
            lda     progress_label+1
            cmp     #>firmware_receive_progress_text
            bne     progress_select_firmware_erase
            lda     progress_label
            cmp     #<firmware_receive_progress_text
            beq     progress_return_firmware_kind
progress_select_firmware_erase:
            lda     progress_label+1
            cmp     #>firmware_erase_progress_text
            bne     progress_select_firmware_ready
            lda     progress_label
            cmp     #<firmware_erase_progress_text
            beq     progress_return_firmware_kind
progress_select_firmware_ready:
            lda     progress_label+1
            cmp     #>firmware_ready_progress_text
            bne     progress_return_flash_kind
            lda     progress_label
            cmp     #<firmware_ready_progress_text
            bne     progress_return_flash_kind
progress_return_firmware_kind:
            lda     #PROGRESS_KIND_FIRMWARE
            rts
progress_return_flash_kind:
            lda     #PROGRESS_KIND_FLASH
            rts
progress_return_scan_kind:
            lda     #PROGRESS_KIND_SCAN
            rts
progress_return_manager_kind:
            lda     #PROGRESS_KIND_MANAGER
            rts
progress_return_export_kind:
            lda     #PROGRESS_KIND_EXPORT
            rts

draw_progress_static:
            ldy     #UI_PROGRESS_TITLE_LINE
            jsr     ui_clear_modal_row
            ldy     #UI_PROGRESS_NAME_LINE
            jsr     ui_clear_modal_row
            ldy     #UI_PROGRESS_HINT_LINE
            jsr     ui_clear_modal_row

            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_PROGRESS_TITLE_LINE
            jsr     ui_set_xy
            lda     #UI_COLOR_ACCENT
            sta     ui_color
            lda     progress_modal_kind
            cmp     #PROGRESS_KIND_SCAN
            beq     draw_progress_scan_title
            cmp     #PROGRESS_KIND_MANAGER
            beq     draw_progress_manager_title
            cmp     #PROGRESS_KIND_EXPORT
            beq     draw_progress_export_title
            cmp     #PROGRESS_KIND_FIRMWARE
            beq     draw_progress_firmware_title
            lda     #<progress_flash_title
            ldx     #>progress_flash_title
            bra     draw_progress_title
draw_progress_scan_title:
            lda     #<progress_scan_title
            ldx     #>progress_scan_title
            bra     draw_progress_title
draw_progress_manager_title:
            lda     #<progress_manager_title
            ldx     #>progress_manager_title
            bra     draw_progress_title
draw_progress_export_title:
            lda     #<progress_export_title
            ldx     #>progress_export_title
            bra     draw_progress_title
draw_progress_firmware_title:
            lda     #<progress_firmware_title
            ldx     #>progress_firmware_title
draw_progress_title:
            jsr     ui_puts_colored

            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_PROGRESS_NAME_LINE
            jsr     ui_set_xy
            lda     #UI_COLOR_NORMAL
            sta     ui_color
            ldy     #0
draw_progress_name_loop:
            cpy     #UI_MODAL_RIGHT-UI_MODAL_LEFT-6
            beq     draw_progress_hint
            lda     install_name,y
            beq     draw_progress_hint
            jsr     ui_putc_colored
            iny
            bra     draw_progress_name_loop

draw_progress_hint:
            ldx     #UI_MODAL_LEFT+3
            ldy     #UI_PROGRESS_HINT_LINE
            jsr     ui_set_xy
            lda     #UI_COLOR_LABEL
            sta     ui_color
            lda     progress_modal_kind
            cmp     #PROGRESS_KIND_SCAN
            bne     draw_progress_locked_hint
            lda     #<progress_cancel_hint
            ldx     #>progress_cancel_hint
            bra     draw_progress_hint_text
draw_progress_locked_hint:
            lda     #<progress_locked_hint
            ldx     #>progress_locked_hint
draw_progress_hint_text:
            jmp     ui_puts_colored

progress_select_status_color:
            lda     progress_modal_kind
            cmp     #PROGRESS_KIND_SCAN
            beq     progress_status_label
            cmp     #PROGRESS_KIND_FIRMWARE
            beq     progress_status_firmware
            lda     progress_label+1
            cmp     #>flash_done_progress_text
            bne     progress_status_error
            lda     progress_label
            cmp     #<flash_done_progress_text
            beq     progress_status_success
progress_status_error:
            lda     #UI_COLOR_ERROR
            rts
progress_status_success:
            lda     #UI_COLOR_SUCCESS
            rts
progress_status_firmware:
            lda     progress_label+1
            cmp     #>firmware_ready_progress_text
            bne     progress_status_label
            lda     progress_label
            cmp     #<firmware_ready_progress_text
            beq     progress_status_success
            bra     progress_status_label
progress_status_label:
            lda     #UI_COLOR_LABEL
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
            stz     progress_partial
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
            jsr     calculate_progress_partial
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

; calculate_progress_ratio leaves (current * width) mod total in
; progress_work. Scale that remainder to one of seven partial-cell glyphs.
; Eight eighths are never returned: that would already be a full cell.
calculate_progress_partial:
            lda     progress_filled
            cmp     #UI_PROGRESS_BAR_WIDTH
            bcs     calculate_progress_partial_done
            .for shift := 0, shift < 3, shift += 1
            asl     progress_work
            rol     progress_work+1
            rol     progress_work+2
            rol     progress_work+3
            .next
calculate_progress_partial_loop:
            ldx     #3
calculate_progress_partial_compare:
            lda     progress_work,x
            cmp     progress_total,x
            bcc     calculate_progress_partial_done
            bne     calculate_progress_partial_subtract
            dex
            bpl     calculate_progress_partial_compare
calculate_progress_partial_subtract:
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
            inc     progress_partial
            bra     calculate_progress_partial_loop
calculate_progress_partial_done:
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

ui_clear_modal_row:
            sty     ui_row
            ldx     #UI_MODAL_LEFT+1
            jsr     ui_set_xy
            lda     #UI_COLOR_NORMAL
            sta     ui_color
            ldx     #UI_MODAL_RIGHT-UI_MODAL_LEFT-1
ui_clear_modal_row_loop:
            lda     #' '
            jsr     ui_putc_colored
            dex
            bne     ui_clear_modal_row_loop
            rts

ui_dim_screen:
            php
            sei
            lda     #3
            sta     MMU_IO_CTRL
            ldx     #0
            lda     #UI_COLOR_DIM
ui_dim_screen_loop:
            .for page := 0, page < 19, page += 1
            sta     TEXT_BUFFER+page*$100,x
            .next
            inx
            bne     ui_dim_screen_loop
            lda     #2
            sta     MMU_IO_CTRL
            plp
            rts

ui_draw_modal:
            lda     ui_modal_color
            sta     ui_color
            ldx     #UI_MODAL_LEFT
            ldy     #UI_MODAL_TOP
            jsr     ui_set_xy
            lda     #BOX_TL
            jsr     ui_putc_colored
            ldx     #UI_MODAL_RIGHT-UI_MODAL_LEFT-1
ui_modal_top_fill:
            lda     #BOX_H
            jsr     ui_putc_colored
            dex
            bne     ui_modal_top_fill
            lda     #BOX_TR
            jsr     ui_putc_colored
            lda     #UI_MODAL_TOP+1
            sta     ui_modal_row
ui_modal_body_row:
            ldx     #UI_MODAL_LEFT
            ldy     ui_modal_row
            jsr     ui_set_xy
            lda     ui_modal_color
            sta     ui_color
            lda     #BOX_V
            jsr     ui_putc_colored
            lda     #UI_COLOR_NORMAL
            sta     ui_color
            ldx     #UI_MODAL_RIGHT-UI_MODAL_LEFT-1
ui_modal_clear_fill:
            lda     #' '
            jsr     ui_putc_colored
            dex
            bne     ui_modal_clear_fill
            lda     ui_modal_color
            sta     ui_color
            lda     #BOX_V
            jsr     ui_putc_colored
            inc     ui_modal_row
            lda     ui_modal_row
            cmp     #UI_MODAL_BOTTOM
            bcc     ui_modal_body_row
            ldx     #UI_MODAL_LEFT
            ldy     #UI_MODAL_BOTTOM
            jsr     ui_set_xy
            lda     #BOX_BL
            jsr     ui_putc_colored
            ldx     #UI_MODAL_RIGHT-UI_MODAL_LEFT-1
ui_modal_bottom_fill:
            lda     #BOX_H
            jsr     ui_putc_colored
            dex
            bne     ui_modal_bottom_fill
            lda     #BOX_BR
            jmp     ui_putc_colored

ui_print_u16_decimal:
            stz     decimal_started
            lda     #5
            sec
            sbc     decimal_width
            sta     decimal_padding_start
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
            beq     decimal_print_zero
            cpx     decimal_padding_start
            bcc     decimal_next_power
            lda     #' '
            jsr     ui_putc_colored
            bra     decimal_next_power
decimal_print_zero:
            lda     #0
decimal_print_digit:
            ora     #'0'
            jsr     ui_putc_colored
            lda     #1
            sta     decimal_started
decimal_next_power:
            inx
            cpx     #5
            bne     decimal_power_loop
            rts

ui_clear_screen:
            stz     progress_modal_visible
            stz     progress_modal_kind
            stz     progress_drawn_label
            stz     progress_drawn_label+1
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
            stz     $d001               ; 80 columns by 60 normal-height rows
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

; Compact one-line product identity from the design template.
ui_draw_header:
            ldx     #3
            ldy     #UI_HEADER_LINE
            jsr     ui_set_xy
            lda     #UI_COLOR_ACCENT
            sta     ui_color
            lda     #<ui_brand_text
            ldx     #>ui_brand_text
            jsr     ui_puts_colored
            lda     #UI_COLOR_ORANGE
            sta     ui_color
            lda     #<ui_brand_k2_text
            ldx     #>ui_brand_k2_text
            jsr     ui_puts_colored
            ldx     #20
            ldy     #UI_HEADER_LINE
            jsr     ui_set_xy
            lda     #UI_COLOR_LABEL
            sta     ui_color
            lda     #<ui_manager_text
            ldx     #>ui_manager_text
            jmp     ui_puts_colored

; Help is deliberately laid out as its own panel rather than borrowing the
; catalog's tabs, column heading, and separator. This follows the design
; template and leaves enough breathing room around the grouped controls.
ui_draw_help_frame:
            lda     #UI_COLOR_FRAME
            sta     ui_color
            ldx     #UI_HELP_LEFT
            ldy     #UI_HELP_TOP
            jsr     ui_set_xy
            lda     #BOX_TL
            jsr     ui_putc_colored
            ldx     #UI_HELP_RIGHT-UI_HELP_LEFT-1
ui_help_top_fill:
            lda     #BOX_H
            jsr     ui_putc_colored
            dex
            bne     ui_help_top_fill
            lda     #BOX_TR
            jsr     ui_putc_colored
            lda     #UI_HELP_TOP+1
            sta     ui_modal_row
ui_help_body_row:
            ldx     #UI_HELP_LEFT
            ldy     ui_modal_row
            jsr     ui_set_xy
            lda     #BOX_V
            jsr     ui_putc_colored
            ldx     #UI_HELP_RIGHT
            ldy     ui_modal_row
            jsr     ui_set_xy
            lda     #BOX_V
            jsr     ui_putc_colored
            inc     ui_modal_row
            lda     ui_modal_row
            cmp     #UI_HELP_BOTTOM
            bcc     ui_help_body_row
            ldx     #UI_HELP_LEFT
            ldy     #UI_HELP_BOTTOM
            jsr     ui_set_xy
            lda     #BOX_BL
            jsr     ui_putc_colored
            ldx     #UI_HELP_RIGHT-UI_HELP_LEFT-1
ui_help_bottom_fill:
            lda     #BOX_H
            jsr     ui_putc_colored
            dex
            bne     ui_help_bottom_fill
            lda     #BOX_BR
            jmp     ui_putc_colored

ui_draw_help_legend:
            ldx     #7
            ldy     #UI_HELP_BOTTOM
            jsr     ui_set_xy
            lda     #UI_COLOR_FRAME
            sta     ui_color
            lda     #BOX_TEE_RIGHT
            jsr     ui_putc_colored
            lda     #UI_COLOR_ACCENT
            sta     ui_color
            lda     #<ui_cursor_legend_text
            ldx     #>ui_cursor_legend_text
            jsr     ui_puts_colored
            lda     #UI_COLOR_SUCCESS
            sta     ui_color
            lda     #<ui_default_legend_text
            ldx     #>ui_default_legend_text
            jsr     ui_puts_colored
            lda     #UI_COLOR_ORANGE
            sta     ui_color
            lda     #<ui_booted_legend_text
            ldx     #>ui_booted_legend_text
            jsr     ui_puts_colored
            ldx     #40
            ldy     #UI_HELP_BOTTOM
            jsr     ui_set_xy
            lda     #UI_COLOR_FRAME
            sta     ui_color
            lda     #BOX_TEE_LEFT
            jmp     ui_putc_colored

ui_draw_top_border:
            jsr     ui_draw_plain_top_border
            ldx     #7
            ldy     #UI_FRAME_TOP_LINE
            jsr     ui_set_xy
            lda     #UI_COLOR_FRAME
            sta     ui_color
            lda     #BOX_TEE_RIGHT
            jsr     ui_putc_colored
            ldx     #8
            ldy     #UI_FRAME_TOP_LINE
            jsr     ui_set_xy
            lda     view_mode
            bne     ui_draw_catalog_tab_inactive
            lda     #UI_COLOR_ACCENT
            bra     ui_draw_catalog_tab

ui_draw_plain_top_border:
            lda     #BOX_TL
            sta     ui_border_left
            lda     #BOX_TR
            sta     ui_border_right
            ldy     #UI_FRAME_TOP_LINE
            jmp     ui_draw_border
ui_draw_catalog_tab_inactive:
            lda     #UI_COLOR_LABEL
ui_draw_catalog_tab:
            sta     ui_color
            lda     #<ui_catalog_tab_text
            ldx     #>ui_catalog_tab_text
            jsr     ui_puts_colored
            lda     #UI_COLOR_FRAME
            sta     ui_color
            lda     #BOX_TEE_LEFT
            jsr     ui_putc_colored
            ldx     #30
            ldy     #UI_FRAME_TOP_LINE
            jsr     ui_set_xy
            lda     #BOX_TEE_RIGHT
            jsr     ui_putc_colored
            ldx     #31
            ldy     #UI_FRAME_TOP_LINE
            jsr     ui_set_xy
            lda     view_mode
            beq     ui_draw_local_tab_inactive
            lda     #UI_COLOR_ACCENT
            bra     ui_draw_local_tab
ui_draw_local_tab_inactive:
            lda     #UI_COLOR_LABEL
ui_draw_local_tab:
            sta     ui_color
            lda     #<ui_local_tab_text
            ldx     #>ui_local_tab_text
            jsr     ui_puts_colored
            lda     #UI_COLOR_FRAME
            sta     ui_color
            lda     #BOX_TEE_LEFT
            jmp     ui_putc_colored

ui_draw_separator:
            lda     #UI_COLOR_LABEL
            ldy     #UI_COLUMNS_LINE
            jsr     ui_set_line_color
            ldx     #UI_BOX_LEFT
            ldy     #UI_COLUMNS_LINE
            jsr     ui_set_xy
            lda     #BOX_V
            jsr     ui_putc
            ldx     #UI_BOX_RIGHT
            ldy     #UI_COLUMNS_LINE
            jsr     ui_set_xy
            lda     #BOX_V
            jsr     ui_putc
            lda     #BOX_TEE_LEFT
            sta     ui_border_left
            lda     #BOX_TEE_RIGHT
            sta     ui_border_right
            ldy     #UI_SEPARATOR_LINE
            jmp     ui_draw_border

ui_draw_bottom_border:
            jsr     ui_draw_plain_bottom_border
            ldx     #7
            ldy     #UI_BOTTOM_LINE
            jsr     ui_set_xy
            lda     #UI_COLOR_FRAME
            sta     ui_color
            lda     #BOX_TEE_RIGHT
            jsr     ui_putc_colored
            ldx     #8
            ldy     #UI_BOTTOM_LINE
            jsr     ui_set_xy
            lda     #UI_COLOR_ACCENT
            sta     ui_color
            lda     #<ui_cursor_legend_text
            ldx     #>ui_cursor_legend_text
            jsr     ui_puts_colored
            lda     #UI_COLOR_SUCCESS
            sta     ui_color
            lda     #<ui_default_legend_text
            ldx     #>ui_default_legend_text
            jsr     ui_puts_colored
            lda     #UI_COLOR_ORANGE
            sta     ui_color
            lda     #<ui_booted_legend_text
            ldx     #>ui_booted_legend_text
            jsr     ui_puts_colored
            ldx     #40
            ldy     #UI_BOTTOM_LINE
            jsr     ui_set_xy
            lda     #UI_COLOR_FRAME
            sta     ui_color
            lda     #BOX_TEE_LEFT
            jmp     ui_putc_colored

ui_draw_plain_bottom_border:
            lda     #BOX_BL
            sta     ui_border_left
            lda     #BOX_BR
            sta     ui_border_right
            ldy     #UI_BOTTOM_LINE
            jmp     ui_draw_border

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
            lda     view_mode
            bne     ui_draw_local_keys
            lda     #<key_bar_text
            ldx     #>key_bar_text
            jsr     ui_draw_key_line_1
            lda     #<catalog_key_bar_text_2
            ldx     #>catalog_key_bar_text_2
            jmp     ui_draw_key_line_2
ui_draw_local_keys:
            lda     #<local_key_bar_text
            ldx     #>local_key_bar_text
            jsr     ui_draw_key_line_1
            lda     #<key_bar_text_2
            ldx     #>key_bar_text_2
            jmp     ui_draw_key_line_2

ui_draw_key_line_1:
            sta     status_pointer
            stx     status_pointer+1
            lda     #UI_COLOR_NORMAL
            ldy     #UI_KEY_LINE
            jsr     ui_set_full_line_color
            ldx     #3
            ldy     #UI_KEY_LINE
            bra     ui_draw_key_line
ui_draw_key_line_2:
            sta     status_pointer
            stx     status_pointer+1
            lda     #UI_COLOR_NORMAL
            ldy     #UI_KEY_LINE_2
            jsr     ui_set_full_line_color
            ldx     #3
            ldy     #UI_KEY_LINE_2
ui_draw_key_line:
            jsr     ui_set_xy
            lda     status_pointer
            ldx     status_pointer+1
            bra     ui_draw_segmented_key_bar

ui_draw_return_hint:
            lda     #UI_COLOR_NORMAL
            ldy     #UI_KEY_LINE_2
            jsr     ui_set_full_line_color
            ldx     #3
            ldy     #UI_KEY_LINE_2
            jsr     ui_set_xy
            lda     #<boot_log_key_bar_text
            ldx     #>boot_log_key_bar_text
            jmp     ui_draw_segmented_key_bar

; Draw a zero-terminated key line from A/X. KEY_BAR_TOGGLE changes from the
; amber key name to its cyan description (and back) without using a cell.
ui_draw_segmented_key_bar:
            sta     ZP_TIMEOUT0
            stx     ZP_TIMEOUT1
            lda     #UI_COLOR_KEY_BAR
            sta     ui_color
            php
            sei
            ldy     #0
ui_key_bar_loop:
            lda     (ZP_TIMEOUT0),y
            beq     ui_key_bar_done
            cmp     #KEY_BAR_TOGGLE
            beq     ui_key_bar_toggle
            sta     (ZP_POINTER)
            lda     #3
            sta     MMU_IO_CTRL
            lda     ui_color
            sta     (ZP_POINTER)
            lda     #2
            sta     MMU_IO_CTRL
            inc     ZP_POINTER
            bne     +
            inc     ZP_POINTER+1
+           inc     ui_column
ui_key_bar_next:
            iny
            bne     ui_key_bar_loop
            inc     ZP_TIMEOUT1
            bra     ui_key_bar_loop
ui_key_bar_toggle:
            lda     ui_color
            cmp     #UI_COLOR_KEY_BAR
            beq     +
            lda     #UI_COLOR_KEY_BAR
            bra     ui_key_bar_set_color
+           lda     #UI_COLOR_FRAME
ui_key_bar_set_color:
            sta     ui_color
            bra     ui_key_bar_next
ui_key_bar_done:
            plp
            rts

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

ui_print_source_colored:
            cmp     #SOURCE_AUTO
            bne     +
            lda     #<source_auto_text
            ldx     #>source_auto_text
            bra     ui_source_colored_done
+           cmp     #SOURCE_SD
            bne     +
            lda     #<source_sd_text
            ldx     #>source_sd_text
            bra     ui_source_colored_done
+           cmp     #SOURCE_FLASH
            bne     +
            lda     #<source_flash_text
            ldx     #>source_flash_text
            bra     ui_source_colored_done
+           lda     #<source_golden_text
            ldx     #>source_golden_text
ui_source_colored_done:
            jmp     ui_puts_colored

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

ui_putc_colored:
            sta     (ZP_POINTER)
            lda     #3
            sta     MMU_IO_CTRL
            lda     ui_color
            sta     (ZP_POINTER)
            lda     #2
            sta     MMU_IO_CTRL
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

; Write text and its per-cell attribute together. ui_color contains the
; foreground/background attribute and A/X points to a zero-terminated string.
ui_puts_colored:
            sta     ZP_TIMEOUT0
            stx     ZP_TIMEOUT1
            php
            sei
            ldy     #0
ui_puts_colored_loop:
            lda     (ZP_TIMEOUT0),y
            beq     ui_puts_colored_done
            sta     (ZP_POINTER)
            lda     #3
            sta     MMU_IO_CTRL
            lda     ui_color
            sta     (ZP_POINTER)
            lda     #2
            sta     MMU_IO_CTRL
            inc     ZP_POINTER
            bne     +
            inc     ZP_POINTER+1
+           inc     ui_column
            iny
            bne     ui_puts_colored_loop
            inc     ZP_TIMEOUT1
            bra     ui_puts_colored_loop
ui_puts_colored_done:
            plp
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
            jsr     catalog_get_once
            bcc     catalog_get_return
            lda     mailbox_error
            cmp     #$21                ; RP2040 catalog was rebuilt
            bne     catalog_get_error
            lda     catalog_refreshing
            bne     catalog_get_error
            lda     catalog_index
            cmp     catalog_count
            bcs     catalog_get_entry_lost
            jsr     catalog_entry_pointer
            ldy     #ENTRY_SOURCE
            lda     (ZP_POINTER),y
            sta     highlight_source
            ldy     #ENTRY_NAME_LENGTH
            lda     (ZP_POINTER),y
            sta     install_name_length
            ldx     #0
catalog_get_preserve_name:
            cpx     install_name_length
            beq     catalog_get_name_done
            txa
            clc
            adc     #ENTRY_NAME
            tay
            lda     (ZP_POINTER),y
            sta     install_name,x
            inx
            bra     catalog_get_preserve_name
catalog_get_name_done:
            stz     install_name,x
            lda     #1
            sta     catalog_refreshing
            sta     highlight_pending
            stz     highlight_found
            jsr     load_catalog
            stz     catalog_refreshing
            bcs     catalog_get_refresh_failed
            lda     highlight_found
            beq     catalog_get_entry_lost
            lda     cursor_index
            sta     catalog_index
            jsr     catalog_get_once
catalog_get_return:
            rts
catalog_get_entry_lost:
            lda     #$22                ; selected entry is no longer present
            sta     mailbox_error
            bra     catalog_get_error
catalog_get_refresh_failed:
            stz     highlight_pending
            lda     #$ff
            sta     highlight_source
catalog_get_error:
            sec
            rts

catalog_get_once:
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
            bcs     catalog_get_once_done
            lda     response_length
            cmp     #19
            bcc     response_short
            clc
catalog_get_once_done:
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
            jsr     prepare_catalog_progress_name
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

; Preserve the selected catalog basename before COPY_BEGIN replaces the
; catalog response buffer. The modal deliberately shows a filename, not the
; manager-SD directory used to locate it.
prepare_catalog_progress_name:
            lda     response_buffer+18
            beq     prepare_catalog_progress_name_empty
            tay
            dey
prepare_catalog_progress_name_find:
            lda     response_buffer+19,y
            cmp     #'/'
            beq     prepare_catalog_progress_name_found
            dey
            cpy     #$ff
            bne     prepare_catalog_progress_name_find
            ldy     #0
            bra     prepare_catalog_progress_name_copy
prepare_catalog_progress_name_found:
            iny
prepare_catalog_progress_name_copy:
            ldx     #0
prepare_catalog_progress_name_loop:
            cpy     response_buffer+18
            beq     prepare_catalog_progress_name_done
            cpx     #LOCAL_ENTRY_NAME_MAX
            beq     prepare_catalog_progress_name_done
            lda     response_buffer+19,y
            sta     install_name,x
            inx
            iny
            bra     prepare_catalog_progress_name_loop
prepare_catalog_progress_name_done:
            stz     install_name,x
            stx     install_name_length
            rts
prepare_catalog_progress_name_empty:
            stz     install_name
            stz     install_name_length
            rts

; Copy a manager-SD, replaceable-flash, or embedded-golden catalog image into
; the K2 SD browser's current directory. Write and verify a hidden temporary
; file first. Publication changes MicroKernel's CWD to the selected directory
; because its rename implementation requires a bare destination name. An
; existing final file is retained as a rollback backup until publication works.
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
            stz     export_temporary_created
            stz     export_backup_created
            stz     transfer_progress

            ; Clear any abandoned transfer/read session before beginning.
            lda     #COMMAND_IMAGE_ABORT
            ldx     #0
            jsr     mailbox_command
            bcs     export_remote_failure

            jsr     prepare_nonce
            lda     context
            sta     tx_buffer+4
            lda     #$ff                ; source-aware read request marker
            sta     tx_buffer+5
            lda     export_source
            sta     tx_buffer+6
            lda     export_path_length
            sta     tx_buffer+7
            tay
            beq     export_begin_path_ready
            dey
export_begin_copy_path:
            lda     EXPORT_PATH,y
            sta     tx_buffer+8,y
            dey
            bpl     export_begin_copy_path
export_begin_path_ready:
            lda     export_path_length
            clc
            adc     #8
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
            sta     export_temporary_created

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
            and     #PROGRESS_UPDATE_MASK
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
            jsr     export_verify_temporary
            bcs     export_publish_failure
            jsr     export_publish_temporary
            bcs     export_publish_failure
export_publish_done:
            ; Reopen the exact full path before reporting success.
            jsr     export_verify_destination
            bcc     export_publish_verified
            lda     #$ee
            sta     mailbox_error
            bra     export_cleanup
export_publish_verified:
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
export_publish_failure:
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
            lda     export_temporary_created
            beq     export_cleanup_restore
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

export_delete_temporary:
            lda     #<EXPORT_TEMPORARY
            sta     KARGS_BUF
            lda     #>EXPORT_TEMPORARY
            sta     KARGS_BUF+1
            lda     export_temporary_length
            sta     KARGS_BUFLEN
            bra     export_delete_path
export_delete_backup:
            lda     #<EXPORT_BACKUP
            sta     KARGS_BUF
            lda     #>EXPORT_BACKUP
            sta     KARGS_BUF+1
            lda     export_backup_length
            sta     KARGS_BUFLEN
            bra     export_delete_path
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

export_verify_temporary:
            lda     #<EXPORT_TEMPORARY
            sta     KARGS_BUF
            lda     #>EXPORT_TEMPORARY
            sta     KARGS_BUF+1
            lda     export_temporary_length
            sta     KARGS_BUFLEN
            bra     export_verify_path
export_verify_destination:
            lda     #<EXPORT_DESTINATION
            sta     KARGS_BUF
            lda     #>EXPORT_DESTINATION
            sta     KARGS_BUF+1
            lda     export_destination_length
            sta     KARGS_BUFLEN
export_verify_path:
            lda     local_drive
            sta     KARGS_FILE_DRIVE
            stz     KARGS_FILE_COOKIE
            stz     KARGS_FILE_MODE       ; read-only existence check
            jsr     KERNEL_FILE_OPEN
            bcs     export_verify_destination_failed
export_verify_destination_wait_open:
            jsr     export_next_event
            lda     EVENT_TYPE
            cmp     #EVENT_FILE_OPENED
            beq     export_verify_destination_opened
            cmp     #EVENT_FILE_NOT_FOUND
            beq     export_verify_destination_failed
            cmp     #EVENT_FILE_ERROR
            beq     export_verify_destination_failed
            bra     export_verify_destination_wait_open
export_verify_destination_opened:
            lda     EVENT_STREAM
            sta     export_stream
            lda     #1
            sta     export_stream_open
            jsr     export_close_local
            rts
export_verify_destination_failed:
            sec
            rts

; Publish the verified temporary file without destroying an existing final
; file first. MicroKernel rename accepts a full source path, but resolves its
; bare destination name in the current directory, so publication temporarily
; changes CWD to the directory displayed by the local browser.
export_publish_temporary:
            jsr     export_chdir_local
            bcs     export_publish_chdir_failed

            ; A stale hidden backup must not prevent us from preserving the
            ; current destination. Its absence is the common case, so ignore
            ; deletion errors here and let the following rename remain safe.
            jsr     export_delete_backup

            jsr     export_rename_destination_to_backup
            bcs     export_publish_no_existing
            lda     #1
            sta     export_backup_created
export_publish_no_existing:
            jsr     export_rename_temporary_to_destination
            bcs     export_publish_rollback
            stz     export_temporary_created

            lda     export_backup_created
            beq     export_publish_success
            jsr     export_delete_backup
            stz     export_backup_created
export_publish_success:
            jsr     export_chdir_root
            clc
            rts

export_publish_rollback:
            lda     export_backup_created
            beq     export_publish_restore_cwd
            jsr     export_rename_backup_to_destination
            bcs     export_publish_restore_cwd
            stz     export_backup_created
export_publish_restore_cwd:
            jsr     export_chdir_root
            sec
            rts
export_publish_chdir_failed:
            sec
            rts

export_rename_destination_to_backup:
            lda     #<EXPORT_DESTINATION
            sta     KARGS_BUF
            lda     #>EXPORT_DESTINATION
            sta     KARGS_BUF+1
            lda     export_destination_length
            sta     KARGS_BUFLEN
            lda     #<EXPORT_BACKUP_NAME
            sta     KARGS_EXT
            lda     #>EXPORT_BACKUP_NAME
            sta     KARGS_EXT+1
            lda     export_backup_name_length
            sta     KARGS_EXTLEN
            bra     export_rename_path
export_rename_temporary_to_destination:
            lda     #<EXPORT_TEMPORARY
            sta     KARGS_BUF
            lda     #>EXPORT_TEMPORARY
            sta     KARGS_BUF+1
            lda     export_temporary_length
            sta     KARGS_BUFLEN
            lda     #<EXPORT_BASENAME
            sta     KARGS_EXT
            lda     #>EXPORT_BASENAME
            sta     KARGS_EXT+1
            lda     export_basename_length
            sta     KARGS_EXTLEN
            bra     export_rename_path
export_rename_backup_to_destination:
            lda     #<EXPORT_BACKUP
            sta     KARGS_BUF
            lda     #>EXPORT_BACKUP
            sta     KARGS_BUF+1
            lda     export_backup_length
            sta     KARGS_BUFLEN
            lda     #<EXPORT_BASENAME
            sta     KARGS_EXT
            lda     #>EXPORT_BASENAME
            sta     KARGS_EXT+1
            lda     export_basename_length
            sta     KARGS_EXTLEN
export_rename_path:
            lda     local_drive
            sta     KARGS_FILE_DRIVE
            stz     KARGS_FILE_COOKIE
            jsr     KERNEL_FILE_RENAME
            bcs     export_rename_failed
export_wait_rename:
            jsr     export_next_event
            lda     EVENT_TYPE
            cmp     #EVENT_FILE_RENAMED
            beq     export_rename_ok
            cmp     #EVENT_FILE_NOT_FOUND
            beq     export_rename_failed
            cmp     #EVENT_FILE_ERROR
            beq     export_rename_failed
            bra     export_wait_rename
export_rename_ok:
            clc
            rts
export_rename_failed:
            sec
            rts

export_chdir_local:
            lda     #<local_path
            sta     KARGS_BUF
            lda     #>local_path
            sta     KARGS_BUF+1
            lda     export_directory_length
            sta     KARGS_BUFLEN
            bra     export_chdir
export_chdir_root:
            lda     #<export_root_path
            sta     KARGS_BUF
            lda     #>export_root_path
            sta     KARGS_BUF+1
            lda     #1
            sta     KARGS_BUFLEN
export_chdir:
            lda     local_drive
            sta     KARGS_FILE_DRIVE
            jsr     KERNEL_CHDIR
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
            sta     export_source
            cmp     #SOURCE_SD
            beq     prepare_export_sd_entry
            cmp     #SOURCE_FLASH
            beq     prepare_export_memory_entry
            cmp     #SOURCE_GOLDEN
            bne     export_entry_invalid
prepare_export_memory_entry:
            lda     response_buffer+11
            cmp     #FORMAT_GZIP
            bne     export_entry_invalid
            stz     export_path_length
            lda     response_buffer+18
            beq     export_entry_invalid
            cmp     #LOCAL_ENTRY_NAME_MAX+1
            bcs     export_entry_invalid
            sta     export_basename_length
            ldy     #0
prepare_export_golden_basename_loop:
            cpy     export_basename_length
            beq     prepare_export_basename_done
            lda     response_buffer+19,y
            sta     EXPORT_BASENAME,y
            iny
            bra     prepare_export_golden_basename_loop

prepare_export_sd_entry:
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
            sty     install_name_length
            ldx     #0
prepare_export_progress_name:
            lda     EXPORT_BASENAME,x
            sta     install_name,x
            beq     prepare_export_progress_name_done
            inx
            bra     prepare_export_progress_name
prepare_export_progress_name_done:

            jsr     local_path_length
            sta     export_directory_length
            clc
            adc     export_basename_length
            cmp     #128
            bcs     export_entry_invalid
            sta     export_destination_length

            ldx     #0
prepare_export_prefix_loop:
            cpx     export_directory_length
            beq     prepare_export_destination_name
            lda     local_path,x
            sta     EXPORT_DESTINATION,x
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

            ; Staging and rollback names live beside the destination. Their
            ; extra leading dot and suffixes must also fit MicroKernel's
            ; 127-byte pathname limit.
            lda     export_destination_length
            clc
            adc     #6                  ; leading dot plus ".part"
            cmp     #128
            bcs     export_entry_invalid
            sta     export_temporary_length
            lda     export_destination_length
            clc
            adc     #5                  ; leading dot plus ".bak"
            sta     export_backup_length
            lda     export_basename_length
            clc
            adc     #5
            sta     export_backup_name_length

            ldx     #0
prepare_export_temp_prefix:
            cpx     export_directory_length
            beq     prepare_export_temp_dot
            lda     local_path,x
            sta     EXPORT_TEMPORARY,x
            sta     EXPORT_BACKUP,x
            inx
            bra     prepare_export_temp_prefix
prepare_export_temp_dot:
            lda     #'.'
            sta     EXPORT_TEMPORARY,x
            sta     EXPORT_BACKUP,x
            inx
            ldy     #0
prepare_export_temp_basename:
            cpy     export_basename_length
            beq     prepare_export_temp_suffix
            lda     EXPORT_BASENAME,y
            sta     EXPORT_TEMPORARY,x
            sta     EXPORT_BACKUP,x
            iny
            inx
            bra     prepare_export_temp_basename
prepare_export_temp_suffix:
            ldy     #0
-           lda     export_part_suffix,y
            sta     EXPORT_TEMPORARY,x
            inx
            iny
            cmp     #0
            bne     -

            ldx     export_directory_length
            lda     #'.'
            sta     EXPORT_BACKUP_NAME
            inx
            ldy     #0
prepare_export_backup_basename:
            cpy     export_basename_length
            beq     prepare_export_backup_suffix
            lda     EXPORT_BASENAME,y
            sta     EXPORT_BACKUP,x
            sta     EXPORT_BACKUP_NAME+1,y
            inx
            iny
            bra     prepare_export_backup_basename
prepare_export_backup_suffix:
            ldy     #0
-           lda     export_backup_suffix,y
            sta     EXPORT_BACKUP,x
            inx
            iny
            cmp     #0
            bne     -
            ldx     #0
            ldy     export_directory_length
prepare_export_backup_name:
            lda     EXPORT_BACKUP,y
            sta     EXPORT_BACKUP_NAME,x
            inx
            iny
            cmp     #0
            bne     prepare_export_backup_name
            jsr     prepare_export_display_name
            clc
prepare_export_done:
            rts

; The progress dialog shows the actual K2-SD destination, not just the source
; basename. Keep the rightmost 55 characters when a deep path exceeds the
; modal width, so the filename and nearest directory remain visible.
prepare_export_display_name:
            stz     export_basename_start
            lda     export_destination_length
            cmp     #56
            bcc     prepare_export_display_length_ready
            sec
            sbc     #55
            sta     export_basename_start
            lda     #55
prepare_export_display_length_ready:
            sta     install_name_length
            ldx     #0
            ldy     export_basename_start
prepare_export_display_name_loop:
            cpx     install_name_length
            beq     prepare_export_display_name_done
            lda     EXPORT_DESTINATION,y
            sta     install_name,x
            inx
            iny
            bra     prepare_export_display_name_loop
prepare_export_display_name_done:
            stz     install_name,x
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
            stz     MMU_IO_CTRL
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
            stz     MMU_IO_CTRL
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
            cmp     #MAX_PAYLOAD+1
            bcs     response_bad_count
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
            stz     MMU_IO_CTRL
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

; The built-in K2 keyboard has RUN/STOP rather than Escape. Keep Escape as an
; unadvertised convenience for external PS/2 keyboards, but do not let normal
; command keys dismiss an informational screen accidentally.
wait_break_key:
            jsr     wait_key
            cmp     #KEY_BREAK
            beq     wait_break_key_done
            cmp     #KEY_ESC
            bne     wait_break_key
wait_break_key_done:
            rts

; A host reset restarts the CPU and kernel while the keyboard itself remains
; live. If reset happens on key-down, the new BASIC session can receive a
; typematic copy of that key. Consume events through the matching release
; before asserting the FPGA reset registers.
wait_restart_key_release:
            lda     #<event_buffer
            sta     KARGS_EVENT_DEST
            lda     #>event_buffer
            sta     KARGS_EVENT_DEST+1
            jsr     KERNEL_NEXT_EVENT
            bcc     +
            jsr     KERNEL_YIELD
            bra     wait_restart_key_release
+           lda     EVENT_TYPE
            cmp     #EVENT_KEY_RELEASED
            bne     wait_restart_key_release
            lda     EVENT_KEY_RAW
            cmp     restart_key_raw
            bne     wait_restart_key_release
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
banner_text:        .text $0a,"K2 Core Manager",$0a,0
context_text:       .text "Context ",0
running_text:       .text "booted context ",0
offline_text:       .text "FPGA Manager is unavailable.",$0a,0
version_text:       .text "Unsupported FPGA Manager version $",0
error_text:         .text "FPGA Manager command failed, error",0
exit_text:          .text "Press any key to reset the system.",0
ui_help_title_text: .text "Help - F1   ",0
ui_boot_log_title_text: .text "Boot Log",0
ui_brand_text:      .text "wildbits ",0
ui_brand_k2_text:   .text "k2",0
ui_manager_text:    .text "Core manager",0
ui_catalog_tab_text:.text " RP2040 catalog ",0
ui_local_tab_text:  .text " Local SD ",0
ui_cursor_legend_text: .text GLYPH_CURSOR," cursor   ",0
ui_default_legend_text:.text GLYPH_DEFAULT," default   ",0
ui_booted_legend_text: .text GLYPH_BOOTED," booted ",0
ui_columns_text:    .text "  SRC    PATH",0
ui_local_columns_text: .text "SRC       PATH",0
boot_log_columns_text: .text "RP2040 diagnostics",0
local_sd_error_text: .text "Can't read K2 SD. Insert a FAT-formatted card and press R.",0
local_truncated_text: .text "Some entries omitted: over 255 files or a filename longer than 62 characters.",0
manager_sd_unavailable_text: .text "No RP2040 SD card. Press F3 to copy a gzip core directly to flash.",0
boot_log_empty_text:.text "No boot diagnostics were recorded.",0
boot_log_hint_text: .text "Recent startup activity.",0
running_once_text:  .text "Starting core without changing the default...",0
context_mismatch_text: .text "Cannot run another context. Change DIP switches and restart the K2.",0
booting_text:       .text "Saving as default and starting core...",0
default_saved_text: .text "Default core saved.",0
restart_supervisor_text: .text "Restarting FPGA Manager and reloading the core...",0
restart_computer_text: .text "Restarting the K2...",0
key_bar_text:       .text "Enter",KEY_BAR_TOGGLE," Boot   ",KEY_BAR_TOGGLE,"F3",KEY_BAR_TOGGLE," Copy to flash   ",KEY_BAR_TOGGLE,"F7",KEY_BAR_TOGGLE," Set default   ",KEY_BAR_TOGGLE,"DEL",KEY_BAR_TOGGLE," Delete",0
local_key_bar_text: .text "Enter",KEY_BAR_TOGGLE," Open   ",KEY_BAR_TOGGLE,"F3",KEY_BAR_TOGGLE," Copy to flash   ",KEY_BAR_TOGGLE,"F5",KEY_BAR_TOGGLE," Copy to RP SD   ",KEY_BAR_TOGGLE,"DEL",KEY_BAR_TOGGLE," Parent directory",0
catalog_key_bar_text_2: .text "F1",KEY_BAR_TOGGLE," Help   ",KEY_BAR_TOGGLE,"F2",KEY_BAR_TOGGLE," Diagnostics   ",KEY_BAR_TOGGLE,"F5",KEY_BAR_TOGGLE," Copy to K2 SD   ",KEY_BAR_TOGGLE,"Tab",KEY_BAR_TOGGLE," Switch view   ",KEY_BAR_TOGGLE,"Q",KEY_BAR_TOGGLE," Exit",0
key_bar_text_2:     .text "F1",KEY_BAR_TOGGLE," Help   ",KEY_BAR_TOGGLE,"F2",KEY_BAR_TOGGLE," Diagnostics   ",KEY_BAR_TOGGLE,"U",KEY_BAR_TOGGLE," Firmware update   ",KEY_BAR_TOGGLE,"Tab",KEY_BAR_TOGGLE," Switch   ",KEY_BAR_TOGGLE,"Q",KEY_BAR_TOGGLE," Exit",0
boot_log_key_bar_text: .text "RUN/STOP",KEY_BAR_TOGGLE," Close",0
local_target_text:  .text "Copy destination: RP2040 SD, context ",0
local_no_manager_sd_text: .text "No RP2040 SD card. Flash context ",0
scan_text:          .text "Checking image...",0
scan_cancelled_text:.text "Image check cancelled.",0
install_text:       .text "Copying to RP2040 SD. Do not turn off the K2.",0
install_done_text:  .text "Copied to RP2040 SD.",0
direct_flash_text:  .text "Writing core to flash. Do not turn off the K2.",0
direct_flash_done_text: .text "Core written to flash.",0
direct_flash_unavailable_text: .text "Select a gzip core no larger than 2 MiB.",0
firmware_update_unavailable_text: .text "Select a .k2fw package in the Local SD view and press U.",0
firmware_stage_text: .text "Staging FPGA Manager firmware. Do not turn off the K2.",0
firmware_staged_text: .text "Firmware is staged. Press U when ready to restart and apply it.",0
firmware_apply_text: .text "Restarting FPGA Manager to install the verified update...",0
firmware_ready_prompt_text: .text "FPGA Manager firmware is ready to install.",0
firmware_restart_warning_text: .text "The RP2040 will restart; the current core will reload.",0
firmware_confirm_text: .text "Press Y to install; RUN/STOP leaves it staged.",0
flash_copy_text:    .text "Copying from RP2040 SD to flash. Do not turn off the K2.",0
flash_copy_done_text: .text "Core written to flash.",0
export_start_text:  .text "Copying to K2 SD. Do not turn off the K2.",0
export_done_text:   .text "Copied to K2 SD.",0
delete_prompt_text: .text "Delete this core from the RP2040 SD card?",0
delete_confirm_text:.text "Press Y to delete it; RUN/STOP cancels.",0
delete_cancelled_text: .text "Delete cancelled.",0
delete_done_text:   .text "Core deleted from RP2040 SD.",0
delete_unavailable_text: .text "Only cores on RP2040 SD can be deleted.",0
progress_scan_title:.text "Validating image",0
progress_manager_title: .text "Installing to manager SD",0
progress_flash_title:.text "Installing to flash",0
progress_export_title:.text "Copying to K2 SD",0
progress_firmware_title:.text "Updating FPGA Manager",0
progress_cancel_hint:.text "RUN/STOP Cancel",0
progress_locked_hint:.text "Keys locked until complete",0
scan_progress_text: .text "Scanning image and calculating CRC...",0
install_progress_text: .text "Do not power off",0
direct_flash_progress_text: .text "Do not power off",0
flash_erase_progress_text: .text "Do not power off - erasing flash",0
flash_write_progress_text: .text "Do not power off - writing image",0
flash_finalize_progress_text: .text "Do not power off - verifying flash",0
flash_done_progress_text: .text "Flash copy complete",0
flash_failed_progress_text: .text "Flash copy failed",0
export_progress_text: .text "Do not power off",0
firmware_receive_progress_text: .text "Receiving update - do not power off",0
firmware_erase_progress_text: .text "Preparing staging - do not power off",0
firmware_ready_progress_text: .text "Update verified and staged",0
progress_separator_text: .text " / ",0
progress_percent_text: .text "%   ",0
progress_kib_text:  .text " KiB",0
progress_scanned_text: .text " KiB scanned",0
autotest_image_name:.text "WildbitsK2_2x_B0C_020200FE_20260818.bin.gz",0
source_auto_text:   .text "AUTO  ",0
source_sd_text:     .text "SD    ",0
source_flash_text:  .text "FLASH ",0
source_golden_text: .text "GOLDEN",0
source_dir_text:    .text "DIR ",0
source_file_text:   .text "FILE",0
export_part_suffix: .text ".part",0
export_backup_suffix: .text ".bak",0
export_root_path:   .text "/",0
; row, column, color, text pointer. Section headings and the two columns are
; separate records so their colors match the help mockup.
ui_help_layout:
            .byte 17,7,UI_COLOR_ACCENT
            .word help_section_global
            .byte 18,8,UI_COLOR_ORANGE
            .word help_key_f1
            .byte 18,18,UI_COLOR_NORMAL
            .word help_global_f1
            .byte 19,8,UI_COLOR_ORANGE
            .word help_key_f2
            .byte 19,18,UI_COLOR_NORMAL
            .word help_global_f2
            .byte 20,8,UI_COLOR_ORANGE
            .word help_key_tab
            .byte 20,18,UI_COLOR_NORMAL
            .word help_global_tab
            .byte 21,8,UI_COLOR_ORANGE
            .word help_key_break
            .byte 21,18,UI_COLOR_NORMAL
            .word help_global_break
            .byte 22,8,UI_COLOR_ORANGE
            .word help_key_f8
            .byte 22,18,UI_COLOR_NORMAL
            .word help_global_f8
            .byte 23,8,UI_COLOR_ORANGE
            .word help_key_q
            .byte 23,18,UI_COLOR_NORMAL
            .word help_global_q

            .byte 25,7,UI_COLOR_ACCENT
            .word help_section_catalog
            .byte 26,8,UI_COLOR_ORANGE
            .word help_key_up_down
            .byte 26,18,UI_COLOR_NORMAL
            .word help_move_cursor
            .byte 27,8,UI_COLOR_ORANGE
            .word help_key_left_right
            .byte 27,18,UI_COLOR_NORMAL
            .word help_catalog_context
            .byte 28,8,UI_COLOR_ORANGE
            .word help_key_enter
            .byte 28,18,UI_COLOR_NORMAL
            .word help_catalog_enter
            .byte 29,8,UI_COLOR_ORANGE
            .word help_key_f7
            .byte 29,18,UI_COLOR_NORMAL
            .word help_catalog_f7
            .byte 30,8,UI_COLOR_ORANGE
            .word help_key_s
            .byte 30,18,UI_COLOR_NORMAL
            .word help_catalog_s
            .byte 31,8,UI_COLOR_ORANGE
            .word help_key_f3
            .byte 31,18,UI_COLOR_NORMAL
            .word help_catalog_f3
            .byte 32,8,UI_COLOR_ORANGE
            .word help_key_f5
            .byte 32,18,UI_COLOR_NORMAL
            .word help_catalog_f5
            .byte 33,8,UI_COLOR_ORANGE
            .word help_key_delete
            .byte 33,18,UI_COLOR_NORMAL
            .word help_catalog_delete

            .byte 35,7,UI_COLOR_ACCENT
            .word help_section_local
            .byte 36,8,UI_COLOR_ORANGE
            .word help_key_up_down
            .byte 36,18,UI_COLOR_NORMAL
            .word help_move_cursor
            .byte 37,8,UI_COLOR_ORANGE
            .word help_key_left_right
            .byte 37,18,UI_COLOR_NORMAL
            .word help_local_page
            .byte 38,8,UI_COLOR_ORANGE
            .word help_key_enter
            .byte 38,18,UI_COLOR_NORMAL
            .word help_local_enter
            .byte 39,8,UI_COLOR_ORANGE
            .word help_key_delete
            .byte 39,18,UI_COLOR_NORMAL
            .word help_local_delete
            .byte 40,8,UI_COLOR_ORANGE
            .word help_key_f3
            .byte 40,18,UI_COLOR_NORMAL
            .word help_local_f3
            .byte 41,8,UI_COLOR_ORANGE
            .word help_key_f5
            .byte 41,18,UI_COLOR_NORMAL
            .word help_local_f5
            .byte 42,8,UI_COLOR_ORANGE
            .word help_key_u
            .byte 42,18,UI_COLOR_NORMAL
            .word help_local_u
            .byte $ff

help_section_global:  .text "Global",0
help_section_catalog: .text "RP2040 catalog",0
help_section_local:   .text "Local SD browser",0
help_key_f1:          .text "F1",0
help_key_f2:          .text "F2",0
help_key_f3:          .text "F3",0
help_key_f5:          .text "F5",0
help_key_f7:          .text "F7",0
help_key_f8:          .text "F8",0
help_key_tab:         .text "Tab",0
help_key_s:           .text "S",0
help_key_q:           .text "Q",0
help_key_u:           .text "U",0
help_key_break:       .text "RUN/STOP",0
help_key_up_down:     .text "Up/Down",0
help_key_left_right:  .text "Left/Right",0
help_key_enter:       .text "Enter",0
help_key_delete:      .text "DEL",0
help_global_f1:       .text "This help screen",0
help_global_f2:       .text "Boot diagnostics",0
help_global_tab:      .text "Switch catalog / local SD browser",0
help_global_break:    .text "Close screen / cancel image check",0
help_global_f8:       .text "Restart FPGA Manager and reload the core",0
help_global_q:        .text "Restart the K2",0
help_move_cursor:     .text "Move cursor",0
help_catalog_context: .text "Switch context",0
help_catalog_enter:   .text "Boot selected image now",0
help_catalog_f7:      .text "Save as default for this context",0
help_catalog_s:       .text "Save as default and boot",0
help_catalog_f3:      .text "Copy selected image to flash",0
help_catalog_f5:      .text "Copy selected image to K2 SD",0
help_catalog_delete:  .text "Delete selected manager-SD image",0
help_local_page:      .text "Move one page",0
help_local_enter:     .text "Open directory",0
help_local_delete:    .text "Parent directory",0
help_local_f3:        .text "Copy gzip core to flash",0
help_local_f5:        .text "Copy core to manager SD",0
help_local_u:         .text "Install a .k2fw FPGA Manager update",0

; Wildbits CI palette used by the Core Manager design template.
ui_text_palette:
            .dword $ff29286a, $ff72bfd0, $fff4efff, $ffffc533
            .dword $ffff6638, $ff45c82f, $fffb4b4e, $ff575687
            .dword $ff3d3b7c, $ffaaaa8a, $ff5555ff, $ff55ff55
            .dword $ffff8ded, $ffff0000, $ffffff55, $ffffffff

ui_line_lo:
            .for row := 0, row < UI_SCREEN_ROWS, row += 1
            .byte <(TEXT_BUFFER+row*80)
            .next
ui_line_hi:
            .for row := 0, row < UI_SCREEN_ROWS, row += 1
            .byte >(TEXT_BUFFER+row*80)
            .next

; ---------------------------------------------------------------------------
; Workspace
; ---------------------------------------------------------------------------

event_buffer:       .fill 16,0
catalog_generation: .fill 4,0
nonce:              .fill 4,0
context:            .byte 0
catalog_count:      .byte 0
catalog_index:      .byte 0
cursor_index:       .byte 0
catalog_top:        .byte 0
catalog_draw_index: .byte 0
selected_index:     .byte 0
selected_source:    .byte 0
catalog_refreshing: .byte 0
highlight_source:   .byte $ff
highlight_found:    .byte 0
running_valid:      .byte 0
running_context:    .byte 0
running_source:     .byte 0
running_name_length:.byte 0
boot_log_count:     .byte 0
boot_log_index:     .byte 0
boot_log_line_length: .byte 0
help_line_index:    .byte 0
restart_key_raw:    .byte 0
ui_entry_index:     .byte 0
ui_entry_source:    .byte 0
ui_entry_flags:     .byte 0
ui_column:          .byte 0
ui_row:             .byte 0
ui_color:           .byte 0
ui_modal_row:       .byte 0
ui_modal_color:     .byte 0
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
local_truncated:    .byte 0
manager_sd_available: .byte 0
local_event_flags:  .byte 0
local_name_length:  .byte 0
local_append_base_length: .byte 0
local_append_name_length: .byte 0
highlight_pending:  .byte 0
transfer_phase:     .byte 0
transfer_stream:    .byte 0
transfer_failed:    .byte 0
transfer_cancelled: .byte 0
transfer_format:    .byte 0
transfer_target:    .byte 0
upload_started:     .byte 0
transfer_retry:     .byte 0
transfer_saved_error: .byte 0
transfer_progress:  .byte 0
export_stream:      .byte 0
export_stream_open: .byte 0
export_temporary_created: .byte 0
export_backup_created: .byte 0
export_source:      .byte 0
export_path_length: .byte 0
export_basename_start: .byte 0
export_basename_length: .byte 0
export_directory_length: .byte 0
export_destination_length: .byte 0
export_temporary_length: .byte 0
export_backup_length: .byte 0
export_backup_name_length: .byte 0
export_write_offset: .byte 0
export_write_remaining: .byte 0
copy_state:         .byte 0
copy_error:         .byte 0
progress_activity:  .byte 0
progress_modal_visible: .byte 0
progress_modal_kind:.byte 0
progress_percent:   .byte 0
progress_filled:    .byte 0
progress_partial:   .byte 0
progress_ratio_limit: .byte 0
progress_ratio_result: .byte 0
progress_label:     .word 0
progress_drawn_label: .word 0
progress_current:   .fill 4,0
progress_total:     .fill 4,0
progress_work:      .fill 4,0
decimal_value:      .fill 2,0
decimal_started:    .byte 0
decimal_digit:      .byte 0
decimal_width:      .byte 0
decimal_padding_start: .byte 0
delete_path_length: .byte 0
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
; Directory event names can occupy the full one-byte length range even when
; they are too long for the visible 62-character cache entry.

core_manager_end:
            .cerror * > $c000, "K2 Core Manager overlaps the video buffer"
            .if CORE_MGR_KUP != 0
            .fill   $c000-*,0           ; KUP stores complete 8 KiB blocks
            .endif
