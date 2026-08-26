#include <array>
#include <cstdint>
#include <cstring>
#include <stdio.h>
//
#include "f_util.h"
#include "ff.h"
#include "hardware/dma.h"
#include "hardware/gpio.h"
#include "hardware/pio.h"
#include "hardware/structs/sio.h"
#include "hardware/watchdog.h"
#include "hardware/xosc.h"
#include "pico/stdlib.h"
#include "rtc.h"
//
#include "fpga_out.pio.h"
#include "boot_config.h"
#include "hardware/clocks.h"
#include "hw_config.h"
#include "miniz.h"
#include "supervisor_service.h"

// Set to 0 to use legacy GPIO bit-bang path for FPGA programming.
#ifndef USE_PIO_FPGA
#define USE_PIO_FPGA 1
#endif

#ifndef FPGA_PIO_CLKDIV
#define FPGA_PIO_CLKDIV 1.0f
#endif

// datasheet for information on which other pins can be used.
#define UART_ID              uart1
#define BAUD_RATE            115200
#define DATA_BITS            8
#define STOP_BITS            1
#define PARITY               UART_PARITY_NONE

#define UART_TX_PIN          24
#define UART_RX_PIN          25

#define SPI_SUPER_MISO_i     0   // SPI0
#define SPI_SUPER_CSn_i      1   // SPI0
#define SPI_SUPER_SCLK_i     2   // SPI0
#define SPI_SUPER_MOSI_o     3   // SPI0
#define FPGA_CONFIG_PRG      4   // Output - Pulse to begin Sequence
#define FPGA_SYSTEM_RSTn     5   // Output
#define FPGA_CONFIG_CCLK     6   // Output
#define FPGA_CONFIG_INITn    7   // Input
// Output
#define FPGA_BUS_D0          8
#define FPGA_BUS_D1          9
#define FPGA_BUS_D2          10
#define FPGA_BUS_D3          11
#define FPGA_BUS_D4          12
#define FPGA_BUS_D5          13
#define FPGA_BUS_D6          14
#define FPGA_BUS_D7          15
// Input
#define F256K2_CONTEXT_SW0   16
#define F256K2_CONTEXT_SW1   17
#define SPI_SD_SD1           21  // Not used now
#define SPI_SD_SD2           22  // Not used Now

// UART Definition
#define COM_TX_PIN           24  // UART1
#define COM_RX_PIN           25  // UART1
#define ADC0                 26
#define ADC1                 27
#define ADC2                 28
#define ADC3                 29

#define FPGA_SIZE            9730652
#define BUFFER_SIZE          32768
#define GZ_IN_BUF_SIZE       2048
#define FPGA_DATA_MASK       0x0000FF00u
#define FPGA_CCLK_MASK       (1u << FPGA_CONFIG_CCLK)
#define FPGA_INIT_TIMEOUT_MS 100
#define RESET_HOLD_SAMPLE_MS 100
#define RESET_HOLD_SECONDS   5
#define RESET_HOLD_TICKS     ((RESET_HOLD_SECONDS * 1000) / RESET_HOLD_SAMPLE_MS)

// Prototypes
void f256k2_context_man_init_io(void);
static inline void f256k2_Set_FPGA_Data_Port(unsigned char Value);
bool f256k2_init_prg_fpga(void);
bool f256k2_prg_block_fpga(const uint8_t* ptr, unsigned int len);
bool program_fpga_from_file(FIL* fil);
bool program_fpga_from_gz_file(const char* path);
bool program_fpga_from_file_path(const char* path);
bool program_fpga_from_gz_file_path(const char* gz_path);

// External FPGA gzip blobs are stored in flash at fixed addresses.
#define FPGA_FLASH_GZIP_BASE0 0x10800000u
#define FPGA_FLASH_GZIP_BASE1 0x10A00000u
#define FPGA_FLASH_GZIP_BASE2 0x10C00000u
#define FPGA_FLASH_GZIP_BASE3 0x10E00000u
#define FPGA_FLASH_SLOT_SIZE (2 * 1024 * 1024u)

typedef struct {
    const char* base_path;
    const char* update_filename;
    const char* fallback_filename;
    uint32_t flash_base;
} fpga_image_info_t;

static const fpga_image_info_t fpga_images[] = {
    { "CNTX1", "context1.bin", "CFP95600C.bin", FPGA_FLASH_GZIP_BASE0 },
    { "CNTX2", "context2.bin", "CFP95616E.bin", FPGA_FLASH_GZIP_BASE1 },
    { "CNTX3", "context3.bin", "f256k2t9.bin", FPGA_FLASH_GZIP_BASE2 },
    { "CNTX4", "context4.bin", "foenix138.bin", FPGA_FLASH_GZIP_BASE3 },
};

typedef enum {
    FPGA_METHOD_NONE = 0,
    FPGA_METHOD_SD_GZIP,
    FPGA_METHOD_SD_RAW,
    FPGA_METHOD_FLASH_GZIP,
    FPGA_METHOD_GOLDEN_GZIP,
} fpga_method_t;

static std::array fpga_method_names {
    "none",
    "SD gzip",
    "SD raw",
    "FLASH gzip",
    "GOLDEN gzip",
};

