#include <stdio.h>
#include <cstdint>
#include <cstring>
//
#include "f_util.h"
#include "ff.h"
#include "pico/stdlib.h"
#include "rtc.h"
#include "hardware/gpio.h"
#include "hardware/dma.h"
#include "hardware/pio.h"
#include "hardware/xosc.h"
#include "hardware/structs/sio.h"
//
#include "hw_config.h"
#include "hardware/clocks.h"
#include "miniz.h"
#include "lz4.h"
#include "fpga_out.pio.h"

// Set to 0 to use legacy GPIO bit-bang path for FPGA programming.
#ifndef USE_PIO_FPGA
#define USE_PIO_FPGA 1
#endif

#ifndef FPGA_PIO_CLKDIV
#define FPGA_PIO_CLKDIV 1.0f
#endif

// datasheet for information on which other pins can be used.
#define UART_ID uart1
#define BAUD_RATE 115200
#define DATA_BITS 8
#define STOP_BITS 1
#define PARITY    UART_PARITY_NONE

#define UART_TX_PIN 24
#define UART_RX_PIN 25

#define SPI_SUPER_MISO_i    0   // SPI0
#define SPI_SUPER_CSn_i     1   // SPI0
#define SPI_SUPER_SCLK_i    2   // SPI0
#define SPI_SUPER_MOSI_o    3   // SPI0
#define FPGA_CONFIG_PRG     4   // Output - Pulse to begin Sequence
#define FPGA_SYSTEM_RSTn    5   // Output
#define FPGA_CONFIG_CCLK    6   // Output
#define FPGA_CONFIG_INITn   7   // Input
// Output
#define FPGA_BUS_D0         8
#define FPGA_BUS_D1         9
#define FPGA_BUS_D2         10
#define FPGA_BUS_D3         11
#define FPGA_BUS_D4         12
#define FPGA_BUS_D5         13
#define FPGA_BUS_D6         14
#define FPGA_BUS_D7         15
// Input
#define F256K2_CONTEXT_SW0  16
#define F256K2_CONTEXT_SW1  17
#define SPI_SD_SD1          21  // Not used now
#define SPI_SD_SD2          22  // Not used Now

// UART Definition
#define COM_TX_PIN          24  // UART1
#define COM_RX_PIN          25  // UART1
#define ADC0                26
#define ADC1                27
#define ADC2                28
#define ADC3                29

#define FPGA_SIZE           9730652
#define BUFFER_SIZE         32768
#define GZ_IN_BUF_SIZE      2048
#define LZ4_COMP_BUF_SIZE   LZ4_COMPRESSBOUND(BUFFER_SIZE)
#define FPGA_DATA_MASK      0x0000FF00u
#define FPGA_CCLK_MASK      (1u << FPGA_CONFIG_CCLK)

// Prototpyes
void f256k2_context_man_init_io(void);
static inline void f256k2_Set_FPGA_Data_Port(unsigned char Value);
void f256k2_init_prg_fpga(void);
void f256k2_prg_block_fpga(const uint8_t *ptr, unsigned int len);
bool program_fpga_from_file(FIL fil);
bool program_fpga_from_lz4_file(const char* path);
bool program_fpga_from_gz_file(const char* path);
bool program_fpga_from_file_path(const char* path);
bool program_fpga_from_lz4_file_path(const char* lz4_path);
bool program_fpga_from_gz_file_path(const char* gz_path);
typedef enum {
    FPGA_METHOD_NONE = 0,
    FPGA_METHOD_SD_LZ4,
    FPGA_METHOD_SD_GZIP,
    FPGA_METHOD_SD_RAW,
    FPGA_METHOD_FLASH_LZ4,
    FPGA_METHOD_FLASH_GZIP,
} fpga_method_t;

static const char* const fpga_method_names[] = {
    "none",
    "SD LZ4",
    "SD gzip",
    "SD raw",
    "FLASH LZ4",
    "FLASH gzip",
};

fpga_method_t program_fpga_from_choice(unsigned char sw_choice);
bool program_fpga_from_lz4_data(const uint8_t* data, size_t len);
fpga_method_t program_fpga_from_flash_slot(unsigned char sw_choice);
bool gzip_skip_header(FIL* fil, uint8_t* in_buf, UINT* in_len, UINT* in_pos);
bool fil_read_exact(FIL* fil, void* dst, UINT len);

