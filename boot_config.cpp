#include "boot_config.h"

#include <cstdio>
#include <cstring>

#include "hardware/flash.h"
#include "hardware/sync.h"
#include "pico/stdlib.h"

namespace {

constexpr uintptr_t kXipBase = 0x10000000u;
constexpr uint32_t kMetadataOffsetA = 0x007fe000u;
constexpr uint32_t kMetadataOffsetB = 0x007ff000u;
constexpr uint32_t kMetadataMagic = 0x4d42324bu;  // "K2BM" little-endian.
constexpr uint16_t kMetadataVersion = 1;

struct __attribute__((packed)) StoredSelection {
    uint8_t source;
    uint8_t reserved[3];
    char path[kBootPathLength];
};

struct __attribute__((packed)) StoredFlashSlot {
    uint8_t valid;
    uint8_t reserved[3];
    uint32_t compressed_size;
    uint32_t compressed_crc;
    char label[kFlashLabelLength];
};

struct __attribute__((packed)) MetadataRecord {
    uint32_t magic;
    uint16_t version;
    uint16_t record_size;
    uint32_t sequence;
    StoredSelection selections[kBootContextCount];
    StoredFlashSlot slots[kBootContextCount];
    uint32_t crc32;
};

static_assert(sizeof(MetadataRecord) <= FLASH_SECTOR_SIZE,
              "boot metadata must fit in one erase sector");
static_assert((kMetadataOffsetA % FLASH_SECTOR_SIZE) == 0);
static_assert((kMetadataOffsetB % FLASH_SECTOR_SIZE) == 0);

MetadataRecord metadata;
uint32_t active_offset = kMetadataOffsetB;
BootSelection selections[kBootContextCount];
BootRuntimeStatus runtime_status{};
alignas(FLASH_PAGE_SIZE) uint8_t flash_sector_buffer[FLASH_SECTOR_SIZE];

uint32_t crc32_bytes(const uint8_t* data, size_t length)
{
    uint32_t crc = 0xffffffffu;
    for (size_t i = 0; i < length; ++i) {
        crc ^= data[i];
        for (unsigned bit = 0; bit < 8; ++bit) {
            crc = (crc >> 1) ^ (0xedb88320u & (0u - (crc & 1u)));
        }
    }
    return ~crc;
}

uint32_t record_crc(const MetadataRecord& record)
{
    return crc32_bytes(reinterpret_cast<const uint8_t*>(&record),
                       offsetof(MetadataRecord, crc32));
}

bool source_valid(uint8_t source)
{
    return source <= static_cast<uint8_t>(BootSource::Golden);
}

bool record_valid(const MetadataRecord& record)
{
    if (record.magic != kMetadataMagic || record.version != kMetadataVersion ||
        record.record_size != sizeof(MetadataRecord) ||
        record.crc32 != record_crc(record)) {
        return false;
    }
    for (const StoredSelection& selection : record.selections) {
        if (!source_valid(selection.source) ||
            std::memchr(selection.path, '\0', sizeof(selection.path)) == nullptr) {
            return false;
        }
    }
    for (const StoredFlashSlot& slot : record.slots) {
        if (slot.valid > 1 ||
            std::memchr(slot.label, '\0', sizeof(slot.label)) == nullptr) {
            return false;
        }
    }
    return true;
}

bool sequence_newer(uint32_t a, uint32_t b)
{
    return static_cast<int32_t>(a - b) > 0;
}

void set_defaults()
{
    std::memset(&metadata, 0, sizeof(metadata));
    metadata.magic = kMetadataMagic;
    metadata.version = kMetadataVersion;
    metadata.record_size = sizeof(MetadataRecord);
    for (StoredSelection& selection : metadata.selections) {
        selection.source = static_cast<uint8_t>(BootSource::Auto);
    }
}

void refresh_public_selections()
{
    for (size_t i = 0; i < kBootContextCount; ++i) {
        selections[i].source =
            static_cast<BootSource>(metadata.selections[i].source);
        std::snprintf(selections[i].path, sizeof(selections[i].path), "%s",
                      metadata.selections[i].path);
    }
}

bool write_record()
{
    metadata.sequence += 1;
    metadata.crc32 = record_crc(metadata);
    const uint32_t target_offset =
        active_offset == kMetadataOffsetA ? kMetadataOffsetB : kMetadataOffsetA;

    // Keep the erase-sector staging buffer in BSS: the RP2040 linker stack is
    // intentionally small and cannot safely hold a 4 KiB local array.
    std::memset(flash_sector_buffer, 0xff, sizeof(flash_sector_buffer));
    std::memcpy(flash_sector_buffer, &metadata, sizeof(metadata));

    uint32_t interrupts = save_and_disable_interrupts();
    flash_range_erase(target_offset, FLASH_SECTOR_SIZE);
    flash_range_program(target_offset, flash_sector_buffer, FLASH_SECTOR_SIZE);
    restore_interrupts(interrupts);

    const auto* readback = reinterpret_cast<const MetadataRecord*>(
        kXipBase + target_offset);
    if (!record_valid(*readback) || readback->sequence != metadata.sequence) {
        std::printf("Boot metadata flash verification failed at 0x%06lx\n",
                    static_cast<unsigned long>(target_offset));
        return false;
    }
    active_offset = target_offset;
    return true;
}

bool copy_string(char* destination, size_t capacity, const char* source)
{
    if (!destination || capacity == 0 || !source) {
        return false;
    }
    size_t length = std::strlen(source);
    if (length >= capacity) {
        return false;
    }
    std::memset(destination, 0, capacity);
    std::memcpy(destination, source, length);
    return true;
}

}  // namespace

