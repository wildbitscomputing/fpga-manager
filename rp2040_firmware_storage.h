#pragma once

#include "firmware_update_engine.h"

class Rp2040FirmwareStorage : public firmware_update::FirmwareStorage {
  public:
    const uint8_t* read(uint32_t offset, size_t length) override;
    firmware_update::StorageResult erase_sector(uint32_t offset) override;
    firmware_update::StorageResult program_page(
        uint32_t offset,
        const uint8_t data[firmware_update::kFlashPageSize]) override;
    firmware_update::StorageResult checkpoint(
        firmware_update::UpdateCheckpoint checkpoint) override;
};
