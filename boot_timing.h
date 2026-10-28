#pragma once

#include <cstdint>
#include "hardware/structs/watchdog.h"

// Scratch 0-2 are application-owned; the SDK reserves 4-7 for reboot state.
constexpr uint32_t kLoaderTimingMagic = 0x4b32544du;
inline void save_loader_timing(uint32_t elapsed_us, bool flash_fast_boot)
{
    watchdog_hw->scratch[1] = elapsed_us;
    watchdog_hw->scratch[2] = flash_fast_boot ? 1u : 0u;
    watchdog_hw->scratch[0] = kLoaderTimingMagic;
}
