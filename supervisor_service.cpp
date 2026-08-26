#include "supervisor_service.h"

#include <cstdio>
#include <cstring>

#include "boot_config.h"
#include "ff.h"
#include "hardware/adc.h"
#include "hardware/dma.h"
#include "hardware/flash.h"
#include "hardware/pio.h"
#include "hardware/sync.h"
#include "miniz.h"
#include "pico/stdlib.h"
#include "supervisor_spi.pio.h"

namespace {

constexpr uint8_t kRequestMagic = 0xA5;
constexpr uint8_t kResponseMagic = 0x5A;
constexpr uint8_t kProtocolVersion = 1;
constexpr size_t kFrameSize = 256;
constexpr size_t kHeaderSize = 16;
constexpr size_t kMaxPayload = kFrameSize - kHeaderSize;
constexpr uint8_t kFirmwareMajor = 1;
constexpr uint8_t kFirmwareMinor = 4;

constexpr uint kMisoPin = 0;
constexpr uint kCsPin = 1;
constexpr uint kClockPin = 2;
constexpr uint kMosiPin = 3;

constexpr uint8_t kCommandPoll = 0x00;
constexpr uint8_t kCommandPing = 0x01;
constexpr uint8_t kCommandImageBegin = 0x02;
constexpr uint8_t kCommandImageData = 0x03;
constexpr uint8_t kCommandImageEnd = 0x04;
constexpr uint8_t kCommandImageAbort = 0x05;
constexpr uint8_t kCommandReconfigure = 0x06;
constexpr uint8_t kCommandImageStatus = 0x07;
constexpr uint8_t kCommandCatalogBegin = 0x08;
constexpr uint8_t kCommandCatalogGet = 0x09;
constexpr uint8_t kCommandGetSelection = 0x0a;
constexpr uint8_t kCommandSetSelection = 0x0b;
constexpr uint8_t kCommandReconfigureSelected = 0x0c;
constexpr uint8_t kCommandClearFlash = 0x0d;
constexpr uint8_t kCommandGetBootStatus = 0x0e;

constexpr uint8_t kTargetSdRaw = 0;
constexpr uint8_t kTargetFlashGzip = 2;
constexpr uint32_t kFpgaImageSize = 9730652u;
constexpr uint32_t kFlashSlotSize = 2u * 1024u * 1024u;
constexpr uintptr_t kXipBase = 0x10000000u;
constexpr uint32_t kMutableFlashStart = 8u * 1024u * 1024u;
constexpr uint32_t kMutableFlashEnd = 16u * 1024u * 1024u;
constexpr uint32_t kFlashSlotOffsets[] = {
    0x00800000u, 0x00A00000u, 0x00C00000u, 0x00E00000u
};
static_assert(kFlashSlotOffsets[0] == kMutableFlashStart, "mutable bank start changed");
static_assert(kFlashSlotOffsets[3] + kFlashSlotSize == kMutableFlashEnd,
              "mutable bank must remain inside the upper 8 MiB");

constexpr const char* kImagePaths[] = {
    "0:/CNTX1/context1.bin",
    "0:/CNTX2/context2.bin",
    "0:/CNTX3/context3.bin",
    "0:/CNTX4/context4.bin",
};

enum Error : uint8_t {
    kErrorNone = 0,
    kErrorBadMagic = 1,
    kErrorProtocol = 2,
    kErrorLength = 3,
    kErrorUploadActive = 0x10,
    kErrorBadTarget = 0x11,
    kErrorBadSlot = 0x12,
    kErrorFileOpen = 0x13,
    kErrorFileWrite = 0x14,
    kErrorSize = 0x15,
    kErrorCrc = 0x16,
    kErrorFlashSize = 0x17,
    kErrorNoUpload = 0x18,
    kErrorGzip = 0x19,
    kErrorFlashVerify = 0x1a,
    kErrorMetadata = 0x1b,
    kErrorCatalog = 0x20,
    kErrorStaleCatalog = 0x21,
    kErrorBadSelection = 0x22,
};

enum ImageFormat : uint8_t {
    kFormatNone = 0,
    kFormatRaw = 1,
    kFormatGzip = 2,
};

constexpr uint8_t kCatalogFlagSelected = 0x01;
constexpr uint8_t kCatalogFlagRunning = 0x02;
constexpr size_t kCatalogCapacity = 32;

struct CatalogEntry {
    BootSource source;
    ImageFormat format;
    uint32_t size;
    char name[kBootPathLength];
};

PIO service_pio = pio1;
int service_sm = -1;
int tx_dma = -1;
int rx_dma = -1;
uint service_offset = 0;

uint8_t request[kFrameSize];
uint8_t response[kFrameSize];
uint32_t tx_words[kFrameSize];
uint32_t rx_words[kFrameSize];

bool sd_available = false;
bool upload_active = false;
uint8_t upload_target = 0;
uint8_t upload_slot = 0;
uint32_t upload_expected_size = 0;
uint32_t upload_expected_crc = 0;
uint32_t upload_size = 0;
mz_ulong upload_crc = MZ_CRC32_INIT;
FIL upload_file;
bool upload_file_open = false;
uint8_t flash_page[FLASH_PAGE_SIZE];
uint8_t flash_first_page[FLASH_PAGE_SIZE];
size_t flash_page_used = 0;
uint32_t flash_write_offset = 0;
bool flash_first_page_pending = false;
uint8_t upload_header[10];
size_t upload_header_used = 0;
uint8_t upload_tail[8];
uint8_t last_error = kErrorNone;
char upload_label[kFlashLabelLength];
CatalogEntry catalog[kCatalogCapacity];
uint16_t catalog_count = 0;
uint8_t catalog_context = 0;
uint32_t catalog_generation = 0;
uint8_t command_response[kMaxPayload];
DIR catalog_directory;
FILINFO catalog_file_info;
char catalog_path[kBootPathLength];
bool last_command_valid = false;
uint8_t last_command_sequence = 0;
uint8_t last_command = kCommandPoll;
uint16_t last_command_length = 0;
uint8_t last_command_payload[kMaxPayload];

uint16_t read_le16(const uint8_t* p)
{
    return static_cast<uint16_t>(p[0]) |
           (static_cast<uint16_t>(p[1]) << 8);
}

uint32_t read_le32(const uint8_t* p)
{
    return static_cast<uint32_t>(p[0]) |
           (static_cast<uint32_t>(p[1]) << 8) |
           (static_cast<uint32_t>(p[2]) << 16) |
           (static_cast<uint32_t>(p[3]) << 24);
}

void write_le16(uint8_t* p, uint16_t value)
{
    p[0] = static_cast<uint8_t>(value);
    p[1] = static_cast<uint8_t>(value >> 8);
}

void write_le32(uint8_t* p, uint32_t value)
{
    p[0] = static_cast<uint8_t>(value);
    p[1] = static_cast<uint8_t>(value >> 8);
    p[2] = static_cast<uint8_t>(value >> 16);
    p[3] = static_cast<uint8_t>(value >> 24);
}

char ascii_tolower(char c)
{
    return c >= 'A' && c <= 'Z' ? static_cast<char>(c - 'A' + 'a') : c;
}

bool ends_with_casefold(const char* text, const char* suffix)
{
    const size_t text_length = std::strlen(text);
    const size_t suffix_length = std::strlen(suffix);
    if (suffix_length > text_length) {
        return false;
    }
    text += text_length - suffix_length;
    for (size_t i = 0; i < suffix_length; ++i) {
        if (ascii_tolower(text[i]) != ascii_tolower(suffix[i])) {
            return false;
        }
    }
    return true;
}

bool strings_equal_casefold(const char* a, const char* b)
{
    while (*a && *b) {
        if (ascii_tolower(*a++) != ascii_tolower(*b++)) {
            return false;
        }
    }
    return *a == *b;
}

bool add_catalog_entry(BootSource source, ImageFormat format, uint32_t size,
                       const char* name)
{
    if (catalog_count >= kCatalogCapacity || !name ||
        std::strlen(name) >= sizeof(catalog[0].name)) {
        return false;
    }
    CatalogEntry& entry = catalog[catalog_count++];
    entry.source = source;
    entry.format = format;
    entry.size = size;
    std::snprintf(entry.name, sizeof(entry.name), "%s", name);
    return true;
}

bool flash_slot_has_gzip(uint8_t context)
{
    const uint8_t* data = reinterpret_cast<const uint8_t*>(
        kXipBase + kFlashSlotOffsets[context]);
    return data[0] == 0x1f && data[1] == 0x8b && data[2] == 8 &&
           (data[3] & 0xe0) == 0;
}

bool valid_sd_selection_path(uint8_t context, const char* path)
{
    if (!path || !path[0] || std::strstr(path, "..") != nullptr ||
        (!ends_with_casefold(path, ".gz") && !ends_with_casefold(path, ".bin"))) {
        return false;
    }
    char prefix[16];
    std::snprintf(prefix, sizeof(prefix), "CNTX%u/",
                  static_cast<unsigned>(context + 1));
    const char* relative = path;
    if (relative[0] == '0' && relative[1] == ':' && relative[2] == '/') {
        relative += 3;
    } else if (relative[0] == '/') {
        ++relative;
    }
    for (size_t i = 0; prefix[i]; ++i) {
        if (!relative[i] || ascii_tolower(relative[i]) != ascii_tolower(prefix[i])) {
            return false;
        }
    }
    return true;
}

void rebuild_catalog(uint8_t context)
{
    const absolute_time_t scan_start = get_absolute_time();
    uint16_t directory_entries = 0;
    uint16_t sd_images = 0;
    std::printf("Catalog scan start: context %u\n",
                static_cast<unsigned>(context + 1));
    catalog_count = 0;
    catalog_context = context;
    ++catalog_generation;
    if (catalog_generation == 0) {
        ++catalog_generation;
    }

    add_catalog_entry(BootSource::Auto, kFormatNone, 0,
                      "Automatic (SD, flash, golden)");

    if (sd_available) {
        char directory[16];
        std::snprintf(directory, sizeof(directory), "CNTX%u",
                      static_cast<unsigned>(context + 1));
        if (f_opendir(&catalog_directory, directory) == FR_OK) {
            for (;;) {
                // Always reserve the final two catalog positions for the
                // replaceable flash slot and immutable golden recovery.
                if (catalog_count >= kCatalogCapacity - 2) {
                    break;
                }
                FRESULT result = f_readdir(&catalog_directory,
                                           &catalog_file_info);
                if (result != FR_OK || catalog_file_info.fname[0] == '\0') {
                    if (result != FR_OK) {
                        std::printf("Catalog readdir failed: %u\n",
                                    static_cast<unsigned>(result));
                    }
                    break;
                }
                ++directory_entries;
                if ((catalog_file_info.fattrib & AM_DIR) != 0) {
                    continue;
                }
                ImageFormat format = kFormatNone;
                if (ends_with_casefold(catalog_file_info.fname, ".gz")) {
                    format = kFormatGzip;
                } else if (ends_with_casefold(catalog_file_info.fname, ".bin")) {
                    format = kFormatRaw;
                } else {
                    continue;
                }
                int length = std::snprintf(catalog_path, sizeof(catalog_path),
                                           "%s/%s", directory,
                                           catalog_file_info.fname);
                if (length > 0 &&
                    length < static_cast<int>(sizeof(catalog_path))) {
                    if (add_catalog_entry(
                            BootSource::Sd, format,
                            static_cast<uint32_t>(catalog_file_info.fsize),
                            catalog_path)) {
                        ++sd_images;
                    }
                }
            }
            f_closedir(&catalog_directory);
        } else {
            std::printf("Catalog opendir failed: %s\n", directory);
        }
    }

    if (flash_slot_has_gzip(context)) {
        FlashSlotInfo slot = boot_config_flash_slot(context);
        char label[kFlashLabelLength];
        if (slot.valid && slot.label[0]) {
            std::snprintf(label, sizeof(label), "%s", slot.label);
        } else {
            std::snprintf(label, sizeof(label), "Flash slot %u (unlabelled)",
                          static_cast<unsigned>(context + 1));
        }
        add_catalog_entry(BootSource::Flash, kFormatGzip,
                          slot.valid ? slot.compressed_size : 0, label);
    }

    char golden[48];
    std::snprintf(golden, sizeof(golden), "Embedded golden context %u",
                  static_cast<unsigned>(context == 1 ? 1 : context + 1));
    add_catalog_entry(BootSource::Golden, kFormatGzip, 0, golden);
    const int64_t scan_us =
        absolute_time_diff_us(scan_start, get_absolute_time());
    std::printf(
        "Catalog scan complete: %u entries (%u directory, %u SD images), "
        "%lld us\n",
        static_cast<unsigned>(catalog_count),
        static_cast<unsigned>(directory_entries),
        static_cast<unsigned>(sd_images), scan_us);
}

uint8_t catalog_flags(const CatalogEntry& entry)
{
    uint8_t flags = 0;
    const BootSelection& selection = boot_config_selection(catalog_context);
    if (selection.source == entry.source &&
        (entry.source != BootSource::Sd ||
         strings_equal_casefold(selection.path, entry.name))) {
        flags |= kCatalogFlagSelected;
    }
    const BootRuntimeStatus& running = boot_runtime_status();
    if (running.valid && running.context == catalog_context &&
        running.source == entry.source &&
        (entry.source != BootSource::Sd ||
         strings_equal_casefold(running.path, entry.name))) {
        flags |= kCatalogFlagRunning;
    }
    return flags;
}

uint8_t sample_adc(uint channel)
{
    adc_select_input(channel);
    return static_cast<uint8_t>(adc_read() >> 4);
}

uint8_t status_byte()
{
    uint8_t status = 0x01;
    if (upload_active) {
        status |= 0x02;
    }
    if (sd_available) {
        status |= 0x04;
    }
    if (upload_active && upload_target == kTargetFlashGzip) {
        status |= 0x08;
    }
    if (last_error != kErrorNone) {
        status |= 0x80;
    }
    return status;
}

void prepare_response(uint8_t sequence)
{
    std::memset(response, 0, sizeof(response));
    response[0] = kResponseMagic;
    response[1] = kProtocolVersion;
    response[2] = sequence;
    response[3] = status_byte();
    response[4] = last_error;
    response[7] = static_cast<uint8_t>(kMaxPayload);
    response[8] = static_cast<uint8_t>(kMaxPayload >> 8);
    response[9] = sample_adc(0);
    response[10] = sample_adc(1);
    response[11] = sample_adc(2);
    response[12] = sample_adc(3);
    response[13] = kFirmwareMajor;
    response[14] = kFirmwareMinor;
}

void reset_transport()
{
    pio_sm_set_enabled(service_pio, service_sm, false);
    pio_sm_clear_fifos(service_pio, service_sm);
    pio_sm_restart(service_pio, service_sm);
    pio_sm_set_enabled(service_pio, service_sm, true);
}

void transfer_frame()
{
    for (size_t i = 0; i < kFrameSize; ++i) {
        tx_words[i] = static_cast<uint32_t>(response[i]) << 24;
        rx_words[i] = 0;
    }

    reset_transport();

    dma_channel_config tx_config = dma_channel_get_default_config(tx_dma);
    channel_config_set_transfer_data_size(&tx_config, DMA_SIZE_32);
    channel_config_set_read_increment(&tx_config, true);
    channel_config_set_write_increment(&tx_config, false);
    channel_config_set_dreq(&tx_config, pio_get_dreq(service_pio, service_sm, true));
    dma_channel_configure(tx_dma, &tx_config, &service_pio->txf[service_sm],
                          tx_words, kFrameSize, false);

    dma_channel_config rx_config = dma_channel_get_default_config(rx_dma);
    channel_config_set_transfer_data_size(&rx_config, DMA_SIZE_32);
    channel_config_set_read_increment(&rx_config, false);
    channel_config_set_write_increment(&rx_config, true);
    channel_config_set_dreq(&rx_config, pio_get_dreq(service_pio, service_sm, false));
    dma_channel_configure(rx_dma, &rx_config, rx_words,
                          &service_pio->rxf[service_sm], kFrameSize, false);

    dma_start_channel_mask((1u << tx_dma) | (1u << rx_dma));
    dma_channel_wait_for_finish_blocking(rx_dma);
    while (!gpio_get(kCsPin)) {
        tight_loop_contents();
    }
    dma_channel_abort(tx_dma);

    for (size_t i = 0; i < kFrameSize; ++i) {
        request[i] = static_cast<uint8_t>(rx_words[i]);
    }
}

void close_upload_file()
{
    if (upload_file_open) {
        f_close(&upload_file);
        upload_file_open = false;
    }
}

void abort_upload()
{
    close_upload_file();
    if (upload_target == kTargetSdRaw && upload_slot < 4) {
        char temporary[96];
        std::snprintf(temporary, sizeof(temporary), "%s.upload", kImagePaths[upload_slot]);
        f_unlink(temporary);
    }
    upload_active = false;
    flash_page_used = 0;
    flash_first_page_pending = false;
}

bool program_and_verify_flash_page(uint32_t offset, const uint8_t* page)
{
    const uint32_t flash_offset = kFlashSlotOffsets[upload_slot] + offset;
    uint32_t interrupts = save_and_disable_interrupts();
    flash_range_program(flash_offset, page, FLASH_PAGE_SIZE);
    restore_interrupts(interrupts);

    const uint8_t* readback = reinterpret_cast<const uint8_t*>(kXipBase + flash_offset);
    if (std::memcmp(readback, page, FLASH_PAGE_SIZE) != 0) {
        last_error = kErrorFlashVerify;
        return false;
    }
    return true;
}

bool flash_program_page()
{
    if (flash_page_used == 0) {
        return true;
    }
    std::memset(flash_page + flash_page_used, 0xFF, FLASH_PAGE_SIZE - flash_page_used);
    if (flash_write_offset == 0) {
        std::memcpy(flash_first_page, flash_page, FLASH_PAGE_SIZE);
        flash_first_page_pending = true;
    } else if (!program_and_verify_flash_page(flash_write_offset, flash_page)) {
        return false;
    }
    flash_write_offset += FLASH_PAGE_SIZE;
    flash_page_used = 0;
    return true;
}

bool flash_commit_first_page()
{
    if (!flash_first_page_pending) {
        last_error = kErrorFlashVerify;
        return false;
    }
    if (!program_and_verify_flash_page(0, flash_first_page)) {
        return false;
    }
    flash_first_page_pending = false;
    return true;
}

void capture_upload_bytes(const uint8_t* payload, size_t length)
{
    for (size_t i = 0; i < length && upload_header_used < sizeof(upload_header); ++i) {
        upload_header[upload_header_used++] = payload[i];
    }
    if (length >= sizeof(upload_tail)) {
        std::memcpy(upload_tail, payload + length - sizeof(upload_tail), sizeof(upload_tail));
        return;
    }
    for (size_t i = 0; i < length; ++i) {
        std::memmove(upload_tail, upload_tail + 1, sizeof(upload_tail) - 1);
        upload_tail[sizeof(upload_tail) - 1] = payload[i];
    }
}

bool uploaded_gzip_shape_valid()
{
    return upload_size >= 18 && upload_header_used == sizeof(upload_header) &&
           upload_header[0] == 0x1f && upload_header[1] == 0x8b &&
           upload_header[2] == 8 && (upload_header[3] & 0xe0) == 0 &&
           read_le32(upload_tail + 4) == kFpgaImageSize;
}

bool begin_upload(const uint8_t* payload, size_t length)
{
    if (upload_active) {
        last_error = kErrorUploadActive;
        return false;
    }
    if (length < 10) {
        last_error = kErrorLength;
        return false;
    }

    upload_label[0] = '\0';
    if (length > 10) {
        const size_t label_length = payload[10];
        if (length != 11 + label_length || label_length == 0 ||
            label_length >= sizeof(upload_label)) {
            last_error = kErrorLength;
            return false;
        }
        std::memcpy(upload_label, payload + 11, label_length);
        upload_label[label_length] = '\0';
    }

    upload_target = payload[0];
    upload_slot = payload[1];
    upload_expected_size = read_le32(payload + 2);
    upload_expected_crc = read_le32(payload + 6);
    upload_size = 0;
    upload_crc = MZ_CRC32_INIT;
    flash_page_used = 0;
    flash_write_offset = 0;
    flash_first_page_pending = false;
    upload_header_used = 0;
    std::memset(upload_header, 0, sizeof(upload_header));
    std::memset(upload_tail, 0, sizeof(upload_tail));

    if (upload_slot >= 4) {
        last_error = kErrorBadSlot;
        return false;
    }

    if (!upload_label[0]) {
        std::snprintf(upload_label, sizeof(upload_label), "Uploaded flash slot %u",
                      static_cast<unsigned>(upload_slot + 1));
    }

    if (upload_target == kTargetSdRaw) {
        if (!sd_available) {
            last_error = kErrorBadTarget;
            return false;
        }
        char temporary[96];
        std::snprintf(temporary, sizeof(temporary), "%s.upload", kImagePaths[upload_slot]);
        if (f_open(&upload_file, temporary, FA_CREATE_ALWAYS | FA_WRITE) != FR_OK) {
            last_error = kErrorFileOpen;
            return false;
        }
        upload_file_open = true;
    } else if (upload_target == kTargetFlashGzip) {
        if (upload_expected_size < 18 || upload_expected_size > kFlashSlotSize) {
            last_error = kErrorFlashSize;
            return false;
        }
        uint32_t interrupts = save_and_disable_interrupts();
        flash_range_erase(kFlashSlotOffsets[upload_slot], kFlashSlotSize);
        restore_interrupts(interrupts);
    } else {
        last_error = kErrorBadTarget;
        return false;
    }

    upload_active = true;
    last_error = kErrorNone;
    return true;
}

bool write_upload(const uint8_t* payload, size_t length)
{
    if (!upload_active) {
        last_error = kErrorNoUpload;
        return false;
    }
    if (upload_size + length > upload_expected_size) {
        last_error = kErrorSize;
        return false;
    }

    if (upload_target == kTargetSdRaw) {
        UINT written = 0;
        if (f_write(&upload_file, payload, static_cast<UINT>(length), &written) != FR_OK ||
            written != length) {
            last_error = kErrorFileWrite;
            return false;
        }
    } else {
        capture_upload_bytes(payload, length);
        size_t consumed = 0;
        while (consumed < length) {
            size_t room = FLASH_PAGE_SIZE - flash_page_used;
            size_t amount = length - consumed;
            if (amount > room) {
                amount = room;
            }
            std::memcpy(flash_page + flash_page_used, payload + consumed, amount);
            flash_page_used += amount;
            consumed += amount;
            if (flash_page_used == FLASH_PAGE_SIZE) {
                if (!flash_program_page()) {
                    return false;
                }
            }
        }
    }

    upload_crc = mz_crc32(upload_crc, payload, length);
    upload_size += static_cast<uint32_t>(length);
    last_error = kErrorNone;
    return true;
}

bool finish_sd_upload()
{
    if (f_sync(&upload_file) != FR_OK) {
        last_error = kErrorFileWrite;
        close_upload_file();
        return false;
    }
    close_upload_file();

    char temporary[96];
    char backup[96];
    char compressed[96];
    std::snprintf(temporary, sizeof(temporary), "%s.upload", kImagePaths[upload_slot]);
    std::snprintf(backup, sizeof(backup), "%s.old", kImagePaths[upload_slot]);
    f_unlink(backup);
    f_rename(kImagePaths[upload_slot], backup);
    if (f_rename(temporary, kImagePaths[upload_slot]) != FR_OK) {
        f_rename(backup, kImagePaths[upload_slot]);
        last_error = kErrorFileWrite;
        return false;
    }
    f_unlink(backup);
    std::snprintf(compressed, sizeof(compressed), "%s.gz", kImagePaths[upload_slot]);
    f_unlink(compressed);
    return true;
}

bool finish_upload()
{
    if (!upload_active) {
        last_error = kErrorNoUpload;
        return false;
    }
    if (upload_size != upload_expected_size) {
        std::printf("Upload size mismatch: received %lu, expected %lu\n",
                    static_cast<unsigned long>(upload_size),
                    static_cast<unsigned long>(upload_expected_size));
        last_error = kErrorSize;
        return false;
    }
    if (static_cast<uint32_t>(upload_crc) != upload_expected_crc) {
        last_error = kErrorCrc;
        return false;
    }
    if (upload_target == kTargetFlashGzip && !uploaded_gzip_shape_valid()) {
        last_error = kErrorGzip;
        return false;
    }

    bool ok = true;
    if (upload_target == kTargetSdRaw) {
        ok = finish_sd_upload();
    } else {
        ok = flash_program_page() && flash_commit_first_page();
        if (ok && !boot_config_set_flash_slot(upload_slot, upload_size,
                                               upload_expected_crc,
                                               upload_label)) {
            last_error = kErrorMetadata;
            ok = false;
        }
    }
    if (ok) {
        upload_active = false;
        last_error = kErrorNone;
    }
    return ok;
}

bool process_request(SupervisorReconfigureRequest* reconfigure_request)
{
    if (request[0] != kRequestMagic) {
        last_error = kErrorBadMagic;
        return false;
    }
    if (request[1] != kProtocolVersion) {
        last_error = kErrorProtocol;
        prepare_response(request[2]);
        return false;
    }

    const uint8_t sequence = request[2];
    const uint8_t command = request[3];
    const size_t length = read_le16(request + 4);
    if (length > kMaxPayload) {
        last_error = kErrorLength;
        prepare_response(sequence);
        return false;
    }

    // The FPGA retransmits an in-flight command with the same sequence until
    // it receives the matching pipelined response. Do not execute a repeated
    // command twice; leave its already-prepared response intact so the retry
    // transaction returns the same result. Require the same length and payload
    // too, so sequence reuse cannot suppress a genuinely new command. A POLL
    // ends the retry window.
    if (command != kCommandPoll && last_command_valid &&
        sequence == last_command_sequence && command == last_command &&
        length == last_command_length &&
        std::memcmp(request + kHeaderSize, last_command_payload, length) == 0) {
        return false;
    }
    if (command == kCommandPoll) {
        last_command_valid = false;
    }

    bool reconfigure = false;
    size_t response_length = 0;
    std::memset(command_response, 0, sizeof(command_response));
    switch (command) {
    case kCommandPoll:
    case kCommandPing:
        last_error = kErrorNone;
        break;
    case kCommandImageBegin:
        begin_upload(request + kHeaderSize, length);
        break;
    case kCommandImageData:
        write_upload(request + kHeaderSize, length);
        break;
    case kCommandImageEnd:
        finish_upload();
        break;
    case kCommandImageAbort:
        abort_upload();
        last_error = kErrorNone;
        break;
    case kCommandImageStatus:
        if (length != 0) {
            last_error = kErrorLength;
        } else {
            last_error = kErrorNone;
        }
        break;
    case kCommandReconfigure:
        if (length != 1 || request[kHeaderSize] >= 4) {
            last_error = kErrorBadSlot;
        } else if (upload_active) {
            last_error = kErrorUploadActive;
        } else {
            reconfigure_request->context = request[kHeaderSize];
            last_error = kErrorNone;
            reconfigure = true;
        }
        break;
    case kCommandCatalogBegin:
        if (length != 5 || request[kHeaderSize + 4] >= kBootContextCount) {
            last_error = kErrorBadSlot;
        } else {
            const uint32_t nonce = read_le32(request + kHeaderSize);
            rebuild_catalog(request[kHeaderSize + 4]);
            write_le32(command_response, nonce);
            write_le32(command_response + 4, catalog_generation);
            write_le16(command_response + 8, catalog_count);
            command_response[10] = catalog_context;
            response_length = 11;
            last_error = kErrorNone;
        }
        break;
    case kCommandCatalogGet:
        if (length != 10) {
            last_error = kErrorLength;
        } else {
            const uint32_t nonce = read_le32(request + kHeaderSize);
            const uint32_t generation = read_le32(request + kHeaderSize + 4);
            const uint16_t index = read_le16(request + kHeaderSize + 8);
            if (generation != catalog_generation) {
                last_error = kErrorStaleCatalog;
            } else if (index >= catalog_count) {
                last_error = kErrorCatalog;
            } else {
                const CatalogEntry& entry = catalog[index];
                const size_t name_length = std::strlen(entry.name);
                write_le32(command_response, nonce);
                write_le32(command_response + 4, catalog_generation);
                write_le16(command_response + 8, index);
                command_response[10] = static_cast<uint8_t>(entry.source);
                command_response[11] = static_cast<uint8_t>(entry.format);
                command_response[12] = catalog_context;
                command_response[13] = catalog_flags(entry);
                write_le32(command_response + 14, entry.size);
                command_response[18] = static_cast<uint8_t>(name_length);
                std::memcpy(command_response + 19, entry.name, name_length);
                response_length = 19 + name_length;
                last_error = kErrorNone;
            }
        }
        break;
    case kCommandGetSelection:
        if (length != 5 || request[kHeaderSize + 4] >= kBootContextCount) {
            last_error = kErrorBadSlot;
        } else {
            const uint32_t nonce = read_le32(request + kHeaderSize);
            const uint8_t context = request[kHeaderSize + 4];
            const BootSelection& selection = boot_config_selection(context);
            const size_t path_length = selection.source == BootSource::Sd
                                           ? std::strlen(selection.path)
                                           : 0;
            write_le32(command_response, nonce);
            command_response[4] = context;
            command_response[5] = static_cast<uint8_t>(selection.source);
            command_response[6] = static_cast<uint8_t>(path_length);
            std::memcpy(command_response + 7, selection.path, path_length);
            response_length = 7 + path_length;
            last_error = kErrorNone;
        }
        break;
    case kCommandSetSelection:
        if (length < 7) {
            last_error = kErrorLength;
        } else {
            const uint32_t nonce = read_le32(request + kHeaderSize);
            const uint8_t context = request[kHeaderSize + 4];
            const auto source = static_cast<BootSource>(request[kHeaderSize + 5]);
            const size_t path_length = request[kHeaderSize + 6];
            if (context >= kBootContextCount ||
                static_cast<uint8_t>(source) >
                    static_cast<uint8_t>(BootSource::Golden) ||
                length != 7 + path_length || path_length >= kBootPathLength) {
                last_error = kErrorBadSelection;
                break;
            }
            char path[kBootPathLength]{};
            std::memcpy(path, request + kHeaderSize + 7, path_length);
            if ((source == BootSource::Sd &&
                 !valid_sd_selection_path(context, path)) ||
                (source != BootSource::Sd && path_length != 0) ||
                (source == BootSource::Flash && !flash_slot_has_gzip(context))) {
                last_error = kErrorBadSelection;
                break;
            }
            if (!boot_config_set_selection(context, source, path)) {
                last_error = kErrorMetadata;
                break;
            }
            write_le32(command_response, nonce);
            command_response[4] = context;
            command_response[5] = static_cast<uint8_t>(source);
            response_length = 6;
            last_error = kErrorNone;
        }
        break;
    case kCommandReconfigureSelected:
        if (length != 5 || request[kHeaderSize + 4] >= kBootContextCount) {
            last_error = kErrorBadSlot;
        } else if (upload_active) {
            last_error = kErrorUploadActive;
        } else {
            const uint32_t nonce = read_le32(request + kHeaderSize);
            reconfigure_request->context = request[kHeaderSize + 4];
            write_le32(command_response, nonce);
            command_response[4] = reconfigure_request->context;
            response_length = 5;
            last_error = kErrorNone;
            reconfigure = true;
        }
        break;
    case kCommandClearFlash:
        if (length != 5 || request[kHeaderSize + 4] >= kBootContextCount) {
            last_error = kErrorBadSlot;
        } else if (upload_active) {
            last_error = kErrorUploadActive;
        } else {
            const uint32_t nonce = read_le32(request + kHeaderSize);
            const uint8_t context = request[kHeaderSize + 4];
            uint32_t interrupts = save_and_disable_interrupts();
            flash_range_erase(kFlashSlotOffsets[context], FLASH_SECTOR_SIZE);
            restore_interrupts(interrupts);
            bool erased = true;
            const uint8_t* readback = reinterpret_cast<const uint8_t*>(
                kXipBase + kFlashSlotOffsets[context]);
            for (size_t i = 0; i < FLASH_SECTOR_SIZE; ++i) {
                if (readback[i] != 0xff) {
                    erased = false;
                    break;
                }
            }
            if (!erased) {
                last_error = kErrorFlashVerify;
            } else if (!boot_config_clear_flash_slot(context)) {
                last_error = kErrorMetadata;
            } else {
                write_le32(command_response, nonce);
                command_response[4] = context;
                response_length = 5;
                last_error = kErrorNone;
            }
        }
        break;
    case kCommandGetBootStatus:
        if (length != 4) {
            last_error = kErrorLength;
        } else {
            const uint32_t nonce = read_le32(request + kHeaderSize);
            const BootRuntimeStatus& status = boot_runtime_status();
            const size_t path_length = status.valid ? std::strlen(status.path) : 0;
            write_le32(command_response, nonce);
            command_response[4] = status.valid ? 1 : 0;
            command_response[5] = status.context;
            command_response[6] = static_cast<uint8_t>(status.source);
            command_response[7] = static_cast<uint8_t>(path_length);
            std::memcpy(command_response + 8, status.path, path_length);
            response_length = 8 + path_length;
            last_error = kErrorNone;
        }
        break;
    default:
        last_error = kErrorProtocol;
        break;
    }

    prepare_response(sequence);
    if (response_length != 0) {
        write_le16(response + 5, static_cast<uint16_t>(response_length));
        std::memcpy(response + kHeaderSize, command_response, response_length);
    } else if (command == kCommandImageData || command == kCommandImageEnd ||
        command == kCommandImageStatus) {
        write_le16(response + 5, 4);
        write_le32(response + kHeaderSize, upload_size);
    }
    if (command != kCommandPoll) {
        last_command_sequence = sequence;
        last_command = command;
        last_command_length = static_cast<uint16_t>(length);
        std::memcpy(last_command_payload, request + kHeaderSize, length);
        last_command_valid = true;
    }
    return reconfigure;
}

}  // namespace