unsigned char Buffer0[BUFFER_SIZE];
static uint8_t lz4_comp_buf[LZ4_COMP_BUF_SIZE];

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

// External FPGA LZ4 blobs are stored in flash at fixed addresses.
#define FOENIX_FLASH_LZ4_BASE0 0x10800000u
#define FOENIX_FLASH_LZ4_BASE1 0x10A00000u
#define FOENIX_FLASH_LZ4_BASE2 0x10C00000u
#define FOENIX_FLASH_LZ4_BASE3 0x10E00000u
#define FOENIX_FLASH_SLOT_SIZE (2 * 1024 * 1024u)

typedef struct {
    const char* base_path;
    const char* fallback_filename;
    uint32_t flash_base;
} fpga_image_info_t;

static const fpga_image_info_t fpga_images[] = {
    { "CNTX1", "CFP95600C.bin", FOENIX_FLASH_LZ4_BASE0 },
    { "CNTX2", "CFP95616E.bin", FOENIX_FLASH_LZ4_BASE1 },
    { "CNTX3", "f256k2t9.bin",  FOENIX_FLASH_LZ4_BASE2 },
    { "CNTX4", "foenix138.bin", FOENIX_FLASH_LZ4_BASE3 },
};

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

// See FatFs - Generic FAT Filesystem Module, "Application Interface",
    // http://elm-chan.org/fsw/ff/00index_e.html

int main() {
    sd_card_t *pSD = sd_get_by_num(0);
    //set_sys_clock_khz(266000, true);
    stdio_init_all();
    xosc_init(); // #define PICO_XOSC_STARTUP_DELAY_MULTIPLIER 64
    time_init();
    // stdio_uart_init_full (uart1, BAUD_RATE, UART_TX_PIN, -1);       // Setup STDIO to Terminal UART (to be removed later)

    f256k2_context_man_init_io();    // Go Init all the GPIOs I will need

    absolute_time_t start = get_absolute_time();

    uint8_t dip_switches = ((gpio_get_all() & 0x00030000) >> 16) & 0x03;    // Read the 2 bits from DipSwitch to know which Load with need to get in there!

    fpga_method_t method;

    // Let's Mount the SDCard First
    FRESULT fr;
    fr = f_mount(&pSD->fatfs, pSD->pcName, 1);
    if (FR_OK != fr) {
      method = program_fpga_from_flash_slot(dip_switches);
      if (method == FPGA_METHOD_NONE) {
        panic("Programming from flash failed\n");
      }
    } else {
      method = program_fpga_from_choice(dip_switches);
    }

    // measure fpga programming
    int64_t fpga_us = absolute_time_diff_us(start, get_absolute_time());

    printf("=== Wildbits FPGA Loader ===\n");
    printf("Method   : %s\n", fpga_method_names[method]);
    printf("Time     : %lldms\n", fpga_us / 1000);
    printf("Core Slot: %d\n", dip_switches);
    printf("============================\n");

    f_unmount(pSD->pcName);
    set_sys_clock_khz(133000, true); // 328us

    for (;;)
      ;
}

bool program_fpga_from_lz4_file(const char* path)
{
    char lz4_path[256];
    int written = snprintf(lz4_path, sizeof(lz4_path), "%s.lz4", path);
    if (written <= 0 || written >= (int)sizeof(lz4_path)) {
        printf("lz4 path too long\n");
        return false;
    }
    return program_fpga_from_lz4_file_path(lz4_path);
}

