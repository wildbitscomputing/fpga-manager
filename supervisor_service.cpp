#include "supervisor_service.h"

#include <cstdio>
#include <cstring>

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
constexpr uint8_t kFirmwareMinor = 0;

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

constexpr uint8_t kTargetSdRaw = 0;
constexpr uint8_t kTargetFlashLz4 = 1;
constexpr uint32_t kFlashSlotSize = 2u * 1024u * 1024u;
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
size_t flash_page_used = 0;
uint32_t flash_write_offset = 0;
uint8_t last_error = kErrorNone;

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
    if (upload_active && upload_target == kTargetFlashLz4) {
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
}

bool flash_program_page()
{
    if (flash_page_used == 0) {
        return true;
    }
    std::memset(flash_page + flash_page_used, 0xFF, FLASH_PAGE_SIZE - flash_page_used);
    uint32_t interrupts = save_and_disable_interrupts();
    flash_range_program(kFlashSlotOffsets[upload_slot] + flash_write_offset,
                        flash_page, FLASH_PAGE_SIZE);
    restore_interrupts(interrupts);
    flash_write_offset += FLASH_PAGE_SIZE;
    flash_page_used = 0;
    return true;
}

bool begin_upload(const uint8_t* payload, size_t length)
{
    if (upload_active) {
        last_error = kErrorUploadActive;
        return false;
    }
    if (length != 10) {
        last_error = kErrorLength;
        return false;
    }

    upload_target = payload[0];
    upload_slot = payload[1];
    upload_expected_size = read_le32(payload + 2);
    upload_expected_crc = read_le32(payload + 6);
    upload_size = 0;
    upload_crc = MZ_CRC32_INIT;
    flash_page_used = 0;
    flash_write_offset = 0;

    if (upload_slot >= 4) {
        last_error = kErrorBadSlot;
        return false;
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
    } else if (upload_target == kTargetFlashLz4) {
        if (upload_expected_size > kFlashSlotSize) {
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
                flash_program_page();
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
    std::snprintf(compressed, sizeof(compressed), "%s.lz4", kImagePaths[upload_slot]);
    f_unlink(compressed);
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
        last_error = kErrorSize;
        return false;
    }
    if (static_cast<uint32_t>(upload_crc) != upload_expected_crc) {
        last_error = kErrorCrc;
        return false;
    }

    bool ok = true;
    if (upload_target == kTargetSdRaw) {
        ok = finish_sd_upload();
    } else {
        ok = flash_program_page();
    }
    if (ok) {
        upload_active = false;
        last_error = kErrorNone;
    }
    return ok;
}

bool process_request(uint8_t* reconfigure_slot)
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

    bool reconfigure = false;
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
    case kCommandReconfigure:
        if (length != 1 || request[kHeaderSize] >= 4) {
            last_error = kErrorBadSlot;
        } else if (upload_active) {
            last_error = kErrorUploadActive;
        } else {
            *reconfigure_slot = request[kHeaderSize];
            last_error = kErrorNone;
            reconfigure = true;
        }
        break;
    default:
        last_error = kErrorProtocol;
        break;
    }

    prepare_response(sequence);
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
    prepare_response(0);
}

bool supervisor_service_once(uint8_t* reconfigure_slot)
{
    transfer_frame();
    return process_request(reconfigure_slot);
}