void supervisor_service_init(bool sd_mounted)
{
    sd_available = sd_mounted;

    adc_init();
    adc_gpio_init(26);
    adc_gpio_init(27);
    adc_gpio_init(28);
    adc_gpio_init(29);

    service_sm = pio_claim_unused_sm(service_pio, true);
    tx_dma = dma_claim_unused_channel(true);
    rx_dma = dma_claim_unused_channel(true);
    service_offset = pio_add_program(service_pio, &supervisor_spi_program);

    pio_sm_config config = supervisor_spi_program_get_default_config(service_offset);
    sm_config_set_out_pins(&config, kMisoPin, 1);
    sm_config_set_in_pins(&config, kMosiPin);
    sm_config_set_out_shift(&config, false, true, 8);
    sm_config_set_in_shift(&config, false, true, 8);
    pio_gpio_init(service_pio, kMisoPin);
    pio_gpio_init(service_pio, kCsPin);
    pio_gpio_init(service_pio, kClockPin);
    pio_gpio_init(service_pio, kMosiPin);
    pio_sm_set_consecutive_pindirs(service_pio, service_sm, kMisoPin, 1, true);
    pio_sm_set_consecutive_pindirs(service_pio, service_sm, kCsPin, 3, false);
    pio_sm_init(service_pio, service_sm, service_offset, &config);
    pio_sm_set_enabled(service_pio, service_sm, true);

    last_error = kErrorNone;
    last_command_valid = false;
    prepare_response(0);
}

bool supervisor_service_once(SupervisorReconfigureRequest* request)
{
    transfer_frame();
    return process_request(request);
}