static_assert(FPGA_METHOD_GOLDEN_GZIP == fpga_method_names.size() - 1);

fpga_method_t program_fpga_from_sd_card(const fpga_image_info_t* info, uint8_t slot);
fpga_method_t program_fpga_from_sd_path(const char* path, uint8_t slot);
fpga_method_t program_fpga_from_flash_slot(const fpga_image_info_t* info, uint8_t slot);

bool program_fpga_from_gz_data(const uint8_t* data, size_t len, bool allow_ff_padding);
fpga_method_t program_fpga_from_golden_slot(unsigned char sw_choice);
fpga_method_t program_selected_context(uint8_t slot, bool sd_mounted,
                                       bool force_golden);
bool reset_hold_timer_callback(struct repeating_timer* timer);
void start_reset_hold_monitor(void);

unsigned char Buffer0[BUFFER_SIZE];
static uint8_t gzip_file_buffer[GZ_IN_BUF_SIZE];
static struct repeating_timer reset_hold_timer;
static volatile unsigned int reset_hold_ticks = 0;
static volatile bool reset_hold_armed = false;

bool reset_hold_timer_callback(struct repeating_timer* timer)
{
    (void)timer;
    if (gpio_get(FPGA_SYSTEM_RSTn)) {
        reset_hold_ticks = 0;
        reset_hold_armed = true;
        return true;
    }
    if (!reset_hold_armed) {
        return true;
    }
    if (++reset_hold_ticks >= RESET_HOLD_TICKS) {
        watchdog_reboot(0, 0, 0);
        return false;
    }
    return true;
}

void start_reset_hold_monitor(void)
{
    reset_hold_ticks = 0;
    reset_hold_armed = false;
    if (!add_repeating_timer_ms(-RESET_HOLD_SAMPLE_MS, reset_hold_timer_callback,
                                NULL, &reset_hold_timer)) {
        printf("Warning: RESET hold monitor unavailable\n");
    }
}

#if USE_PIO_FPGA
static PIO fpga_pio = pio0;
static int fpga_sm = -1;
static int fpga_dma_chan = -1;
static uint fpga_pio_offset = 0;
static bool fpga_pio_inited = false;

static void fpga_pio_init(void)
{
    if (fpga_pio_inited) {
        return;
    }

    fpga_sm = pio_claim_unused_sm(fpga_pio, true);
    fpga_dma_chan = dma_claim_unused_channel(true);
    fpga_pio_offset = pio_add_program(fpga_pio, &fpga_out_program);

    pio_sm_config cfg = fpga_out_program_get_default_config(fpga_pio_offset);
    sm_config_set_out_pins(&cfg, FPGA_BUS_D0, 8);
    sm_config_set_sideset_pins(&cfg, FPGA_CONFIG_CCLK);
    sm_config_set_out_shift(&cfg, true, true, 8);
    sm_config_set_fifo_join(&cfg, PIO_FIFO_JOIN_TX);
    sm_config_set_clkdiv(&cfg, FPGA_PIO_CLKDIV);

    pio_sm_set_consecutive_pindirs(fpga_pio, fpga_sm, FPGA_BUS_D0, 8, true);
    pio_sm_set_consecutive_pindirs(fpga_pio, fpga_sm, FPGA_CONFIG_CCLK, 1, true);
    pio_sm_init(fpga_pio, fpga_sm, fpga_pio_offset, &cfg);
    pio_sm_set_enabled(fpga_pio, fpga_sm, true);
    fpga_pio_inited = true;
}

static void fpga_pio_reset(void)
{
    fpga_pio_init();
    pio_sm_clear_fifos(fpga_pio, fpga_sm);
    pio_sm_restart(fpga_pio, fpga_sm);
}

static void fpga_pio_begin(void)
{
    fpga_pio_reset();
}

static void fpga_pio_set_gpio_mode(void)
{
    for (uint i = 0; i < 8; i++) {
        gpio_set_function(FPGA_BUS_D0 + i, GPIO_FUNC_SIO);
        gpio_set_dir(FPGA_BUS_D0 + i, GPIO_OUT);
    }
    gpio_set_function(FPGA_CONFIG_CCLK, GPIO_FUNC_SIO);
    gpio_set_dir(FPGA_CONFIG_CCLK, GPIO_OUT);
}

static void fpga_pio_set_pio_mode(void)
{
    for (uint i = 0; i < 8; i++) {
        pio_gpio_init(fpga_pio, FPGA_BUS_D0 + i);
    }
    pio_gpio_init(fpga_pio, FPGA_CONFIG_CCLK);
}

static void fpga_pio_enable(bool enable)
{
    if (!fpga_pio_inited) {
        return;
    }
    if (enable) {
        fpga_pio_set_pio_mode();
    } else {
        fpga_pio_set_gpio_mode();
    }
    pio_sm_set_enabled(fpga_pio, fpga_sm, enable);
}
#endif

static char ascii_tolower(char c)
{
    if (c >= 'A' && c <= 'Z') {
        return (char)(c - 'A' + 'a');
    }
    return c;
}

