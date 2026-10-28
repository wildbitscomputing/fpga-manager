#pragma once
#include <cstddef>
#include <cstdint>
struct GzipInspection
{
    uint32_t size;
    uint32_t crc;
};
// Validates the complete gzip, exact FPGA length, CRC, and erased tail.
bool inspect_legacy_gzip(const uint8_t *data, size_t capacity, GzipInspection *result);
