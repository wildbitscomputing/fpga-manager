#pragma once

#include <cstddef>
#include <cstdint>

struct GoldenImageInfo {
    const uint8_t* start;
    const uint8_t* end;
    const char* label;
    uint8_t source_context;
};

// Returns immutable build-time metadata for a zero-based boot context.
// Context 2 currently aliases the context 1 recovery image.
const GoldenImageInfo* golden_image_for_context(uint8_t context);

inline size_t golden_image_size(const GoldenImageInfo& image)
{
    return static_cast<size_t>(image.end - image.start);
}