static bool starts_with_casefold(const char* text, const char* prefix)
{
    if (!text || !prefix) {
        return false;
    }
    while (*prefix) {
        if (*text == '\0' || ascii_tolower(*text) != ascii_tolower(*prefix)) {
            return false;
        }
        ++text;
        ++prefix;
    }
    return true;
}

static bool ends_with_casefold(const char* text, const char* suffix)
{
    if (!text || !suffix) {
        return false;
    }
    size_t text_len = strlen(text);
    size_t suffix_len = strlen(suffix);
    if (suffix_len > text_len) {
        return false;
    }
    const char* tail = text + (text_len - suffix_len);
    for (size_t i = 0; i < suffix_len; i++) {
        if (ascii_tolower(tail[i]) != ascii_tolower(suffix[i])) {
            return false;
        }
    }
    return true;
}

static int compare_casefold(const char* a, const char* b)
{
    while (*a && *b) {
        char ca = ascii_tolower(*a);
        char cb = ascii_tolower(*b);
        if (ca != cb) {
            return (ca < cb) ? -1 : 1;
        }
        ++a;
        ++b;
    }
    if (*a == *b) {
        return 0;
    }
    return (*a == '\0') ? -1 : 1;
}

static bool find_wildbits_image(const char* dir, const char* suffix, char* out_path, size_t out_path_size)
{
    if (!dir || !suffix || !out_path || out_path_size == 0) {
        return false;
    }

    DIR dp;
    FILINFO fno;
    FRESULT fr = f_opendir(&dp, dir);
    if (fr != FR_OK) {
        return false;
    }

    bool found = false;
    char best_name[256];
    best_name[0] = '\0';
    for (;;) {
        fr = f_readdir(&dp, &fno);
        if (fr != FR_OK || fno.fname[0] == '\0') {
            break;
        }
        if (fno.fattrib & AM_DIR) {
            continue;
        }
        if (!starts_with_casefold(fno.fname, "Wildbits")) {
            continue;
        }
        if (!ends_with_casefold(fno.fname, suffix)) {
            continue;
        }
        if (!found || compare_casefold(fno.fname, best_name) > 0) {
            int name_len = snprintf(best_name, sizeof(best_name), "%s", fno.fname);
            if (name_len <= 0 || name_len >= (int)sizeof(best_name)) {
                continue;
            }
            found = true;
        }
    }
    if (found) {
        int written = snprintf(out_path, out_path_size, "%s/%s", dir, best_name);
        if (written <= 0 || written >= (int)out_path_size) {
            found = false;
        }
    }
    f_closedir(&dp);
    return found;
}

extern "C" {
extern const uint8_t golden_fpga_context1_start[];
extern const uint8_t golden_fpga_context1_end[];
extern const uint8_t golden_fpga_context3_start[];
extern const uint8_t golden_fpga_context3_end[];
extern const uint8_t golden_fpga_context4_start[];
extern const uint8_t golden_fpga_context4_end[];
}

typedef struct {
    const uint8_t* start;
    const uint8_t* end;
} golden_image_t;

static const golden_image_t golden_images[] = {
    { golden_fpga_context1_start, golden_fpga_context1_end },
    { golden_fpga_context1_start, golden_fpga_context1_end },
    { golden_fpga_context3_start, golden_fpga_context3_end },
    { golden_fpga_context4_start, golden_fpga_context4_end },
};
static const uint8_t golden_source_context[] = { 1, 1, 3, 4 };

// See FatFs - Generic FAT Filesystem Module, "Application Interface",
// http://elm-chan.org/fsw/ff/00index_e.html

int main()
{
    // set_sys_clock_khz(266000, true);
    stdio_init_all();
    xosc_init(); // #define PICO_XOSC_STARTUP_DELAY_MULTIPLIER 64
    time_init();

    // stdio_uart_init_full(uart1, BAUD_RATE, UART_TX_PIN, -1);       // Setup STDIO to Terminal UART (to be removed later)

    f256k2_context_man_init_io();    // Go Init all the GPIOs I will need
    boot_config_init();

    // Holding the active-low system reset for at least 500 ms during manager
    // startup forces the immutable golden image selected by the context DIP.
    bool force_golden = !gpio_get(FPGA_SYSTEM_RSTn);
    sleep_ms(500);
    force_golden = force_golden && !gpio_get(FPGA_SYSTEM_RSTn);

    absolute_time_t start = get_absolute_time();

    // read the DIP switches to select the FPGA context to program
    uint8_t dip_switches = ((gpio_get_all() & 0x00030000) >> 16) & 0x03;

    if (dip_switches >= std::size(fpga_images)) {
        panic("Slot index %u is out of range\n", dip_switches);
    }

    printf("Selected slot index (0-3): %u\n", dip_switches);

    fpga_method_t method = FPGA_METHOD_NONE;

    // mount the SD card
    sd_card_t* pSD = sd_get_by_num(0);
    if (!pSD) {
        panic("Invalid hardware config, see 'hw_config.c' implementation\n");
    }

    FRESULT fr = f_mount(&pSD->fatfs, pSD->pcName, 1);

    bool sd_mounted = (fr == FR_OK);
    method = program_selected_context(dip_switches, sd_mounted, force_golden);

    if (method == FPGA_METHOD_NONE) {
        panic("Golden FPGA recovery image failed\n");
    }

    // measure programming time
    int64_t fpga_us = absolute_time_diff_us(start, get_absolute_time());

    printf("=== Wildbits FPGA Manager ===\n");
    printf("Method   : %s\n", fpga_method_names[method]);
    printf("Time     : %lldms\n", fpga_us / 1000);
    printf("Core Slot: %d\n", dip_switches);
    printf("=============================\n");

    // Keep clk_sys unchanged so UART baud and other clock-derived peripheral
    // settings remain valid after FPGA programming.
    supervisor_service_init(sd_mounted);
    start_reset_hold_monitor();

    bool reconfigure_armed = false;
    uint8_t reconfigure_slot = 0;
    for (;;) {
        SupervisorReconfigureRequest request{};
        bool requested = supervisor_service_once(&request);

        // The transaction above sends the response prepared for the previous
        // request. Waiting one transaction guarantees that RECONFIGURE is
        // acknowledged before the FPGA disappears from the supervisor bus.
        if (reconfigure_armed) {
            fpga_method_t next = program_selected_context(
                reconfigure_slot, sd_mounted, false);
            printf("Runtime reconfigure slot %u: %s\n", reconfigure_slot,
                   fpga_method_names[next]);
            reconfigure_armed = false;
        }
        if (requested) {
            reconfigure_slot = request.context;
            reconfigure_armed = true;
        }
    }
}

