#pragma once

#include <cstddef>
#include <cstdint>

struct GoldenImageInfo {
    const uint8_t* start;
    const uint8_t* end;
    const char* label;
};

// Returns the immutable context-1 recovery image. Other contexts deliberately
// have no embedded fallback and return nullptr.
const GoldenImageInfo* golden_image_for_context(uint8_t context);

inline size_t golden_image_size(const GoldenImageInfo& image)
{
    return static_cast<size_t>(image.end - image.start);
}
