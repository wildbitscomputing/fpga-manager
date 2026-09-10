#include <cstdint>

#include "firmware_image.h"
#include "firmware_update_engine.h"
#include "firmware_update_layout.h"
#include "hardware/structs/m0plus.h"
#include "hardware/structs/scb.h"
#include "hardware/sync.h"
#include "hardware/watchdog.h"
#include "pico/bootrom.h"
#include "pico/stdlib.h"
#include "rp2040_firmware_storage.h"

#ifndef K2_BOARD_ID
#error "K2_BOARD_ID must identify the board-specific firmware image"
#endif

namespace {

using firmware_update::BoardRevision;
using firmware_update::BootDecision;
using firmware_update::FirmwareImageManifest;

[[noreturn]] void enter_usb_recovery()
{
    reset_usb_boot(0, 0);
    while (true) {
        tight_loop_contents();
    }
}

[[noreturn]] void start_active_application(const uint8_t* slot)
{
    const auto* manifest =
        reinterpret_cast<const FirmwareImageManifest*>(slot);
    const uint8_t* payload =
        slot + firmware_update::kManifestSectorSize;
    const uint32_t* vectors = reinterpret_cast<const uint32_t*>(
        payload + manifest->vector_offset);

    // Do not use watchdog_reboot(pc, sp, 0) here. On RP2040 that ROM shortcut
    // jumps to pc before performing a normal flash boot, so the watchdog reset
    // has disabled XIP by the time a relocated flash address is entered.
    //
    // The loader has no active IRQ-driven services. Keep XIP configured,
    // install the application's vector table, and enter its normal reset
    // handler. That handler initializes .data/.bss and runs the Pico SDK
    // runtime initialization just as it does after a conventional boot.
    watchdog_disable();
    save_and_disable_interrupts();
    ppb_hw->syst_csr = 0;
    ppb_hw->nvic_icer = UINT32_MAX;
    ppb_hw->nvic_icpr = UINT32_MAX;
    // Clear pending PendSV and SysTick exceptions.
    scb_hw->icsr = (1u << 27) | (1u << 25);
    scb_hw->vtor = reinterpret_cast<uintptr_t>(vectors);
    const uint32_t stack_pointer = vectors[0];
    const uint32_t reset_handler = vectors[1];
    __asm volatile(
        "dsb\n"
        "isb\n"
        "msr msp, %0\n"
        "cpsie i\n"
        "bx %1\n"
        :
        : "r"(stack_pointer), "r"(reset_handler)
        : "memory");
    __builtin_unreachable();
    while (true) {
        tight_loop_contents();
    }
}

}  // namespace

int main()
{
    static_assert(K2_BOARD_ID == static_cast<int>(BoardRevision::B0C) ||
                  K2_BOARD_ID == static_cast<int>(BoardRevision::B3B));
    constexpr BoardRevision board = static_cast<BoardRevision>(K2_BOARD_ID);
    const auto* active = reinterpret_cast<const uint8_t*>(
        firmware_update::kXipBase + firmware_update::kActiveOffset);
    Rp2040FirmwareStorage storage;
    switch (firmware_update::process_firmware_boot(storage, board)) {
        case BootDecision::StartActive:
            start_active_application(active);
        case BootDecision::EnterUsbRecovery:
        case BootDecision::Interrupted:
        case BootDecision::FlashError:
            enter_usb_recovery();
    }
}