struct gzip_source_t {
    FIL* file;
    const uint8_t* memory;
    size_t memory_size;
    size_t memory_pos;
    size_t file_pos;
    size_t file_len;
    bool read_error;
};

static uint32_t read_le32_bytes(const uint8_t* p)
{
    return (uint32_t)p[0] | ((uint32_t)p[1] << 8) |
           ((uint32_t)p[2] << 16) | ((uint32_t)p[3] << 24);
}

static bool gzip_source_read_byte(gzip_source_t* source, uint8_t* out)
{
    if (source->memory) {
        if (source->memory_pos >= source->memory_size) {
            return false;
        }
        *out = source->memory[source->memory_pos++];
        return true;
    }

    if (source->file_pos >= source->file_len) {
        UINT read = 0;
        FRESULT result = f_read(source->file, gzip_file_buffer,
                                sizeof(gzip_file_buffer), &read);
        if (result != FR_OK) {
            source->read_error = true;
            return false;
        }
        source->file_pos = 0;
        source->file_len = read;
        if (read == 0) {
            return false;
        }
    }
    *out = gzip_file_buffer[source->file_pos++];
    return true;
}

static bool gzip_source_supply(gzip_source_t* source, mz_stream* stream)
{
    if (stream->avail_in != 0) {
        return true;
    }
    if (source->memory) {
        if (source->memory_pos >= source->memory_size) {
            return false;
        }
        size_t available = source->memory_size - source->memory_pos;
        stream->next_in = source->memory + source->memory_pos;
        stream->avail_in = static_cast<unsigned int>(available);
        source->memory_pos += available;
        return true;
    }

    if (source->file_pos >= source->file_len) {
        UINT read = 0;
        FRESULT result = f_read(source->file, gzip_file_buffer,
                                sizeof(gzip_file_buffer), &read);
        if (result != FR_OK) {
            source->read_error = true;
            return false;
        }
        source->file_pos = 0;
        source->file_len = read;
    }
    if (source->file_pos >= source->file_len) {
        return false;
    }
    stream->next_in = gzip_file_buffer + source->file_pos;
    stream->avail_in = static_cast<unsigned int>(source->file_len - source->file_pos);
    source->file_pos = source->file_len;
    return true;
}

static bool gzip_skip_header(gzip_source_t* source)
{
    mz_ulong header_crc = MZ_CRC32_INIT;
    auto read_header_byte = [&](uint8_t* out) -> bool {
        if (!gzip_source_read_byte(source, out)) {
            return false;
        }
        header_crc = mz_crc32(header_crc, out, 1);
        return true;
    };

    uint8_t header[10];
    for (uint8_t& byte : header) {
        if (!read_header_byte(&byte)) {
            return false;
        }
    }
    if (header[0] != 0x1f || header[1] != 0x8b || header[2] != 8 ||
        (header[3] & 0xe0) != 0) {
        return false;
    }

    const uint8_t flags = header[3];
    if (flags & 0x04) {
        uint8_t lo = 0, hi = 0;
        if (!read_header_byte(&lo) || !read_header_byte(&hi)) {
            return false;
        }
        uint16_t length = (uint16_t)lo | ((uint16_t)hi << 8);
        while (length-- != 0) {
            uint8_t ignored = 0;
            if (!read_header_byte(&ignored)) {
                return false;
            }
        }
    }
    for (uint8_t optional_flag : {uint8_t{0x08}, uint8_t{0x10}}) {
        if (flags & optional_flag) {
            uint8_t byte = 0;
            do {
                if (!read_header_byte(&byte)) {
                    return false;
                }
            } while (byte != 0);
        }
    }
    if (flags & 0x02) {
        uint8_t lo = 0, hi = 0;
        uint16_t expected_header_crc = 0;
        if (!gzip_source_read_byte(source, &lo) ||
            !gzip_source_read_byte(source, &hi)) {
            return false;
        }
        expected_header_crc = (uint16_t)lo | ((uint16_t)hi << 8);
        if (expected_header_crc != static_cast<uint16_t>(header_crc)) {
            return false;
        }
    }
    return true;
}

