#pragma once

#include <cstddef>
#include <cstdint>

constexpr size_t kBootContextCount = 4;
constexpr uint8_t kGoldenRecoveryContext = 3;
constexpr size_t kBootPathLength = 192;
constexpr size_t kFlashLabelLength = 128;

enum class BootSource : uint8_t {
    Auto = 0,
    Sd = 1,
    Flash = 2,
    Golden = 3,
};

struct BootSelection {
    BootSource source;
    char path[kBootPathLength];
};

struct FlashSlotInfo {
    bool valid;
    uint32_t compressed_size;
    uint32_t compressed_crc;
    char label[kFlashLabelLength];
};

struct BootRuntimeStatus {
    bool valid;
    uint8_t context;
    BootSource source;
    char path[kBootPathLength];
};

// Loads the newest valid metadata journal record. Invalid or erased metadata
// safely produces AUTO selections and empty flash labels.
void boot_config_init();

const BootSelection& boot_config_selection(uint8_t context);
bool boot_config_set_selection(uint8_t context, BootSource source,
                               const char* path);

FlashSlotInfo boot_config_flash_slot(uint8_t slot);
bool boot_config_set_flash_slot(uint8_t slot, uint32_t compressed_size,
                                uint32_t compressed_crc, const char* label);
bool boot_config_clear_flash_slot(uint8_t slot);

void boot_runtime_set(uint8_t context, BootSource source, const char* path);
const BootRuntimeStatus& boot_runtime_status();
