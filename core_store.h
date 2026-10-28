#pragma once

#include "firmware_update_engine.h"

namespace core_store
{
constexpr uint32_t kPoolOffset = 0x800000;
constexpr uint32_t kBlockSize = 0x10000;
constexpr uint32_t kBlockCount = 128;
constexpr uint32_t kCapacity = kBlockSize * kBlockCount;
constexpr uint32_t kLegacySlotSize = 0x200000;
// The guard is beyond the end (0x7e2000) of legacy flat factory images,
// whose address gaps may contain zeros. It is programmed once, never erased.
constexpr uint32_t kGuardOffset = 0x7f0000;
// Allocation records each have a dedicated physical 64 KiB erase block.
constexpr uint32_t kRecordA = 0x7c0000;
constexpr uint32_t kRecordB = 0x7d0000;
constexpr uint32_t kMagic = 0x3241434b; // KCA2
constexpr uint16_t kFormat = 2;
constexpr uint32_t kContextCount = 4;
constexpr uint32_t kLabelSize = 128;

enum class Kind : uint8_t
{
    Empty,
    Gzip,
    Reserved
};
enum class State
{
    Legacy,
    Ready,
    Corrupt
};
enum class Result
{
    Ok,
    Invalid,
    NoSpace,
    Busy,
    StorageError
};
struct Image
{
    Kind kind;
    uint8_t count;
    uint16_t reserved;
    uint32_t size;
    uint32_t crc;
    char label[kLabelSize];
    uint8_t blocks[kBlockCount];
};
struct Record
{
    uint32_t magic;
    uint16_t format;
    uint16_t size;
    uint32_t sequence;
    Image images[kContextCount];
    uint32_t crc;
};
static_assert(sizeof(Record) < firmware_update::kFlashSectorSize);
static_assert(kGuardOffset >= firmware_update::kUpdateJournalOffsetB + firmware_update::kFlashSectorSize);
static_assert(kGuardOffset + firmware_update::kFlashSectorSize <= firmware_update::kBootMetadataOffsetA);
static_assert(kRecordB + kBlockSize <= firmware_update::kUpdateJournalOffsetA);

bool record_valid(const Record &record);
// Conservative compatibility fence, including torn/corrupt metadata.
bool requires_pool_firmware(firmware_update::FirmwareStorage &storage);

class Store
{
  public:
    explicit Store(firmware_update::FirmwareStorage &storage) : storage_(storage) {}
    State load();
    State state() const
    {
        return state_;
    }
    const Image &image(uint8_t slot) const;
    uint32_t free_bytes() const;
    Result migrate(const Image (&images)[kContextCount]);
    Result begin(uint8_t slot, uint32_t size, const char *label);
    Result erase_next(); // One 64 KiB allocation block per call.
    bool erased() const
    {
        return active_ && erased_blocks_ == pending_.count;
    }
    uint32_t erase_size() const
    {
        return pending_.count * kBlockSize;
    }
    Result write_page(uint32_t offset, const uint8_t *page);
    Result commit(uint32_t crc);
    void abort()
    {
        active_ = false;
    }
    Result clear(uint8_t slot);
    const uint8_t *span(uint8_t slot, uint32_t offset, size_t *length) const;
    bool read(uint8_t slot, uint32_t offset, void *dest, size_t length) const;

  private:
    bool persist();
    bool prepare_mutation();
    bool guard();
    bool program(uint32_t offset, const uint8_t *bytes);
    firmware_update::FirmwareStorage &storage_;
    Record record_{};
    Image pending_{};
    State state_ = State::Legacy;
    uint32_t current_offset_ = kRecordB;
    uint32_t written_ = 0;
    uint8_t erased_blocks_ = 0, pending_slot_ = 0;
    bool active_ = false;
    alignas(256) uint8_t page_[256]{};
};
} // namespace core_store
