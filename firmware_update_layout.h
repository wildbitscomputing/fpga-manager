#pragma once

#include <cstddef>
#include <cstdint>

namespace firmware_update {

constexpr uintptr_t kXipBase = 0x10000000u;
constexpr uint32_t kFlashSize = 0x01000000u;

constexpr uint32_t kLoaderOffset = 0x000000u;
constexpr uint32_t kLoaderSize = 0x010000u;

constexpr uint32_t kActiveOffset = 0x010000u;
constexpr uint32_t kRollbackOffset = 0x280000u;
constexpr uint32_t kStagingOffset = 0x4f0000u;
constexpr uint32_t kApplicationSlotSize = 0x270000u;
constexpr uint32_t kManifestSectorSize = 0x001000u;
constexpr uint32_t kApplicationPayloadSize =
    kApplicationSlotSize - kManifestSectorSize;
constexpr uint32_t kApplicationPayloadOffset =
    kActiveOffset + kManifestSectorSize;

constexpr uint32_t kReservedOffset = 0x760000u;
// Keep the update journal in a dedicated 64 KiB physical erase block. The
// RP2040 ROM supports 4 KiB erases during normal updates, while OpenOCD's SWD
// flash driver erases the W25Q128 in 64 KiB units for factory programming.
constexpr uint32_t kUpdateJournalOffsetA = 0x7e0000u;
constexpr uint32_t kUpdateJournalOffsetB = 0x7e1000u;
constexpr uint32_t kBootMetadataOffsetA = 0x7fe000u;
constexpr uint32_t kBootMetadataOffsetB = 0x7ff000u;
constexpr uint32_t kFpgaSlotsOffset = 0x800000u;

constexpr uint16_t kLoaderAbiVersion = 1;
constexpr uint32_t kSdkVectorOffset = 0x100u;

static_assert(kLoaderOffset + kLoaderSize == kActiveOffset);
static_assert(kActiveOffset + kApplicationSlotSize == kRollbackOffset);
static_assert(kRollbackOffset + kApplicationSlotSize == kStagingOffset);
static_assert(kStagingOffset + kApplicationSlotSize == kReservedOffset);
static_assert(kUpdateJournalOffsetA + 0x1000u == kUpdateJournalOffsetB);
static_assert(kReservedOffset <= kUpdateJournalOffsetA);
static_assert(kUpdateJournalOffsetB + 0x1000u <= kBootMetadataOffsetA);
static_assert(kBootMetadataOffsetA + 0x1000u == kBootMetadataOffsetB);
static_assert(kBootMetadataOffsetB + 0x1000u == kFpgaSlotsOffset);
static_assert(kFpgaSlotsOffset < kFlashSize);

}  // namespace firmware_update