bool program_fpga_from_lz4_file_path(const char* lz4_path)
{
    FIL fil;
    FRESULT fr = f_open(&fil, lz4_path, FA_READ);
    if (fr != FR_OK) {
        return false;
    }

    uint32_t total_size = 0;
    if (!fil_read_exact(&fil, &total_size, sizeof(total_size))) {
        f_close(&fil);
        return false;
    }
    if (total_size == 0x184D2204u) {
        f_close(&fil);
        return false;
    }
    (void)total_size;

    printf("Programming from SD (lz4 raw): %s\n", lz4_path);
    f256k2_init_prg_fpga();

    for (;;) {
        uint32_t out_len = 0;
        uint32_t in_len = 0;
        if (!fil_read_exact(&fil, &out_len, sizeof(out_len)) ||
            !fil_read_exact(&fil, &in_len, sizeof(in_len))) {
            printf("lz4 header read failed\n");
            f_close(&fil);
            return false;
        }
        if (out_len == 0 && in_len == 0) {
            break;
        }
        if (out_len > BUFFER_SIZE || in_len > LZ4_COMP_BUF_SIZE) {
            printf("lz4 block too large\n");
            f_close(&fil);
            return false;
        }
        if (!fil_read_exact(&fil, lz4_comp_buf, (UINT)in_len)) {
            printf("lz4 read failed\n");
            f_close(&fil);
            return false;
        }

        int dec = LZ4_decompress_safe((const char*)lz4_comp_buf, (char*)Buffer0,
                                      (int)in_len, (int)out_len);
        if (dec < 0 || (uint32_t)dec != out_len) {
            printf("lz4 decompress failed\n");
            f_close(&fil);
            return false;
        }
        f256k2_prg_block_fpga(Buffer0, (unsigned int)out_len);
    }

#if USE_PIO_FPGA
    fpga_pio_enable(false);
#endif
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_OUT);
    for (unsigned int k = 0; k < 100; k++){
        gpio_put(FPGA_CONFIG_CCLK, 0);        // Bring Down the Clock
        gpio_put(FPGA_CONFIG_CCLK, 1);        // Bring Up the Clock
    }
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_IN);

    f_close(&fil);
    return true;
}

bool program_fpga_from_lz4_data(const uint8_t* data, size_t len)
{
    if (!data || len < 4) {
        return false;
    }
    uint32_t total_size = (uint32_t)data[0] |
                          ((uint32_t)data[1] << 8) |
                          ((uint32_t)data[2] << 16) |
                          ((uint32_t)data[3] << 24);
    (void)total_size;

    size_t off = 4;
    f256k2_init_prg_fpga();

    while (off + 8 <= len) {
        uint32_t out_len = (uint32_t)data[off] |
                           ((uint32_t)data[off + 1] << 8) |
                           ((uint32_t)data[off + 2] << 16) |
                           ((uint32_t)data[off + 3] << 24);
        uint32_t in_len = (uint32_t)data[off + 4] |
                          ((uint32_t)data[off + 5] << 8) |
                          ((uint32_t)data[off + 6] << 16) |
                          ((uint32_t)data[off + 7] << 24);
        off += 8;
        if (out_len == 0 && in_len == 0) {
            break;
        }
        if (out_len > BUFFER_SIZE || in_len > LZ4_COMP_BUF_SIZE) {
            printf("flash lz4 block too large\n");
            return false;
        }
        if (off + in_len > len) {
            printf("flash lz4 truncated\n");
            return false;
        }
        int dec = LZ4_decompress_safe((const char*)(data + off), (char*)Buffer0,
                                      (int)in_len, (int)out_len);
        if (dec < 0 || (uint32_t)dec != out_len) {
            printf("flash lz4 decompress failed\n");
            return false;
        }
        f256k2_prg_block_fpga(Buffer0, (unsigned int)out_len);
        off += in_len;
    }

#if USE_PIO_FPGA
    fpga_pio_enable(false);
#endif
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_OUT);
    for (unsigned int k = 0; k < 100; k++){
        gpio_put(FPGA_CONFIG_CCLK, 0);
        gpio_put(FPGA_CONFIG_CCLK, 1);
    }
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_IN);

    return true;
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

    static uint8_t in_buf[GZ_IN_BUF_SIZE];
    UINT in_len = 0;
    UINT in_pos = 0;

    if (!gzip_skip_header(&fil, in_buf, &in_len, &in_pos)) {
        printf("gzip header error\n");
        f_close(&fil);
        return false;
    }

    printf("Programming from SD (gzip): %s\n", gz_path);
    mz_stream stream;
    memset(&stream, 0, sizeof(stream));

    int ret = mz_inflateInit2(&stream, -MZ_DEFAULT_WINDOW_BITS);
    if (ret != MZ_OK) {
        printf("inflate init failed: %d\n", ret);
        f_close(&fil);
        return false;
    }

    f256k2_init_prg_fpga();

    bool eof = false;
    stream.next_in = in_buf + in_pos;
    stream.avail_in = in_len - in_pos;

    for (;;) {
        if (stream.avail_in == 0) {
            UINT br = 0;
            fr = f_read(&fil, in_buf, sizeof(in_buf), &br);
            if (fr != FR_OK) {
                printf("gzip read failed\n");
                mz_inflateEnd(&stream);
                f_close(&fil);
                return false;
            }
            if (br == 0) {
                eof = true;
            }
            stream.next_in = in_buf;
            stream.avail_in = br;
        }

        stream.next_out = Buffer0;
        stream.avail_out = BUFFER_SIZE;
        ret = mz_inflate(&stream, MZ_NO_FLUSH);
        size_t produced = BUFFER_SIZE - stream.avail_out;
        if (produced > 0) {
            f256k2_prg_block_fpga(Buffer0, (unsigned int)produced);
        }

        if (ret == MZ_STREAM_END) {
            mz_inflateEnd(&stream);
#if USE_PIO_FPGA
            fpga_pio_enable(false);
#endif
            gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_OUT);
            for (unsigned int k = 0; k < 100; k++){
                gpio_put(FPGA_CONFIG_CCLK, 0);        // Bring Down the Clock
                gpio_put(FPGA_CONFIG_CCLK, 1);        // Bring Up the Clock
            }
            gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_IN);
            f_close(&fil);
            return true;
        }
        if (ret != MZ_OK) {
            printf("inflate failed: %d\n", ret);
            mz_inflateEnd(&stream);
            f_close(&fil);
            return false;
        }
        if (eof && stream.avail_in == 0) {
            printf("gzip truncated\n");
            mz_inflateEnd(&stream);
            f_close(&fil);
            return false;
        }
    }
}

