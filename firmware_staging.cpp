#include "firmware_staging.h"

#include <algorithm>
#include <cstring>

#include "firmware_update_layout.h"

namespace firmware_update {

void FirmwareStagingReceiver::initialize(FirmwareStorage* storage,
                                         BoardRevision board)
{
    storage_ = storage;
    board_ = board;
    state_ = FirmwareReceiveState::Idle;
    error_ = FirmwareReceiveError::None;
    validation_ = ImageValidation::Ok;
    package_size_ = 0;
    payload_size_ = 0;
    next_offset_ = 0;
    erase_size_ = 0;
    erase_offset_ = 0;
    page_offset_ = 0;
    page_used_ = 0;
    manifest_committed_ = false;
}

bool FirmwareStagingReceiver::fail(FirmwareReceiveError error)
{
    error_ = error;
    state_ = FirmwareReceiveState::Failed;
    return false;
}

bool FirmwareStagingReceiver::begin(uint32_t package_size)
{
    if (!storage_ || state_ == FirmwareReceiveState::Ready ||
        manifest_committed_) {
        error_ = FirmwareReceiveError::BadState;
        return false;
    }
    const UpdateJournalStatus journal = read_update_journal(*storage_, board_);
    if (journal.valid &&
        journal.record.state != static_cast<uint8_t>(UpdateState::Confirmed)) {
        error_ = FirmwareReceiveError::BadState;
        return false;
    }
    if (package_size <= kManifestSectorSize ||
        package_size > kApplicationSlotSize) {
        error_ = FirmwareReceiveError::BadSize;
        return false;
    }

    state_ = FirmwareReceiveState::Manifest;
    error_ = FirmwareReceiveError::None;
    validation_ = ImageValidation::Ok;
    package_size_ = package_size;
    payload_size_ = 0;
    next_offset_ = 0;
    erase_size_ = 0;
    erase_offset_ = 0;
    page_offset_ = 0;
    page_used_ = 0;
    manifest_committed_ = false;
    std::memset(manifest_sector_, 0xff, sizeof(manifest_sector_));
    std::memset(page_, 0xff, sizeof(page_));
    return true;
}

bool FirmwareStagingReceiver::write(uint32_t offset, const uint8_t* data,
                                    size_t length)
{
    if (!data || length == 0) {
        error_ = FirmwareReceiveError::BadSize;
        return false;
    }
    if (state_ == FirmwareReceiveState::Erasing) {
        error_ = FirmwareReceiveError::Busy;
        return false;
    }
    if (state_ != FirmwareReceiveState::Manifest &&
        state_ != FirmwareReceiveState::Payload) {
        error_ = FirmwareReceiveError::BadState;
        return false;
    }
    if (offset != next_offset_) {
        error_ = FirmwareReceiveError::BadOffset;
        return false;
    }
    if (length > package_size_ - next_offset_) {
        error_ = FirmwareReceiveError::BadSize;
        return false;
    }

    if (state_ == FirmwareReceiveState::Manifest) {
        if (length > kManifestSectorSize - next_offset_) {
            error_ = FirmwareReceiveError::BadSize;
            return false;
        }
        std::memcpy(manifest_sector_ + next_offset_, data, length);
        next_offset_ += static_cast<uint32_t>(length);
        error_ = FirmwareReceiveError::None;
        if (next_offset_ != kManifestSectorSize) {
            return true;
        }

        validation_ = validate_firmware_manifest(manifest_sector_, board_);
        if (validation_ != ImageValidation::Ok) {
            return fail(FirmwareReceiveError::BadManifest);
        }
        const auto* manifest = reinterpret_cast<const FirmwareImageManifest*>(
            manifest_sector_);
        const uint8_t* active_sector =
            storage_->read(kActiveOffset, kManifestSectorSize);
        if (active_sector &&
            validate_firmware_manifest(active_sector, board_) ==
                ImageValidation::Ok) {
            const auto* active =
                reinterpret_cast<const FirmwareImageManifest*>(active_sector);
            const bool older =
                manifest->version_major < active->version_major ||
                (manifest->version_major == active->version_major &&
                 manifest->version_minor < active->version_minor) ||
                (manifest->version_major == active->version_major &&
                 manifest->version_minor == active->version_minor &&
                 manifest->version_patch < active->version_patch);
            if (older) {
                return fail(FirmwareReceiveError::Downgrade);
            }
        }
        payload_size_ = manifest->payload_size;
        if (package_size_ != kManifestSectorSize + payload_size_) {
            return fail(FirmwareReceiveError::BadSize);
        }
        erase_size_ = (package_size_ + kFlashSectorSize - 1) &
                      ~(kFlashSectorSize - 1);
        erase_offset_ = 0;
        state_ = FirmwareReceiveState::Erasing;
        return true;
    }

    size_t consumed = 0;
    while (consumed < length) {
        const size_t amount = std::min<size_t>(
            static_cast<size_t>(kFlashPageSize) - page_used_,
            length - consumed);
        std::memcpy(page_ + page_used_, data + consumed, amount);
        sha256_update(&sha_, data + consumed, amount);
        page_used_ += amount;
        consumed += amount;
        next_offset_ += static_cast<uint32_t>(amount);
        if (page_used_ == kFlashPageSize && !program_payload_page()) {
            return false;
        }
    }
    error_ = FirmwareReceiveError::None;
    return true;
}

bool FirmwareStagingReceiver::verify_erased_sector(uint32_t offset)
{
    const uint8_t* bytes = storage_->read(offset, kFlashSectorSize);
    if (!bytes) {
        return fail(FirmwareReceiveError::Storage);
    }
    for (size_t i = 0; i < kFlashSectorSize; ++i) {
        if (bytes[i] != 0xff) {
            return fail(FirmwareReceiveError::Verify);
        }
    }
    if (storage_->checkpoint(UpdateCheckpoint::EraseVerified) !=
        StorageResult::Ok) {
        return fail(FirmwareReceiveError::Storage);
    }
    return true;
}

void FirmwareStagingReceiver::service_step()
{
    if (state_ != FirmwareReceiveState::Erasing) {
        return;
    }
    error_ = FirmwareReceiveError::None;
    if (erase_offset_ == erase_size_) {
        state_ = FirmwareReceiveState::Payload;
        page_offset_ = kManifestSectorSize;
        page_used_ = 0;
        std::memset(page_, 0xff, sizeof(page_));
        sha256_init(&sha_);
        return;
    }
    const uint32_t target = kStagingOffset + erase_offset_;
    if (storage_->erase_sector(target) != StorageResult::Ok) {
        fail(FirmwareReceiveError::Storage);
        return;
    }
    if (!verify_erased_sector(target)) {
        return;
    }
    erase_offset_ += kFlashSectorSize;
}

bool FirmwareStagingReceiver::program_payload_page()
{
    const uint32_t target = kStagingOffset + page_offset_;
    if (storage_->program_page(target, page_) != StorageResult::Ok) {
        return fail(FirmwareReceiveError::Storage);
    }
    const uint8_t* readback = storage_->read(target, kFlashPageSize);
    if (!readback || std::memcmp(readback, page_, kFlashPageSize) != 0) {
        return fail(FirmwareReceiveError::Verify);
    }
    if (storage_->checkpoint(UpdateCheckpoint::PageVerified) !=
        StorageResult::Ok) {
        return fail(FirmwareReceiveError::Storage);
    }
    page_offset_ += kFlashPageSize;
    page_used_ = 0;
    std::memset(page_, 0xff, sizeof(page_));
    return true;
}

bool FirmwareStagingReceiver::finish()
{
    if (state_ != FirmwareReceiveState::Payload ||
        next_offset_ != package_size_) {
        error_ = next_offset_ == package_size_
                     ? FirmwareReceiveError::BadState
                     : FirmwareReceiveError::BadSize;
        return false;
    }
    if (page_used_ != 0 && !program_payload_page()) {
        return false;
    }

    uint8_t digest[32];
    sha256_final(&sha_, digest);
    const auto* manifest = reinterpret_cast<const FirmwareImageManifest*>(
        manifest_sector_);
    if (std::memcmp(digest, manifest->payload_sha256, sizeof(digest)) != 0) {
        return fail(FirmwareReceiveError::BadHash);
    }
    if (storage_->checkpoint(UpdateCheckpoint::PayloadVerified) !=
        StorageResult::Ok) {
        return fail(FirmwareReceiveError::Storage);
    }

    if (storage_->program_page(kStagingOffset, manifest_sector_) !=
        StorageResult::Ok) {
        return fail(FirmwareReceiveError::Storage);
    }
    const uint8_t* manifest_readback =
        storage_->read(kStagingOffset, kFlashPageSize);
    if (!manifest_readback ||
        std::memcmp(manifest_readback, manifest_sector_, kFlashPageSize) != 0) {
        return fail(FirmwareReceiveError::Verify);
    }
    manifest_committed_ = true;
    const uint8_t* staging = storage_->read(kStagingOffset, package_size_);
    validation_ = staging ? validate_firmware_image(staging, board_)
                          : ImageValidation::BadMagic;
    if (validation_ != ImageValidation::Ok) {
        return fail(FirmwareReceiveError::Verify);
    }
    if (storage_->checkpoint(UpdateCheckpoint::ImageVerified) !=
        StorageResult::Ok) {
        return fail(FirmwareReceiveError::Storage);
    }
    if (mark_update_pending(*storage_, board_) != StorageResult::Ok) {
        return fail(FirmwareReceiveError::Journal);
    }
    state_ = FirmwareReceiveState::Ready;
    error_ = FirmwareReceiveError::None;
    return true;
}

bool FirmwareStagingReceiver::abort()
{
    if (state_ == FirmwareReceiveState::Ready || manifest_committed_) {
        error_ = FirmwareReceiveError::BadState;
        return false;
    }
    state_ = FirmwareReceiveState::Idle;
    error_ = FirmwareReceiveError::None;
    validation_ = ImageValidation::Ok;
    package_size_ = 0;
    payload_size_ = 0;
    next_offset_ = 0;
    erase_size_ = 0;
    erase_offset_ = 0;
    page_offset_ = 0;
    page_used_ = 0;
    return true;
}

FirmwareReceiveStatus FirmwareStagingReceiver::status() const
{
    uint32_t progress = next_offset_;
    uint32_t total = package_size_;
    if (state_ == FirmwareReceiveState::Manifest) {
        total = kManifestSectorSize;
    } else if (state_ == FirmwareReceiveState::Erasing) {
        progress = erase_offset_;
        total = erase_size_;
    }
    return {state_, error_, validation_, next_offset_, progress, total,
            package_size_, payload_size_};
}

bool FirmwareStagingReceiver::ready_to_apply() const
{
    return state_ == FirmwareReceiveState::Ready;
}

}  // namespace firmware_update