static bool gzip_read_after_stream(gzip_source_t* source, mz_stream* stream,
                                   uint8_t* out)
{
    if (stream->avail_in != 0) {
        *out = *stream->next_in++;
        --stream->avail_in;
        return true;
    }
    return gzip_source_read_byte(source, out);
}

static bool gzip_trailing_data_ok(gzip_source_t* source, mz_stream* stream,
                                  bool allow_ff_padding)
{
    uint8_t byte = 0;
    while (gzip_read_after_stream(source, stream, &byte)) {
        if (!allow_ff_padding || byte != 0xff) {
            return false;
        }
    }
    return !source->read_error;
}

static inline void pulse_fpga_config_clock()
{
    gpio_put(FPGA_CONFIG_CCLK, 0);
    gpio_put(FPGA_CONFIG_CCLK, 1);
}

static bool wait_for_fpga_init(bool high)
{
    const absolute_time_t deadline = make_timeout_time_ms(FPGA_INIT_TIMEOUT_MS);
    do {
        pulse_fpga_config_clock();
        if (gpio_get(FPGA_CONFIG_INITn) == high) {
            return true;
        }
    } while (!time_reached(deadline));
    return false;
}

static bool finish_fpga_programming()
{
#if USE_PIO_FPGA
    fpga_pio_enable(false);
#endif
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_OUT);
    for (unsigned int k = 0; k < 100; ++k) {
        pulse_fpga_config_clock();
    }
    const bool init_high = gpio_get(FPGA_CONFIG_INITn);
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_IN);
    if (!init_high) {
        printf("FPGA configuration failed: INITn is low after startup clocks\n");
        return false;
    }
    printf("FPGA configuration accepted: INITn remained high\n");
    return true;
}

static bool program_fpga_from_gzip_source(gzip_source_t* source,
                                          bool allow_ff_padding)
{
    if (!gzip_skip_header(source)) {
        printf("gzip header error\n");
        return false;
    }

    mz_stream stream{};
    int result = mz_inflateInit2(&stream, -MZ_DEFAULT_WINDOW_BITS);
    if (result != MZ_OK) {
        printf("inflate init failed: %d\n", result);
        return false;
    }

    mz_ulong output_crc = MZ_CRC32_INIT;
    uint32_t output_size = 0;
    if (!f256k2_init_prg_fpga()) {
        mz_inflateEnd(&stream);
        return false;
    }

    for (;;) {
        if (!gzip_source_supply(source, &stream)) {
            printf(source->read_error ? "gzip read failed\n" : "gzip truncated\n");
            mz_inflateEnd(&stream);
            return false;
        }

        stream.next_out = Buffer0;
        stream.avail_out = BUFFER_SIZE;
        result = mz_inflate(&stream, MZ_NO_FLUSH);
        size_t produced = BUFFER_SIZE - stream.avail_out;
        if (produced > FPGA_SIZE - output_size) {
            printf("gzip output exceeds FPGA image size\n");
            mz_inflateEnd(&stream);
            return false;
        }
        if (produced != 0) {
            output_crc = mz_crc32(output_crc, Buffer0, produced);
            output_size += static_cast<uint32_t>(produced);
            if (!f256k2_prg_block_fpga(Buffer0,
                                       static_cast<unsigned int>(produced))) {
                mz_inflateEnd(&stream);
                return false;
            }
        }

        if (result == MZ_STREAM_END) {
            uint8_t trailer[8];
            bool trailer_ok = true;
            for (uint8_t& byte : trailer) {
                if (!gzip_read_after_stream(source, &stream, &byte)) {
                    trailer_ok = false;
                    break;
                }
            }
            if (!trailer_ok || read_le32_bytes(trailer) != output_crc ||
                read_le32_bytes(trailer + 4) != output_size ||
                output_size != FPGA_SIZE ||
                !gzip_trailing_data_ok(source, &stream, allow_ff_padding)) {
                printf("gzip CRC or FPGA image size mismatch\n");
                mz_inflateEnd(&stream);
                return false;
            }
            mz_inflateEnd(&stream);
            return finish_fpga_programming();
        }
        if (result != MZ_OK) {
            printf("inflate failed: %d\n", result);
            mz_inflateEnd(&stream);
            return false;
        }
    }
}

bool program_fpga_from_gz_file(const char* path)
{
    char gz_path[256];
    int written = snprintf(gz_path, sizeof(gz_path), "%s.gz", path);
    if (written <= 0 || written >= (int)sizeof(gz_path)) {
        printf("gzip path too long\n");
        return false;
    }
    return program_fpga_from_gz_file_path(gz_path);
}

