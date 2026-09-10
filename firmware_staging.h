#pragma once

#include <cstddef>
#include <cstdint>

#include "firmware_update_engine.h"
#include "sha256.h"

namespace firmware_update {

enum class FirmwareReceiveState : uint8_t {
    Idle = 0,
    Manifest = 1,
    Erasing = 2,
    Payload = 3,
    Ready = 4,
    Failed = 5,
};

enum class FirmwareReceiveError : uint8_t {
    None = 0,
    BadState = 1,
    BadSize = 2,
    BadOffset = 3,
    Busy = 4,
    BadManifest = 5,
    Storage = 6,
    Verify = 7,
    BadHash = 8,
    Journal = 9,
    Downgrade = 10,
};

struct FirmwareReceiveStatus {
    FirmwareReceiveState state;
    FirmwareReceiveError error;
    ImageValidation validation;
    uint32_t next_offset;
    uint32_t progress;
    uint32_t progress_total;
    uint32_t package_size;
    uint32_t payload_size;
};

// Receives a complete .k2fw package into the fixed staging slot. The manifest
// sector is buffered and is not programmed until the payload has been written
// and verified, so a reset during transfer cannot create a valid candidate.
class FirmwareStagingReceiver {
  public:
    void initialize(FirmwareStorage* storage, BoardRevision board);
    bool begin(uint32_t package_size);
    bool write(uint32_t offset, const uint8_t* data, size_t length);
    void service_step();
    bool finish();
    bool abort();

    FirmwareReceiveStatus status() const;
    bool ready_to_apply() const;

  private:
    bool fail(FirmwareReceiveError error);
    bool program_payload_page();
    bool verify_erased_sector(uint32_t offset);

    FirmwareStorage* storage_ = nullptr;
    BoardRevision board_ = BoardRevision::B0C;
    FirmwareReceiveState state_ = FirmwareReceiveState::Idle;
    FirmwareReceiveError error_ = FirmwareReceiveError::None;
    ImageValidation validation_ = ImageValidation::Ok;
    uint32_t package_size_ = 0;
    uint32_t payload_size_ = 0;
    uint32_t next_offset_ = 0;
    uint32_t erase_size_ = 0;
    uint32_t erase_offset_ = 0;
    uint32_t page_offset_ = 0;
    size_t page_used_ = 0;
    bool manifest_committed_ = false;
    alignas(kFlashPageSize) uint8_t manifest_sector_[kManifestSectorSize];
    alignas(kFlashPageSize) uint8_t page_[kFlashPageSize];
    Sha256Context sha_{};
};

}  // namespace firmware_update
