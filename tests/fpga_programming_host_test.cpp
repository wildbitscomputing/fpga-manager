#include <cassert>
#include <cstdint>
#include <cstdio>
#include <initializer_list>

#include "fpga_completion_constants.inc"

constexpr unsigned PIO_FDEBUG_TXSTALL_LSB = 24;
constexpr unsigned GPIO_FUNC_SIO = 5;
constexpr bool GPIO_OUT = true;
constexpr bool GPIO_IN = false;
using absolute_time_t = uint64_t;
using uint = unsigned int;

struct DebugRegister {
    uint32_t bits = 0;
    uint32_t cleared = 0;
    operator uint32_t() const { return bits; }
    void operator=(uint32_t value) {
        cleared |= value;
        bits &= ~value; // RP2040 FDEBUG write-one-to-clear behavior
    }
};
struct FakePio { DebugRegister fdebug; } hardware;
FakePio* fpga_pio = &hardware;
int fpga_sm = 2;
bool fpga_pio_inited = true;
bool enabled = true;
bool sio_owns_clock = false;
bool sio_clock = true; // Old SIO latch must not create a handoff edge.
bool init_high = true;
bool reset_asserted = false;
bool stuck = false;
unsigned remaining = 0;
unsigned phase = 0;
unsigned divider = 1;
unsigned transmitted = 0;
unsigned startup_clocks = 0;
unsigned handoff_edges = 0;
unsigned disabled_before_transmit = 0;
unsigned logs = 0;
uint64_t now = 0;
uint64_t reset_release_at = 0;
unsigned sleeps = 0;
unsigned watchdog_feeds = 0;

uint32_t stall_mask() { return 1u << (PIO_FDEBUG_TXSTALL_LSB + fpga_sm); }

absolute_time_t make_timeout_time_ms(unsigned ms) { return now + ms * 1000; }
bool time_reached(absolute_time_t deadline) {
    ++now;
    if (enabled && !stuck && now % divider == 0) {
        // fpga_out: OUT side 0; NOP side 0; NOP side 1; wrap.
        // At phase 1/2 the final byte may be outside the FIFO but its clock
        // pulse has not completed. Only the next empty OUT sets TXSTALL.
        if (phase == 0 && remaining == 0) {
            hardware.fdebug.bits |= stall_mask();
        } else if (++phase == 3) {
            phase = 0;
            --remaining;
            ++transmitted;
        }
    }
    return now >= deadline;
}
void tight_loop_contents() {}
void sleep_ms(unsigned ms) {
    ++sleeps;
    now += ms * 1000;
}
void firmware_trial_watchdog_feed() { ++watchdog_feeds; }
void pio_sm_set_enabled(FakePio*, int, bool value) {
    if (!value && remaining != 0) ++disabled_before_transmit;
    enabled = value;
}
void fpga_pio_set_pio_mode() { sio_owns_clock = false; }
void gpio_put(unsigned pin, bool value) {
    if (pin == FPGA_CONFIG_CCLK) {
        if (sio_owns_clock && !sio_clock && value) ++startup_clocks;
        sio_clock = value;
    }
}
void gpio_set_function(unsigned pin, unsigned function) {
    assert(function == GPIO_FUNC_SIO);
    assert(!enabled); // Stop the SM before changing any of its pins.
    if (pin == FPGA_CONFIG_CCLK) {
        if (!sio_owns_clock && sio_clock) ++handoff_edges;
        sio_owns_clock = true;
    }
}
void gpio_set_dir(unsigned pin, bool out) {
    if (pin == FPGA_SYSTEM_RSTn) reset_asserted = out;
}
bool gpio_get(unsigned pin) {
    if (pin == FPGA_SYSTEM_RSTn) return now >= reset_release_at;
    assert(pin == FPGA_CONFIG_INITn);
    return init_high;
}
void boot_logf(const char*, ...) { ++logs; }

#include "fpga_completion_functions.inc"

void reset(unsigned bytes, unsigned initial_phase = 0) {
    hardware.fdebug.bits = stall_mask() | (1u << PIO_FDEBUG_TXSTALL_LSB);
    hardware.fdebug.cleared = 0;
    fpga_pio_inited = true;
    enabled = true;
    sio_owns_clock = false;
    sio_clock = true;
    init_high = true;
    reset_asserted = false;
    stuck = false;
    remaining = bytes;
    phase = initial_phase;
    divider = 1;
    transmitted = startup_clocks = handoff_edges = disabled_before_transmit = logs = 0;
    now = 0;
    reset_release_at = 0;
    sleeps = watchdog_feeds = 0;
}

int main() {
#if USE_PIO_FPGA
    // Tail may be in the joined FIFO, in the shifter, or already drained.
    for (unsigned bytes : {0u, 1u, 9u}) {
        for (unsigned speed : {1u, 4u, 100u}) {
            reset(bytes);
            divider = speed;
            assert(finish_fpga_programming());
            assert(remaining == 0 && transmitted == bytes);
            assert(disabled_before_transmit == 0 && !enabled);
            assert(startup_clocks == 100 && handoff_edges == 0);
            assert(!reset_asserted && now > 0);
            assert(hardware.fdebug.cleared == stall_mask());
            assert(hardware.fdebug.bits & (1u << PIO_FDEBUG_TXSTALL_LSB));
        }
    }
    for (unsigned initial_phase : {1u, 2u}) {
        reset(1, initial_phase);
        assert(finish_fpga_programming());
        assert(transmitted == 1 && disabled_before_transmit == 0);
        assert(startup_clocks == 100 && handoff_edges == 0);
    }
    // An old stall or another SM's stall cannot conceal a stopped transmitter.
    reset(9);
    stuck = true;
    assert(!finish_fpga_programming());
    assert(now == FPGA_PIO_DRAIN_TIMEOUT_MS * 1000);
    assert(!enabled && remaining == 9);
    assert(startup_clocks == 0 && logs == 1);

    reset(0);
    init_high = false;
    assert(!finish_fpga_programming());
    assert(startup_clocks == 100 && logs == 1);

    reset(0);
    fpga_pio_inited = false;
    assert(!finish_fpga_programming());
    assert(now == 0 && startup_clocks == 0);
#else
    // The GPIO-only build retains its existing completion sequence.
    reset(0);
    sio_owns_clock = true;
    assert(finish_fpga_programming());
    assert(startup_clocks == 100 && now == 0);
    init_high = false;
    assert(!finish_fpga_programming());
#endif
    reset(0);
    enabled = false;
    assert(!startup_requests_recovery());
    assert(now == 0 && sleeps == 0 && watchdog_feeds == 0);

    // An early release resumes boot promptly instead of waiting out 500 ms.
    for (uint64_t release : {1000u, 125000u, 499000u}) {
        reset(0);
        enabled = false;
        reset_release_at = release;
        assert(!startup_requests_recovery());
        assert(now >= release && now < release + 1000);
        assert(watchdog_feeds == sleeps && sleeps > 0);
    }

    reset(0);
    enabled = false;
    reset_release_at = 1000000;
    assert(startup_requests_recovery());
    assert(now >= STARTUP_RESET_HOLD_MS * 1000);
    assert(now < STARTUP_RESET_HOLD_MS * 1000 + 1000);
    assert(watchdog_feeds == sleeps && sleeps > 0);
    std::puts("FPGA completion/handoff checks passed");
}
