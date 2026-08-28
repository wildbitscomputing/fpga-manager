#include "golden_images.h"

#include <iterator>

extern "C" {
extern const uint8_t golden_fpga_context1_start[];
extern const uint8_t golden_fpga_context1_end[];
extern const uint8_t golden_fpga_context3_start[];
extern const uint8_t golden_fpga_context3_end[];
extern const uint8_t golden_fpga_context4_start[];
extern const uint8_t golden_fpga_context4_end[];
extern const char golden_fpga_context1_label[];
extern const char golden_fpga_context3_label[];
extern const char golden_fpga_context4_label[];
}

namespace {

const GoldenImageInfo golden_images[] = {
    { golden_fpga_context1_start, golden_fpga_context1_end,
      golden_fpga_context1_label, 1 },
    { golden_fpga_context1_start, golden_fpga_context1_end,
      golden_fpga_context1_label, 1 },
    { golden_fpga_context3_start, golden_fpga_context3_end,
      golden_fpga_context3_label, 3 },
    { golden_fpga_context4_start, golden_fpga_context4_end,
      golden_fpga_context4_label, 4 },
};

}  // namespace

const GoldenImageInfo* golden_image_for_context(uint8_t context)
{
    return context < std::size(golden_images) ? &golden_images[context] : nullptr;
}
