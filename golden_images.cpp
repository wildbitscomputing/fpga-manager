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
    return context == kGoldenRecoveryContext ? &golden_context1 : nullptr;
}
