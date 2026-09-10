#include "rp2040_firmware_storage.h"

#include "firmware_update_layout.h"
#include "hardware/flash.h"
#include "hardware/sync.h"

const uint8_t* Rp2040FirmwareStorage::read(uint32_t offset, size_t length)
{
    if (offset > firmware_update::kFlashSize ||
        length > firmware_update::kFlashSize - offset) {
        return nullptr;
    }
    return reinterpret_cast<const uint8_t*>(firmware_update::kXipBase + offset);
}

firmware_update::StorageResult Rp2040FirmwareStorage::erase_sector(
    uint32_t offset)
{
    if ((offset & (firmware_update::kFlashSectorSize - 1)) != 0 ||
        offset > firmware_update::kFlashSize -
                     firmware_update::kFlashSectorSize) {
        return firmware_update::StorageResult::Error;
    }
    const uint32_t interrupts = save_and_disable_interrupts();
    flash_range_erase(offset, firmware_update::kFlashSectorSize);
    restore_interrupts(interrupts);
    return firmware_update::StorageResult::Ok;
}

firmware_update::StorageResult Rp2040FirmwareStorage::program_page(
    uint32_t offset,
    const uint8_t data[firmware_update::kFlashPageSize])
{
    if ((offset & (firmware_update::kFlashPageSize - 1)) != 0 ||
        offset > firmware_update::kFlashSize - firmware_update::kFlashPageSize) {
        return firmware_update::StorageResult::Error;
    }
    const uint32_t interrupts = save_and_disable_interrupts();
    flash_range_program(offset, data, firmware_update::kFlashPageSize);
    restore_interrupts(interrupts);
    return firmware_update::StorageResult::Ok;
}

firmware_update::StorageResult Rp2040FirmwareStorage::checkpoint(
    firmware_update::UpdateCheckpoint)
{
    return firmware_update::StorageResult::Ok;
}