bool program_fpga_from_gz_file_path(const char* gz_path)
{
    FIL fil;
    FRESULT fr = f_open(&fil, gz_path, FA_READ);
    if (fr != FR_OK) {
        return false;
    }

    printf("Programming from SD (gzip): %s\n", gz_path);
    gzip_source_t source{&fil, nullptr, 0, 0, 0, 0, false};
    bool ok = program_fpga_from_gzip_source(&source, false);
    f_close(&fil);
    return ok;
}

bool program_fpga_from_gz_data(const uint8_t* data, size_t len, bool allow_ff_padding)
{
    if (!data || len < 18 || (data[0] == 0xff && data[1] == 0xff)) {
        return false;
    }
    gzip_source_t source{nullptr, data, len, 0, 0, 0, false};
    return program_fpga_from_gzip_source(&source, allow_ff_padding);
}

bool program_fpga_from_file_path(const char* path)
{
    FIL fil;
    FRESULT fr = f_open(&fil, path, FA_READ);
    if (fr != FR_OK) {
        return false;
    }

    printf("Programming from SD (raw): %s\n", path);
    bool ok = program_fpga_from_file(&fil);
    f_close(&fil);
    return ok;
}

fpga_method_t program_fpga_from_sd_path(const char* path, uint8_t slot)
{
    if (!path || slot >= std::size(fpga_images)) {
        return FPGA_METHOD_NONE;
    }
    fpga_method_t method = FPGA_METHOD_NONE;
    if (ends_with_casefold(path, ".gz")) {
        if (program_fpga_from_gz_file_path(path)) {
            method = FPGA_METHOD_SD_GZIP;
        }
    } else if (ends_with_casefold(path, ".bin")) {
        if (program_fpga_from_file_path(path)) {
            method = FPGA_METHOD_SD_RAW;
        }
    } else {
        printf("Selected SD image has unsupported extension: %s\n", path);
    }
    if (method != FPGA_METHOD_NONE) {
        boot_runtime_set(slot, BootSource::Sd, path);
    }
    return method;
}

fpga_method_t program_fpga_from_sd_card(const fpga_image_info_t* info, uint8_t slot)
{
    char update_path[256];
    char fallback_path[256];
    char wildbits_path[256];
    int written = snprintf(update_path, sizeof(update_path), "%s/%s",
                           info->base_path, info->update_filename);
    if (written <= 0 || written >= (int)sizeof(update_path)) {
        printf("Update path too long\n");
        return FPGA_METHOD_NONE;
    }
    written = snprintf(fallback_path, sizeof(fallback_path), "%s/%s",
                       info->base_path, info->fallback_filename);
    if (written <= 0 || written >= (int)sizeof(fallback_path)) {
        printf("Fallback path too long\n");
        return FPGA_METHOD_NONE;
    }

    printf("FPGA image base path: %s, update file: %s\n",
           info->base_path, info->update_filename);
    fpga_method_t method = program_fpga_from_sd_path(update_path, slot);
    if (method != FPGA_METHOD_NONE) {
        return method;
    }
    printf("Searching %s for Wildbits*.{gz,bin}\n", info->base_path);

    if (find_wildbits_image(info->base_path, ".gz", wildbits_path, sizeof(wildbits_path))) {
        printf("Selected Wildbits gzip image: %s\n", wildbits_path);
        method = program_fpga_from_sd_path(wildbits_path, slot);
        if (method != FPGA_METHOD_NONE) {
            return method;
        }
        printf("Wildbits gzip failed, continuing fallback\n");
    }

    if (find_wildbits_image(info->base_path, ".bin", wildbits_path, sizeof(wildbits_path))) {
        printf("Selected Wildbits raw image: %s\n", wildbits_path);
        method = program_fpga_from_sd_path(wildbits_path, slot);
        if (method != FPGA_METHOD_NONE) {
            return method;
        }
        printf("Wildbits raw failed, continuing fallback\n");
    }

    printf("Trying legacy names (.gz -> .bin) from %s\n", fallback_path);
    if (program_fpga_from_gz_file(fallback_path)) {
        char gzip_path[260];
        snprintf(gzip_path, sizeof(gzip_path), "%s.gz", fallback_path);
        boot_runtime_set(slot, BootSource::Sd, gzip_path);
        return FPGA_METHOD_SD_GZIP;
    }

    if (program_fpga_from_file_path(fallback_path)) {
        boot_runtime_set(slot, BootSource::Sd, fallback_path);
        return FPGA_METHOD_SD_RAW;
    }

    return FPGA_METHOD_NONE;
}

fpga_method_t program_fpga_from_flash_slot(const fpga_image_info_t* info, uint8_t slot)
{
    if (info->flash_base == 0u) {
        printf("No flash address specified for slot %u\n", (unsigned)(slot));
        return FPGA_METHOD_NONE;
    }

    printf("Programming from flash (gzip slot %u)\n", (unsigned)(slot));
    const uint8_t* data = reinterpret_cast<const uint8_t*>(info->flash_base);
    if (program_fpga_from_gz_data(data, FPGA_FLASH_SLOT_SIZE, true)) {
        FlashSlotInfo flash = boot_config_flash_slot(slot);
        char fallback_label[32];
        snprintf(fallback_label, sizeof(fallback_label), "flash slot %u",
                 static_cast<unsigned>(slot + 1));
        boot_runtime_set(slot, BootSource::Flash,
                         flash.valid && flash.label[0] ? flash.label : fallback_label);
        return FPGA_METHOD_FLASH_GZIP;
    }
    return FPGA_METHOD_NONE;
}

