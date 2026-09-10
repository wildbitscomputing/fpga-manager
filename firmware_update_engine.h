#pragma once

#include <cstddef>
#include <cstdint>

#include "firmware_image.h"

namespace firmware_update {

constexpr uint32_t kJournalMagic = 0x4a55324bu;  // "K2UJ" little-endian.
constexpr uint16_t kJournalFormatVersion = 1;
constexpr size_t kJournalRecordSize = 256;
constexpr uint32_t kFlashSectorSize = 4096;
constexpr uint32_t kFlashPageSize = 256;

enum class UpdateState : uint8_t {
    Confirmed = 1,
    Pending = 2,
    BackupReady = 3,
    Trial = 4,
};

enum class UpdateResult : uint8_t {
    None = 0,
    Installed = 1,
    RolledBack = 2,
    Rejected = 3,
    Recovered = 4,
};

enum class StorageResult : uint8_t {
    Ok,
    Interrupted,
    Error,
};

enum class UpdateCheckpoint : uint8_t {
    EraseVerified,
    PageVerified,
    PayloadVerified,
    ImageVerified,
    JournalVerified,
};

class FirmwareStorage {
  public:
    virtual ~FirmwareStorage() = default;

    virtual const uint8_t* read(uint32_t offset, size_t length) = 0;
    virtual StorageResult erase_sector(uint32_t offset) = 0;
    virtual StorageResult program_page(uint32_t offset,
                                       const uint8_t data[kFlashPageSize]) = 0;
    virtual StorageResult checkpoint(UpdateCheckpoint checkpoint) = 0;
};

struct __attribute__((packed)) UpdateJournalRecord {
    uint32_t magic;
    uint16_t format_version;
    uint16_t record_size;
    uint32_t sequence;
    uint8_t state;
    uint8_t board_revision;
    uint8_t result;
    uint8_t reserved0;
    char candidate_build_id[32];
    uint8_t candidate_payload_sha256[32];
    uint8_t reserved[172];
    uint32_t crc32;
};

static_assert(sizeof(UpdateJournalRecord) == kJournalRecordSize);
static_assert(offsetof(UpdateJournalRecord, crc32) == 252);

struct UpdateJournalStatus {
    bool valid;
    uint32_t flash_offset;
    UpdateJournalRecord record;
};

enum class BootDecision : uint8_t {
    StartActive,
    EnterUsbRecovery,
    Interrupted,
    FlashError,
};

bool update_journal_record_valid(const uint8_t* sector,
                                 BoardRevision expected_board);
UpdateJournalStatus read_update_journal(FirmwareStorage& storage,
                                        BoardRevision board);

// True only when the active image is valid and matches the candidate named by
// the durable TRIAL journal record.
bool running_firmware_is_trial(FirmwareStorage& storage,
                               BoardRevision board);

// Called by the application after it has completely written and verified the
// staging slot. A repeated call for the same pending candidate is idempotent.
StorageResult mark_update_pending(FirmwareStorage& storage,
                                  BoardRevision board);

// Called by a trial application only after it has reached its known-good
// startup point. A different or stale active image cannot confirm the trial.
StorageResult confirm_running_firmware(FirmwareStorage& storage,
                                       BoardRevision board);

// Runs the restartable loader state machine and returns only when an
// application may be started, recovery is required, or a storage operation
// was interrupted/failed.
BootDecision process_firmware_boot(FirmwareStorage& storage,
                                   BoardRevision board);

}  // namespace firmware_update
