#include "firmware_trial.h"

#include "firmware_update_engine.h"
#include "hardware/watchdog.h"
#include "pico/runtime.h"
#include "rp2040_firmware_storage.h"

#ifndef K2_BOARD_ID
#error "K2_BOARD_ID must identify the board-specific firmware image"
#endif

namespace {

constexpr uint32_t kTrialWatchdogMs = 8000;
bool trial_active = false;

constexpr firmware_update::BoardRevision board_revision()
{
    static_assert(
        K2_BOARD_ID ==
                static_cast<int>(firmware_update::BoardRevision::B0C) ||
            K2_BOARD_ID ==
                static_cast<int>(firmware_update::BoardRevision::B3B));
    return static_cast<firmware_update::BoardRevision>(K2_BOARD_ID);
}

extern "C" void firmware_trial_watchdog_early_init()
{
    Rp2040FirmwareStorage storage;
    trial_active =
        firmware_update::running_firmware_is_trial(storage, board_revision());
    if (trial_active) {
        watchdog_enable(kTrialWatchdogMs, false);
    }
}

// Run after clocks and the RP2040 watchdog tick have been initialized, but
// before the remaining SDK and application startup work.
PICO_RUNTIME_INIT_FUNC_RUNTIME(firmware_trial_watchdog_early_init, "00510");

}  // namespace

bool firmware_trial_active()
{
    return trial_active;
}

void firmware_trial_watchdog_feed()
{
    if (trial_active) {
        watchdog_update();
    }
}

bool firmware_trial_confirm()
{
    if (!trial_active) {
        return true;
    }
    watchdog_update();
    Rp2040FirmwareStorage storage;
    if (firmware_update::confirm_running_firmware(storage, board_revision()) !=
        firmware_update::StorageResult::Ok) {
        return false;
    }
    watchdog_disable();
    trial_active = false;
    return true;
}