fpga_method_t program_fpga_from_golden_slot(unsigned char sw_choice)
{
    const unsigned int slot = sw_choice & 0x03;
    const golden_image_t* image = &golden_images[slot];
    const size_t length = static_cast<size_t>(image->end - image->start);
    const unsigned int requested_context = slot + 1;
    const unsigned int source_context = golden_source_context[slot];
    if (requested_context != source_context) {
        printf("Golden context %u is unavailable; using context %u rescue image\n",
               requested_context, source_context);
    }
    printf("Programming embedded golden context %u (%u bytes)\n",
           source_context, static_cast<unsigned int>(length));
    if (program_fpga_from_gz_data(image->start, length, false)) {
        char label[40];
        snprintf(label, sizeof(label), "embedded golden context %u",
                 source_context);
        boot_runtime_set(slot, BootSource::Golden, label);
        return FPGA_METHOD_GOLDEN_GZIP;
    }
    return FPGA_METHOD_NONE;
}

fpga_method_t program_selected_context(uint8_t slot, bool sd_mounted,
                                       bool force_golden)
{
    if (slot >= std::size(fpga_images)) {
        return FPGA_METHOD_NONE;
    }
    if (force_golden) {
        printf("RESET held during startup: forcing golden image\n");
        return program_fpga_from_golden_slot(slot);
    }

    const fpga_image_info_t* info = &fpga_images[slot];
    const BootSelection& selection = boot_config_selection(slot);
    fpga_method_t method = FPGA_METHOD_NONE;
    printf("Boot selection for context %u: source %u%s%s\n",
           static_cast<unsigned>(slot + 1),
           static_cast<unsigned>(selection.source),
           selection.source == BootSource::Sd ? ", path " : "",
           selection.source == BootSource::Sd ? selection.path : "");

    switch (selection.source) {
    case BootSource::Sd:
        if (sd_mounted) {
            method = program_fpga_from_sd_path(selection.path, slot);
        }
        if (method == FPGA_METHOD_NONE) {
            printf("Selected SD image failed; trying flash slot\n");
            method = program_fpga_from_flash_slot(info, slot);
        }
        break;
    case BootSource::Flash:
        method = program_fpga_from_flash_slot(info, slot);
        if (method == FPGA_METHOD_NONE && sd_mounted) {
            printf("Selected flash image failed; trying automatic SD image\n");
            method = program_fpga_from_sd_card(info, slot);
        }
        break;
    case BootSource::Golden:
        return program_fpga_from_golden_slot(slot);
    case BootSource::Auto:
    default:
        if (sd_mounted) {
            method = program_fpga_from_sd_card(info, slot);
        }
        if (method == FPGA_METHOD_NONE) {
            printf("No usable automatic SD image; trying flash slot\n");
            method = program_fpga_from_flash_slot(info, slot);
        }
        break;
    }

    if (method == FPGA_METHOD_NONE) {
        printf("Selected image and fallbacks failed; trying golden slot %u\n",
               static_cast<unsigned>(slot + 1));
        method = program_fpga_from_golden_slot(slot);
    }
    return method;
}

bool program_fpga_from_file(FIL* fil)
{
    UINT j = 0;
    FRESULT fr = FR_OK;
    uint32_t total = 0;

    // multicore_launch_core1(f256k2_prg_block_fpga);    // Get the Second Core Going

    // printf("The Core1 is Started and the Code is: %X\n", MailBox);
    if (!f256k2_init_prg_fpga()) {
        return false;
    }
    for (;;) {
        fr = f_read(fil, Buffer0, BUFFER_SIZE, &j);      // J = how many were read
        if (fr != FR_OK) {
            return false;
        }
        if (j == 0) {
            break;
        }
        if (j > FPGA_SIZE - total) {
            printf("Raw FPGA image is too large\n");
            return false;
        }
        // printf("Block #: %d Byte Read: %d\n", BlockCount++, j);
        if (!f256k2_prg_block_fpga(Buffer0, j)) {
            return false;
        }
        total += j;
    }

    if (total != FPGA_SIZE) {
        printf("Raw FPGA image size mismatch: %u\n", (unsigned)total);
        return false;
    }
    return finish_fpga_programming();
}