void boot_config_init()
{
    const auto* record_a = reinterpret_cast<const MetadataRecord*>(
        kXipBase + kMetadataOffsetA);
    const auto* record_b = reinterpret_cast<const MetadataRecord*>(
        kXipBase + kMetadataOffsetB);
    const bool valid_a = record_valid(*record_a);
    const bool valid_b = record_valid(*record_b);

    if (valid_a && (!valid_b || sequence_newer(record_a->sequence,
                                               record_b->sequence))) {
        metadata = *record_a;
        active_offset = kMetadataOffsetA;
    } else if (valid_b) {
        metadata = *record_b;
        active_offset = kMetadataOffsetB;
    } else {
        set_defaults();
        active_offset = kMetadataOffsetB;
        std::printf("Boot metadata absent or invalid; using AUTO selections\n");
    }
    refresh_public_selections();
}

const BootSelection& boot_config_selection(uint8_t context)
{
    static const BootSelection invalid{BootSource::Auto, {0}};
    return context < kBootContextCount ? selections[context] : invalid;
}

bool boot_config_set_selection(uint8_t context, BootSource source,
                               const char* path)
{
    if (context >= kBootContextCount ||
        !source_valid(static_cast<uint8_t>(source))) {
        return false;
    }
    MetadataRecord previous = metadata;
    metadata.selections[context].source = static_cast<uint8_t>(source);
    const char* stored_path = source == BootSource::Sd ? path : "";
    if (!copy_string(metadata.selections[context].path,
                     sizeof(metadata.selections[context].path), stored_path)) {
        metadata = previous;
        return false;
    }
    if (!write_record()) {
        metadata = previous;
        return false;
    }
    refresh_public_selections();
    return true;
}

FlashSlotInfo boot_config_flash_slot(uint8_t slot)
{
    FlashSlotInfo result{};
    if (slot >= kBootContextCount) {
        return result;
    }
    const StoredFlashSlot& stored = metadata.slots[slot];
    result.valid = stored.valid != 0;
    result.compressed_size = stored.compressed_size;
    result.compressed_crc = stored.compressed_crc;
    std::snprintf(result.label, sizeof(result.label), "%s", stored.label);
    return result;
}

bool boot_config_set_flash_slot(uint8_t slot, uint32_t compressed_size,
                                uint32_t compressed_crc, const char* label)
{
    if (slot >= kBootContextCount || !label) {
        return false;
    }
    MetadataRecord previous = metadata;
    StoredFlashSlot& stored = metadata.slots[slot];
    stored.valid = 1;
    stored.compressed_size = compressed_size;
    stored.compressed_crc = compressed_crc;
    if (!copy_string(stored.label, sizeof(stored.label), label)) {
        metadata = previous;
        return false;
    }
    if (!write_record()) {
        metadata = previous;
        return false;
    }
    return true;
}

bool boot_config_clear_flash_slot(uint8_t slot)
{
    if (slot >= kBootContextCount) {
        return false;
    }
    MetadataRecord previous = metadata;
    std::memset(&metadata.slots[slot], 0, sizeof(metadata.slots[slot]));
    if (metadata.selections[slot].source ==
        static_cast<uint8_t>(BootSource::Flash)) {
        metadata.selections[slot].source = static_cast<uint8_t>(BootSource::Auto);
        metadata.selections[slot].path[0] = '\0';
    }
    if (!write_record()) {
        metadata = previous;
        return false;
    }
    refresh_public_selections();
    return true;
}

void boot_runtime_set(uint8_t context, BootSource source, const char* path)
{
    runtime_status.valid = context < kBootContextCount;
    runtime_status.context = context;
    runtime_status.source = source;
    if (!copy_string(runtime_status.path, sizeof(runtime_status.path),
                     path ? path : "")) {
        runtime_status.path[0] = '\0';
    }
}

const BootRuntimeStatus& boot_runtime_status()
{
    return runtime_status;
}
