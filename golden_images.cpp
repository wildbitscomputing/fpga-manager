#include "golden_images.h"

#include "boot_config.h"

extern "C" {
extern const uint8_t golden_fpga_context4_start[];
extern const uint8_t golden_fpga_context4_end[];
extern const char golden_fpga_context4_label[];
}

namespace {

const GoldenImageInfo golden_context4 = {
    golden_fpga_context4_start,
    golden_fpga_context4_end,
    golden_fpga_context4_label,
};

}  // namespace

const GoldenImageInfo* golden_image_for_context(uint8_t context)
{
    return context == kGoldenRecoveryContext ? &golden_context4 : nullptr;
}
