#include "golden_images.h"

#include "boot_config.h"

extern "C" {
extern const uint8_t golden_fpga_context1_start[];
extern const uint8_t golden_fpga_context1_end[];
extern const char golden_fpga_context1_label[];
}

namespace {

const GoldenImageInfo golden_context1 = {
    golden_fpga_context1_start,
    golden_fpga_context1_end,
    golden_fpga_context1_label,
};

}  // namespace

const GoldenImageInfo* golden_image_for_context(uint8_t context)
{
    // Context 4 retains its historical recovery behavior, but aliases the
    // context-1 payload so the bitstream is linked only once.
    return context_has_golden_recovery(context) ? &golden_context1 : nullptr;
}
