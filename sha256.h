#pragma once

#include <cstddef>
#include <cstdint>

namespace firmware_update {

struct Sha256Context {
    uint32_t state[8];
    uint64_t byte_count;
    uint8_t block[64];
    size_t block_used;
};

void sha256_init(Sha256Context* context);
void sha256_update(Sha256Context* context, const uint8_t* data, size_t length);
void sha256_final(Sha256Context* context, uint8_t digest[32]);
void sha256(const uint8_t* data, size_t length, uint8_t digest[32]);

}  // namespace firmware_update
