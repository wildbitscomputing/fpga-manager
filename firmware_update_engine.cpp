#include "firmware_update_engine.h"

#include <algorithm>
#include <cstring>

#include "firmware_update_layout.h"
#include "sha256.h"

namespace firmware_update {
namespace {

enum class StepResult : uint8_t {
    Ok,
    Interrupted,
    Error,
};

StepResult step_result(StorageResult result)
{
    switch (result) {
        case StorageResult::Ok:
            return StepResult::Ok;
        case StorageResult::Interrupted:
            return StepResult::Interrupted;
        case StorageResult::Error:
            return StepResult::Error;
    }
    return StepResult::Error;
}

StorageResult storage_result(StepResult result)
{
    switch (result) {
        case StepResult::Ok:
            return StorageResult::Ok;
        case StepResult::Interrupted:
            return StorageResult::Interrupted;
        case StepResult::Error:
            return StorageResult::Error;
    }
    return StorageResult::Error;
}

BootDecision boot_result(StepResult result)
{
    return result == StepResult::Interrupted ? BootDecision::Interrupted
                                             : BootDecision::FlashError;
}

bool sequence_newer(uint32_t a, uint32_t b)
{
    return static_cast<int32_t>(a - b) > 0;
}

bool state_valid(uint8_t state)
{
    return state >= static_cast<uint8_t>(UpdateState::Confirmed) &&
           state <= static_cast<uint8_t>(UpdateState::Trial);
}

bool result_valid(uint8_t result)
{
    return result <= static_cast<uint8_t>(UpdateResult::Recovered);
}

uint32_t journal_crc(const UpdateJournalRecord& record)
{
    return firmware_crc32(reinterpret_cast<const uint8_t*>(&record),
                          offsetof(UpdateJournalRecord, crc32));
}

const uint8_t* image_at(FirmwareStorage& storage, uint32_t offset)
{
    return storage.read(offset, kApplicationSlotSize);
}

bool image_valid(FirmwareStorage& storage, uint32_t offset,
                 BoardRevision board)
{
    const uint8_t* image = image_at(storage, offset);
    return image && validate_firmware_image(image, board) == ImageValidation::Ok;
}

const FirmwareImageManifest* manifest_at(FirmwareStorage& storage,
                                         uint32_t offset)
{
    return reinterpret_cast<const FirmwareImageManifest*>(
        storage.read(offset, sizeof(FirmwareImageManifest)));
}

bool candidate_matches(const UpdateJournalRecord& record,
                       const FirmwareImageManifest& manifest)
{
    return std::memcmp(record.candidate_build_id, manifest.build_id,
                       sizeof(record.candidate_build_id)) == 0 &&
           std::memcmp(record.candidate_payload_sha256,
                       manifest.payload_sha256,
                       sizeof(record.candidate_payload_sha256)) == 0;
}

void set_candidate(UpdateJournalRecord& record,
                   const FirmwareImageManifest& manifest)
{
    std::memcpy(record.candidate_build_id, manifest.build_id,
                sizeof(record.candidate_build_id));
    std::memcpy(record.candidate_payload_sha256, manifest.payload_sha256,
                sizeof(record.candidate_payload_sha256));
}

StepResult verify_erased(FirmwareStorage& storage, uint32_t offset)
{
    const uint8_t* data = storage.read(offset, kFlashSectorSize);
    if (!data) {
        return StepResult::Error;
    }
    for (size_t i = 0; i < kFlashSectorSize; ++i) {
        if (data[i] != 0xff) {
            return StepResult::Error;
        }
    }
    return step_result(storage.checkpoint(UpdateCheckpoint::EraseVerified));
}

StepResult verify_page(FirmwareStorage& storage, uint32_t offset,
                       const uint8_t expected[kFlashPageSize])
{
    const uint8_t* data = storage.read(offset, kFlashPageSize);
    if (!data || std::memcmp(data, expected, kFlashPageSize) != 0) {
        return StepResult::Error;
    }
    return step_result(storage.checkpoint(UpdateCheckpoint::PageVerified));
}

StepResult copy_image(FirmwareStorage& storage, uint32_t source_offset,
                      uint32_t destination_offset, BoardRevision board)
{
    if (!image_valid(storage, source_offset, board)) {
        return StepResult::Error;
    }
    const auto* source_manifest = manifest_at(storage, source_offset);
    if (!source_manifest) {
        return StepResult::Error;
    }
    const uint32_t package_size =
        kManifestSectorSize + source_manifest->payload_size;
    const uint32_t erase_size =
        (package_size + kFlashSectorSize - 1) & ~(kFlashSectorSize - 1);

    for (uint32_t position = 0; position < erase_size;
         position += kFlashSectorSize) {
        StepResult result =
            step_result(storage.erase_sector(destination_offset + position));
        if (result != StepResult::Ok) {
            return result;
        }
        result = verify_erased(storage, destination_offset + position);
        if (result != StepResult::Ok) {
            return result;
        }
    }

    alignas(kFlashPageSize) uint8_t page[kFlashPageSize];
    for (uint32_t position = kManifestSectorSize; position < package_size;
         position += kFlashPageSize) {
        std::memset(page, 0xff, sizeof(page));
        const size_t amount =
            std::min<size_t>(sizeof(page), package_size - position);
        const uint8_t* source =
            storage.read(source_offset + position, amount);
        if (!source) {
            return StepResult::Error;
        }
        std::memcpy(page, source, amount);
        StepResult result = step_result(
            storage.program_page(destination_offset + position, page));
        if (result != StepResult::Ok) {
            return result;
        }
        result = verify_page(storage, destination_offset + position, page);
        if (result != StepResult::Ok) {
            return result;
        }
    }

    const uint8_t* destination_payload = storage.read(
        destination_offset + kManifestSectorSize,
        source_manifest->payload_size);
    if (!destination_payload) {
        return StepResult::Error;
    }
    uint8_t digest[32];
    sha256(destination_payload, source_manifest->payload_size, digest);
    if (std::memcmp(digest, source_manifest->payload_sha256,
                    sizeof(digest)) != 0) {
        return StepResult::Error;
    }
    StepResult result =
        step_result(storage.checkpoint(UpdateCheckpoint::PayloadVerified));
    if (result != StepResult::Ok) {
        return result;
    }

    const uint8_t* manifest_page =
        storage.read(source_offset, kFlashPageSize);
    if (!manifest_page) {
        return StepResult::Error;
    }
    std::memcpy(page, manifest_page, sizeof(page));
    result = step_result(storage.program_page(destination_offset, page));
    if (result != StepResult::Ok) {
        return result;
    }
    result = verify_page(storage, destination_offset, page);
    if (result != StepResult::Ok) {
        return result;
    }
    if (!image_valid(storage, destination_offset, board)) {
        return StepResult::Error;
    }
    return step_result(storage.checkpoint(UpdateCheckpoint::ImageVerified));
}

StepResult commit_journal(FirmwareStorage& storage, BoardRevision board,
                          const UpdateJournalStatus& current,
                          UpdateState state,
                          const FirmwareImageManifest* candidate,
                          UpdateResult update_result,
                          UpdateJournalStatus* committed = nullptr)
{
    UpdateJournalRecord record{};
    record.magic = kJournalMagic;
    record.format_version = kJournalFormatVersion;
    record.record_size = sizeof(record);
    record.sequence = current.valid ? current.record.sequence + 1 : 1;
    record.state = static_cast<uint8_t>(state);
    record.board_revision = static_cast<uint8_t>(board);
    record.result = static_cast<uint8_t>(update_result);
    if (candidate) {
        set_candidate(record, *candidate);
    }
    record.crc32 = journal_crc(record);

    const uint32_t target =
        current.valid && current.flash_offset == kUpdateJournalOffsetA
            ? kUpdateJournalOffsetB
            : kUpdateJournalOffsetA;
    StepResult result = step_result(storage.erase_sector(target));
    if (result != StepResult::Ok) {
        return result;
    }
    result = verify_erased(storage, target);
    if (result != StepResult::Ok) {
        return result;
    }

    alignas(kFlashPageSize) uint8_t page[kFlashPageSize];
    std::memcpy(page, &record, sizeof(record));
    result = step_result(storage.program_page(target, page));
    if (result != StepResult::Ok) {
        return result;
    }
    result = verify_page(storage, target, page);
    if (result != StepResult::Ok) {
        return result;
    }
    const uint8_t* sector = storage.read(target, kFlashSectorSize);
    if (!sector || !update_journal_record_valid(sector, board)) {
        return StepResult::Error;
    }
    result = step_result(storage.checkpoint(UpdateCheckpoint::JournalVerified));
    if (result != StepResult::Ok) {
        return result;
    }
    if (committed) {
        committed->valid = true;
        committed->flash_offset = target;
        committed->record = record;
    }
    return StepResult::Ok;
}

BootDecision restore_and_confirm(FirmwareStorage& storage,
                                 BoardRevision board,
                                 const UpdateJournalStatus& journal,
                                 uint32_t source_offset,
                                 UpdateResult update_result)
{
    StepResult result =
        copy_image(storage, source_offset, kActiveOffset, board);
    if (result != StepResult::Ok) {
        return boot_result(result);
    }
    const auto* active = manifest_at(storage, kActiveOffset);
    result = commit_journal(storage, board, journal, UpdateState::Confirmed,
                            active, update_result);
    return result == StepResult::Ok ? BootDecision::StartActive
                                    : boot_result(result);
}

BootDecision recover_without_update(FirmwareStorage& storage,
                                    BoardRevision board,
                                    const UpdateJournalStatus& journal)
{
    if (image_valid(storage, kActiveOffset, board)) {
        return BootDecision::StartActive;
    }
    if (image_valid(storage, kRollbackOffset, board)) {
        return restore_and_confirm(storage, board, journal, kRollbackOffset,
                                   UpdateResult::Recovered);
    }
    if (image_valid(storage, kStagingOffset, board)) {
        return restore_and_confirm(storage, board, journal, kStagingOffset,
                                   UpdateResult::Recovered);
    }
    return BootDecision::EnterUsbRecovery;
}

}  // namespace

bool update_journal_record_valid(const uint8_t* sector,
                                 BoardRevision expected_board)
{
    if (!sector) {
        return false;
    }
    const auto* record =
        reinterpret_cast<const UpdateJournalRecord*>(sector);
    if (record->magic != kJournalMagic ||
        record->format_version != kJournalFormatVersion ||
        record->record_size != sizeof(UpdateJournalRecord) ||
        record->board_revision != static_cast<uint8_t>(expected_board) ||
        !state_valid(record->state) || !result_valid(record->result) ||
        record->reserved0 != 0 ||
        record->crc32 != journal_crc(*record) ||
        std::memchr(record->candidate_build_id, '\0',
                    sizeof(record->candidate_build_id)) == nullptr) {
        return false;
    }
    for (uint8_t value : record->reserved) {
        if (value != 0) {
            return false;
        }
    }
    for (size_t i = sizeof(UpdateJournalRecord); i < kFlashSectorSize; ++i) {
        if (sector[i] != 0xff) {
            return false;
        }
    }
    return true;
}

UpdateJournalStatus read_update_journal(FirmwareStorage& storage,
                                        BoardRevision board)
{
    UpdateJournalStatus result{};
    const uint8_t* sector_a =
        storage.read(kUpdateJournalOffsetA, kFlashSectorSize);
    const uint8_t* sector_b =
        storage.read(kUpdateJournalOffsetB, kFlashSectorSize);
    const bool valid_a = update_journal_record_valid(sector_a, board);
    const bool valid_b = update_journal_record_valid(sector_b, board);
    if (!valid_a && !valid_b) {
        return result;
    }
    const bool choose_a =
        valid_a && (!valid_b || sequence_newer(
                                  reinterpret_cast<const UpdateJournalRecord*>(
                                      sector_a)->sequence,
                                  reinterpret_cast<const UpdateJournalRecord*>(
                                      sector_b)->sequence));
    result.valid = true;
    result.flash_offset =
        choose_a ? kUpdateJournalOffsetA : kUpdateJournalOffsetB;
    result.record = *reinterpret_cast<const UpdateJournalRecord*>(
        choose_a ? sector_a : sector_b);
    return result;
}

bool running_firmware_is_trial(FirmwareStorage& storage,
                               BoardRevision board)
{
    const UpdateJournalStatus journal = read_update_journal(storage, board);
    if (!journal.valid ||
        journal.record.state != static_cast<uint8_t>(UpdateState::Trial) ||
        !image_valid(storage, kActiveOffset, board)) {
        return false;
    }
    const auto* active = manifest_at(storage, kActiveOffset);
    return active && candidate_matches(journal.record, *active);
}

StorageResult mark_update_pending(FirmwareStorage& storage,
                                  BoardRevision board)
{
    if (!image_valid(storage, kActiveOffset, board) ||
        !image_valid(storage, kStagingOffset, board)) {
        return StorageResult::Error;
    }
    const auto* staging = manifest_at(storage, kStagingOffset);
    UpdateJournalStatus journal = read_update_journal(storage, board);
    if (journal.valid &&
        journal.record.state == static_cast<uint8_t>(UpdateState::Pending) &&
        candidate_matches(journal.record, *staging)) {
        return StorageResult::Ok;
    }
    if (journal.valid &&
        journal.record.state != static_cast<uint8_t>(UpdateState::Confirmed)) {
        return StorageResult::Error;
    }
    return storage_result(commit_journal(
        storage, board, journal, UpdateState::Pending, staging,
        UpdateResult::None));
}

StorageResult confirm_running_firmware(FirmwareStorage& storage,
                                       BoardRevision board)
{
    UpdateJournalStatus journal = read_update_journal(storage, board);
    if (!journal.valid || !image_valid(storage, kActiveOffset, board)) {
        return StorageResult::Error;
    }
    const auto* active = manifest_at(storage, kActiveOffset);
    if (!candidate_matches(journal.record, *active)) {
        return StorageResult::Error;
    }
    if (journal.record.state == static_cast<uint8_t>(UpdateState::Confirmed)) {
        return StorageResult::Ok;
    }
    if (journal.record.state != static_cast<uint8_t>(UpdateState::Trial)) {
        return StorageResult::Error;
    }
    return storage_result(commit_journal(
        storage, board, journal, UpdateState::Confirmed, active,
        UpdateResult::Installed));
}

BootDecision process_firmware_boot(FirmwareStorage& storage,
                                   BoardRevision board)
{
    UpdateJournalStatus journal = read_update_journal(storage, board);
    if (!journal.valid) {
        return recover_without_update(storage, board, journal);
    }

    const UpdateState state =
        static_cast<UpdateState>(journal.record.state);
    if (state == UpdateState::Confirmed) {
        return recover_without_update(storage, board, journal);
    }

    if (state == UpdateState::Trial) {
        if (!image_valid(storage, kRollbackOffset, board)) {
            return BootDecision::EnterUsbRecovery;
        }
        return restore_and_confirm(storage, board, journal, kRollbackOffset,
                                   UpdateResult::RolledBack);
    }

    const bool staging_valid = image_valid(storage, kStagingOffset, board);
    const auto* staging = staging_valid
                              ? manifest_at(storage, kStagingOffset)
                              : nullptr;
    if (!staging || !candidate_matches(journal.record, *staging)) {
        if (state == UpdateState::Pending &&
            image_valid(storage, kActiveOffset, board)) {
            const auto* active = manifest_at(storage, kActiveOffset);
            StepResult result = commit_journal(storage, board, journal,
                                               UpdateState::Confirmed, active,
                                               UpdateResult::Rejected);
            return result == StepResult::Ok ? BootDecision::StartActive
                                            : boot_result(result);
        }
        if (image_valid(storage, kRollbackOffset, board)) {
            return restore_and_confirm(storage, board, journal,
                                       kRollbackOffset,
                                       UpdateResult::RolledBack);
        }
        return BootDecision::EnterUsbRecovery;
    }

    if (state == UpdateState::Pending) {
        if (!image_valid(storage, kActiveOffset, board)) {
            return recover_without_update(storage, board, journal);
        }
        StepResult result =
            copy_image(storage, kActiveOffset, kRollbackOffset, board);
        if (result != StepResult::Ok) {
            return boot_result(result);
        }
        result = commit_journal(storage, board, journal,
                                UpdateState::BackupReady, staging,
                                UpdateResult::None, &journal);
        if (result != StepResult::Ok) {
            return boot_result(result);
        }
    }

    if (!image_valid(storage, kRollbackOffset, board)) {
        return BootDecision::EnterUsbRecovery;
    }
    StepResult result =
        copy_image(storage, kStagingOffset, kActiveOffset, board);
    if (result != StepResult::Ok) {
        return boot_result(result);
    }
    const auto* active = manifest_at(storage, kActiveOffset);
    result = commit_journal(storage, board, journal, UpdateState::Trial,
                            active, UpdateResult::None);
    return result == StepResult::Ok ? BootDecision::StartActive
                                    : boot_result(result);
}

}  // namespace firmware_update