// This could have been done with a loop but for the sake of simplicity, I am numerating
void f256k2_context_man_init_io(void)
{
    // GPIO Init
    gpio_init(FPGA_CONFIG_PRG);     // Output - Pulse to begin Sequence
    // gpio_init(FPGA_CONFIG_DONE);    // Input
    gpio_init(FPGA_CONFIG_CCLK);    // Output
    gpio_init(FPGA_CONFIG_INITn);   // Input
    gpio_init(FPGA_SYSTEM_RSTn);   // I/O
    // gpio_init(FPGA_CONFIG_CSn);     // Output

    gpio_init(FPGA_BUS_D0);         // Output
    gpio_init(FPGA_BUS_D1);         // Output
    gpio_init(FPGA_BUS_D2);         // Output
    gpio_init(FPGA_BUS_D3);         // Output
    gpio_init(FPGA_BUS_D4);         // Output
    gpio_init(FPGA_BUS_D5);         // Output
    gpio_init(FPGA_BUS_D6);         // Output
    gpio_init(FPGA_BUS_D7);         // Output

    gpio_init(SPI_SD_SD1);          // Output (Not used right now)
    gpio_init(SPI_SD_SD2);          // Output (Not used right now)

    gpio_init(F256K2_CONTEXT_SW0);  // Input
    gpio_init(F256K2_CONTEXT_SW1);  // Input
    // GPIOs Direction
    gpio_set_dir(FPGA_CONFIG_PRG, GPIO_OUT);
    // gpio_set_dir(FPGA_CONFIG_DONE, GPIO_IN);
    gpio_set_dir(FPGA_CONFIG_CCLK, GPIO_OUT);
    gpio_set_dir(FPGA_CONFIG_INITn, GPIO_IN);
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_IN);
    gpio_pull_up(FPGA_SYSTEM_RSTn);
    // gpio_set_dir(FPGA_CONFIG_CSn, GPIO_OUT);

    gpio_set_dir(SPI_SD_SD1, GPIO_OUT);
    gpio_set_dir(SPI_SD_SD2, GPIO_OUT);

    gpio_set_dir(FPGA_BUS_D0, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D1, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D2, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D3, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D4, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D5, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D6, GPIO_OUT);
    gpio_set_dir(FPGA_BUS_D7, GPIO_OUT);

    gpio_set_dir(F256K2_CONTEXT_SW0, GPIO_IN);
    gpio_set_dir(F256K2_CONTEXT_SW1, GPIO_IN);

    gpio_put(FPGA_CONFIG_PRG, 1);
    gpio_put(FPGA_CONFIG_CCLK, 1);
    gpio_put(FPGA_SYSTEM_RSTn, 0); // Set the Output to 0, but we are going to switch between Tri-State(Read) and OUtput (0)

    gpio_put(SPI_SD_SD1, 1);
    gpio_put(SPI_SD_SD2, 1);

    // gpio_put(FPGA_CONFIG_CSn, 1);

    //    gpio_pull_up(xxxx); // Just in Case I might need this
}

// This is to Set the DataPort GPIO8--GPIO15
static inline void f256k2_Set_FPGA_Data_Port(unsigned char value)
{
    uint32_t set_mask = ((uint32_t)value << 8) & FPGA_DATA_MASK;
    sio_hw->gpio_clr = FPGA_DATA_MASK;
    sio_hw->gpio_set = set_mask;
}

bool f256k2_init_prg_fpga(void)
{
#if USE_PIO_FPGA
    fpga_pio_begin();
    fpga_pio_enable(false);
#endif
    // Bring Down Program
    gpio_put(FPGA_CONFIG_PRG, 0);
    printf("Programn is Low\n");
    if (!wait_for_fpga_init(false)) {
        gpio_put(FPGA_CONFIG_PRG, 1);
        printf("FPGA configuration failed: INITn did not go low\n");
        return false;
    }
    printf("Initn is Low\n");
    gpio_put(FPGA_CONFIG_PRG, 1);
    printf("Programn is High\n");
    if (!wait_for_fpga_init(true)) {
        printf("FPGA configuration failed: INITn did not return high\n");
        return false;
    }
    printf("Initn is Hi\n");
    pulse_fpga_config_clock();
    // gpio_put(FPGA_CONFIG_CSn, 0);               // Bring Down the ChipSelect
    return true;
}

bool f256k2_prg_block_fpga(const uint8_t* ptr, unsigned int len)
{
    // printf("Programming chunk %d bytes\n", len);
    if (!ptr) {
        return false;
    }
    if (len == 0) {
        return true;
    }

#if USE_PIO_FPGA
    if (!fpga_pio_inited) {
        fpga_pio_begin();
    }
    fpga_pio_enable(true);

    dma_channel_config cfg = dma_channel_get_default_config(fpga_dma_chan);
    channel_config_set_transfer_data_size(&cfg, DMA_SIZE_8);
    channel_config_set_read_increment(&cfg, true);
    channel_config_set_write_increment(&cfg, false);
    channel_config_set_dreq(&cfg, pio_get_dreq(fpga_pio, fpga_sm, true));

    dma_channel_configure(fpga_dma_chan, &cfg,
                          &fpga_pio->txf[fpga_sm],
                          ptr,
                          len,
                          true);
    dma_channel_wait_for_finish_blocking(fpga_dma_chan);
#else
    for (unsigned int i = 0; i < len; i++) {
        f256k2_Set_FPGA_Data_Port(*ptr++);
        sio_hw->gpio_clr = FPGA_CCLK_MASK;     // Write strobe low
        sio_hw->gpio_set = FPGA_CCLK_MASK;     // Write strobe high
    }
#endif
    if (!gpio_get(FPGA_CONFIG_INITn)) {
        printf("FPGA configuration failed: INITn went low while streaming\n");
        return false;
    }
    return true;
}