bool program_fpga_from_file_path(const char* path)
{
    FIL fil;
    FRESULT fr = f_open(&fil, path, FA_READ);
    if (fr != FR_OK) {
        return false;
    }

    printf("Programming from SD (raw): %s\n", path);
    bool ok = program_fpga_from_file(fil);
    f_close(&fil);
    return ok;
}

fpga_method_t program_fpga_from_choice(unsigned char sw_choice)
{
    const fpga_image_info_t* info = &fpga_images[sw_choice & 0x03];
    char fallback_path[256];
    char wildbits_path[256];
    int written = snprintf(fallback_path, sizeof(fallback_path), "%s/%s",
                           info->base_path, info->fallback_filename);
    if (written <= 0 || written >= (int)sizeof(fallback_path)) {
        printf("Fallback path too long\n");
        return FPGA_METHOD_NONE;
    }

    printf("FPGA slot %u base path: %s, fallback file: %s\n",
           (unsigned)(sw_choice & 0x03), info->base_path, info->fallback_filename);
    printf("Searching %s for Wildbits*.{lz4,gz,bin}\n", info->base_path);
    if (find_wildbits_image(info->base_path, ".lz4", wildbits_path, sizeof(wildbits_path))) {
        printf("Selected Wildbits LZ4 image: %s\n", wildbits_path);
        if (program_fpga_from_lz4_file_path(wildbits_path)) {
            return FPGA_METHOD_SD_LZ4;
        }
        printf("Wildbits LZ4 failed, continuing fallback\n");
    }
    if (find_wildbits_image(info->base_path, ".gz", wildbits_path, sizeof(wildbits_path))) {
        printf("Selected Wildbits gzip image: %s\n", wildbits_path);
        if (program_fpga_from_gz_file_path(wildbits_path)) {
            return FPGA_METHOD_SD_GZIP;
        }
        printf("Wildbits gzip failed, continuing fallback\n");
    }
    if (find_wildbits_image(info->base_path, ".bin", wildbits_path, sizeof(wildbits_path))) {
        printf("Selected Wildbits raw image: %s\n", wildbits_path);
        if (program_fpga_from_file_path(wildbits_path)) {
            return FPGA_METHOD_SD_RAW;
        }
        printf("Wildbits raw failed, continuing fallback\n");
    }

    printf("Trying legacy names (.lz4 -> .gz -> .bin) from %s\n", fallback_path);
    if (program_fpga_from_lz4_file(fallback_path)) {
        return FPGA_METHOD_SD_LZ4;
    }
    if (program_fpga_from_gz_file(fallback_path)) {
        return FPGA_METHOD_SD_GZIP;
    }
    if (program_fpga_from_file_path(fallback_path)) {
        return FPGA_METHOD_SD_RAW;
    }
    if (info->flash_base > 0) {
        printf("Programming from flash (lz4 slot %u)\n", (unsigned)(sw_choice & 0x03));
        const uint8_t* data = reinterpret_cast<const uint8_t*>(info->flash_base);
        if (program_fpga_from_lz4_data(data, FOENIX_FLASH_SLOT_SIZE)) {
            return FPGA_METHOD_FLASH_LZ4;
        }
    }
    printf("File Not Found!\n");
    return FPGA_METHOD_NONE;
}

