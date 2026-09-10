#pragma once

#include <cstddef>
#include <cstdint>

struct GoldenImageInfo {
    const uint8_t* start;
    const uint8_t* end;
    const char* label;
};

// Returns the one immutable recovery payload for contexts 1 and 4. Context 4
// aliases the context-1 image; contexts 2 and 3 return nullptr.
const GoldenImageInfo* golden_image_for_context(uint8_t context);

inline size_t golden_image_size(const GoldenImageInfo& image)
{
    return static_cast<size_t>(image.end - image.start);
}
