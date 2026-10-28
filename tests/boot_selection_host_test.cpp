#include <array>
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>
#include "boot_config.h"

using fpga_method_t = int;
constexpr int FPGA_METHOD_NONE = 0, FLASH = 1, SD = 2, GOLDEN = 3;
struct fpga_image_info_t {};
std::array<fpga_image_info_t, 4> fpga_images;
bool manager_sd_attempted = false, manager_sd_mounted = false;
bool card_present = true, flash_ok = true, sd_ok = true, golden_ok = true;
unsigned mounts = 0, directories = 0;
std::string attempts;
BootSelection selection{BootSource::Flash, {0}};
using FRESULT = int;
constexpr FRESULT FR_OK = 0;
struct sd_card_t { int fatfs; const char* pcName; } card{0, "0:"};
sd_card_t* sd_get_by_num(int) { return &card; }
FRESULT f_mount(int*, const char*, int) { ++mounts; return card_present ? FR_OK : 1; }
void ensure_manager_sd_context_directories() { ++directories; }
uint64_t get_absolute_time() { return 0; }
long long absolute_time_diff_us(uint64_t, uint64_t) { return 0; }
void firmware_trial_watchdog_feed() {}
[[noreturn]] void panic(const char*) { std::abort(); }
void boot_logf(const char*, ...) {}
const BootSelection& boot_config_selection(uint8_t) { return selection; }
bool golden_image_for_context(uint8_t slot) { return slot == 0 || slot == 3; }
fpga_method_t program_fpga_from_flash_slot(const fpga_image_info_t*, uint8_t) {
    attempts += 'F'; return flash_ok ? FLASH : 0;
}
fpga_method_t program_fpga_from_sd_card(const fpga_image_info_t*, uint8_t) {
    attempts += 'S'; return sd_ok ? SD : 0;
}
fpga_method_t program_fpga_from_sd_path(const char*, uint8_t) {
    attempts += 'S'; return sd_ok ? SD : 0;
}
fpga_method_t program_fpga_from_golden_slot(unsigned char slot) {
    attempts += 'G'; return golden_image_for_context(slot) && golden_ok ? GOLDEN : 0;
}
#include "selection_functions.inc"
void reset(BootSource source) {
    manager_sd_attempted = manager_sd_mounted = false;
    card_present = flash_ok = sd_ok = golden_ok = true;
    mounts = directories = 0; attempts.clear(); selection.source = source;
}
int main() {
    reset(BootSource::Flash);
    assert(program_selected_context(0, false) == FLASH);
    assert(mounts == 0 && attempts == "F" && !manager_sd_is_mounted());
    // A later catalog/file operation mounts once, and status sees it immediately.
    assert(manager_sd_mount() && manager_sd_mount() && manager_sd_is_mounted());
    assert(mounts == 1 && directories == 1);
    reset(BootSource::Flash); flash_ok = false;
    assert(program_selected_context(0, false) == SD);
    assert(mounts == 1 && attempts == "FS");
    reset(BootSource::Flash); flash_ok = card_present = false;
    assert(program_selected_context(0, false) == GOLDEN);
    assert(mounts == 1 && directories == 0 && attempts == "FG");
    assert(!manager_sd_mount() && mounts == 1);
    reset(BootSource::Auto);
    assert(program_selected_context(0, false) == SD);
    assert(mounts == 1 && attempts == "S");
    reset(BootSource::Sd); sd_ok = false;
    assert(program_selected_context(0, false) == FLASH);
    assert(mounts == 1 && attempts == "SF");
    reset(BootSource::Flash);
    assert(program_selected_context(0, true) == GOLDEN);
    assert(mounts == 0 && attempts == "G");
    reset(BootSource::Golden);
    assert(program_selected_context(0, false) == GOLDEN && mounts == 0);
    reset(BootSource::Golden);
    assert(program_selected_context(1, false) == SD && mounts == 1);
    reset(BootSource::Flash);
    assert(program_transient_context(0, BootSource::Sd, "CNTX1/core.gz") == SD);
    assert(mounts == 1 && attempts == "S");
}