fpga_method_t program_fpga_from_flash_slot(unsigned char sw_choice)
{
    const fpga_image_info_t* info = &fpga_images[sw_choice & 0x03];
    if (info->flash_base == 0u) {
        return FPGA_METHOD_NONE;
    }

    printf("Programming from flash (lz4 slot %u)\n", (unsigned)(sw_choice & 0x03));
    const uint8_t* data = reinterpret_cast<const uint8_t*>(info->flash_base);
    if (program_fpga_from_lz4_data(data, FOENIX_FLASH_SLOT_SIZE)) {
        return FPGA_METHOD_FLASH_LZ4;
    }
    return FPGA_METHOD_NONE;
}

bool gzip_skip_header(FIL* fil, uint8_t* in_buf, UINT* in_len, UINT* in_pos)
{
    auto read_byte = [&](uint8_t* out) -> bool {
        if (*in_pos >= *in_len) {
            UINT br = 0;
            FRESULT fr = f_read(fil, in_buf, GZ_IN_BUF_SIZE, &br);
            if (fr != FR_OK || br == 0) {
                return false;
            }
            *in_len = br;
            *in_pos = 0;
        }
        *out = in_buf[(*in_pos)++];
        return true;
    };

    uint8_t hdr[10];
    for (size_t i = 0; i < sizeof(hdr); i++) {
        if (!read_byte(&hdr[i])) {
            return false;
        }
    }

    if (hdr[0] != 0x1f || hdr[1] != 0x8b || hdr[2] != 8) {
        return false;
    }

    uint8_t flg = hdr[3];
    if (flg & 0x04) {
        uint8_t b0 = 0, b1 = 0;
        if (!read_byte(&b0) || !read_byte(&b1)) {
            return false;
        }
        uint16_t xlen = (uint16_t)b0 | ((uint16_t)b1 << 8);
        for (uint16_t i = 0; i < xlen; i++) {
            uint8_t tmp = 0;
            if (!read_byte(&tmp)) {
                return false;
            }
        }
    }
    if (flg & 0x08) {
        uint8_t c = 0;
        do {
            if (!read_byte(&c)) {
                return false;
            }
        } while (c != 0);
    }
    if (flg & 0x10) {
        uint8_t c = 0;
        do {
            if (!read_byte(&c)) {
                return false;
            }
        } while (c != 0);
    }
    if (flg & 0x02) {
        uint8_t tmp = 0;
        if (!read_byte(&tmp) || !read_byte(&tmp)) {
            return false;
        }
    }

    return true;
}

bool fil_read_exact(FIL* fil, void* dst, UINT len)
{
    UINT total = 0;
    uint8_t* out = static_cast<uint8_t*>(dst);
    while (total < len) {
        UINT br = 0;
        FRESULT fr = f_read(fil, out + total, len - total, &br);
        if (fr != FR_OK || br == 0) {
            return false;
        }
        total += br;
    }
    return true;
}

bool program_fpga_from_file(FIL fil)
{
    UINT j = 0;
    FRESULT fr = FR_OK;

    //multicore_launch_core1(f256k2_prg_block_fpga);    // Get the Second Core Going

    //printf("The Core1 is Started and the Code is: %X\n", MailBox);
    f256k2_init_prg_fpga();
    for (;;) {
        fr = f_read(&fil, Buffer0, BUFFER_SIZE, &j);      // J = how many were read
        if (fr != FR_OK) {
            return false;
        }
        if (j == 0) {
            break;
        }
        //printf("Block #: %d Byte Read: %d\n", BlockCount++, j);
        f256k2_prg_block_fpga(Buffer0, j);
        if (j < BUFFER_SIZE) {
            break;
        }
    }

    //gpio_put(FPGA_CONFIG_CSn,1);          // Bring Down the ChipSelect
#if USE_PIO_FPGA
    fpga_pio_begin();
    fpga_pio_enable(false);
#endif
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_OUT);
    for (unsigned int k = 0; k < 100; k++){
        gpio_put(FPGA_CONFIG_CCLK, 0);        // Bring Down the Clock
        gpio_put(FPGA_CONFIG_CCLK, 1);        // Bring Up the Clock
    }
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_IN);

    return true;
}

// This could have been done with a loop but for the sake of simplicity, I am numerating
void f256k2_context_man_init_io(void)
{
    // GPIO Init
    gpio_init(FPGA_CONFIG_PRG);     // Output - Pulse to begin Sequence
    //gpio_init(FPGA_CONFIG_DONE);    // Input
    gpio_init(FPGA_CONFIG_CCLK);    // Output
    gpio_init(FPGA_CONFIG_INITn);   // Input
    gpio_init(FPGA_SYSTEM_RSTn);   // I/O
    //gpio_init(FPGA_CONFIG_CSn);     // Output

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
    //gpio_set_dir(FPGA_CONFIG_DONE, GPIO_IN);
    gpio_set_dir(FPGA_CONFIG_CCLK, GPIO_OUT);
    gpio_set_dir(FPGA_CONFIG_INITn, GPIO_IN);
    gpio_set_dir(FPGA_SYSTEM_RSTn, GPIO_IN);
    //gpio_set_dir(FPGA_CONFIG_CSn, GPIO_OUT);

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

    //gpio_put(FPGA_CONFIG_CSn, 1);

    //    gpio_pull_up(xxxx); // Just in Case I might need this
}

// This is to Set the DataPort GPIO8--GPIO15
static inline void f256k2_Set_FPGA_Data_Port(unsigned char value)
{
    uint32_t set_mask = ((uint32_t)value << 8) & FPGA_DATA_MASK;
    sio_hw->gpio_clr = FPGA_DATA_MASK;
    sio_hw->gpio_set = set_mask;
}

void f256k2_init_prg_fpga(void)
{
#if USE_PIO_FPGA
    fpga_pio_begin();
    fpga_pio_enable(false);
#endif
    // Bring Down Program
    gpio_put(FPGA_CONFIG_PRG, 0);
    printf("Programn is Low\n");
    do {
        gpio_put(FPGA_CONFIG_CCLK, 0);        // Bring Down the Clock
        gpio_put(FPGA_CONFIG_CCLK, 1);        // Bring Up the Clock
    }
    while (gpio_get(FPGA_CONFIG_INITn));       // Wait Till it gets down
    printf("Initn is Low\n");
    gpio_put(FPGA_CONFIG_PRG, 1);
    printf("Programn is High\n");
    do {
        gpio_put(FPGA_CONFIG_CCLK, 0);        // Bring Down the Clock
        gpio_put(FPGA_CONFIG_CCLK, 1);        // Bring Up the Clock
    }
    while (gpio_get(FPGA_CONFIG_INITn) == 0);       // Wait Till it gets up
    printf("Initn is Hi\n");
    gpio_put(FPGA_CONFIG_CCLK, 0);        // Bring Down the Clock
    gpio_put(FPGA_CONFIG_CCLK, 1);        // Bring Up the Clock
    //gpio_put(FPGA_CONFIG_CSn, 0);          // Bring Down the ChipSelect
}

void f256k2_prg_block_fpga(const uint8_t *ptr, unsigned int len)
{
    // printf("Programming chunk %d bytes\n", len);
    if (!ptr || len == 0) {
        return;
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
}
