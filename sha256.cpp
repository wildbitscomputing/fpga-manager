#include "sha256.h"

#include <cstring>

namespace firmware_update {
namespace {

constexpr uint32_t kRoundConstants[64] = {
    0x428a2f98u, 0x71374491u, 0xb5c0fbcfu, 0xe9b5dba5u,
    0x3956c25bu, 0x59f111f1u, 0x923f82a4u, 0xab1c5ed5u,
    0xd807aa98u, 0x12835b01u, 0x243185beu, 0x550c7dc3u,
    0x72be5d74u, 0x80deb1feu, 0x9bdc06a7u, 0xc19bf174u,
    0xe49b69c1u, 0xefbe4786u, 0x0fc19dc6u, 0x240ca1ccu,
    0x2de92c6fu, 0x4a7484aau, 0x5cb0a9dcu, 0x76f988dau,
    0x983e5152u, 0xa831c66du, 0xb00327c8u, 0xbf597fc7u,
    0xc6e00bf3u, 0xd5a79147u, 0x06ca6351u, 0x14292967u,
    0x27b70a85u, 0x2e1b2138u, 0x4d2c6dfcu, 0x53380d13u,
    0x650a7354u, 0x766a0abbu, 0x81c2c92eu, 0x92722c85u,
    0xa2bfe8a1u, 0xa81a664bu, 0xc24b8b70u, 0xc76c51a3u,
    0xd192e819u, 0xd6990624u, 0xf40e3585u, 0x106aa070u,
    0x19a4c116u, 0x1e376c08u, 0x2748774cu, 0x34b0bcb5u,
    0x391c0cb3u, 0x4ed8aa4au, 0x5b9cca4fu, 0x682e6ff3u,
    0x748f82eeu, 0x78a5636fu, 0x84c87814u, 0x8cc70208u,
    0x90befffau, 0xa4506cebu, 0xbef9a3f7u, 0xc67178f2u,
};

constexpr uint32_t rotate_right(uint32_t value, unsigned amount)
{
    return (value >> amount) | (value << (32u - amount));
}

uint32_t load_be32(const uint8_t* data)
{
    return (static_cast<uint32_t>(data[0]) << 24) |
           (static_cast<uint32_t>(data[1]) << 16) |
           (static_cast<uint32_t>(data[2]) << 8) |
           static_cast<uint32_t>(data[3]);
}

void store_be32(uint8_t* data, uint32_t value)
{
    data[0] = static_cast<uint8_t>(value >> 24);
    data[1] = static_cast<uint8_t>(value >> 16);
    data[2] = static_cast<uint8_t>(value >> 8);
    data[3] = static_cast<uint8_t>(value);
}

void transform(Sha256Context* context, const uint8_t block[64])
{
    uint32_t words[64];
    for (size_t i = 0; i < 16; ++i) {
        words[i] = load_be32(block + i * 4);
    }
    for (size_t i = 16; i < 64; ++i) {
        const uint32_t s0 = rotate_right(words[i - 15], 7) ^
                            rotate_right(words[i - 15], 18) ^
                            (words[i - 15] >> 3);
        const uint32_t s1 = rotate_right(words[i - 2], 17) ^
                            rotate_right(words[i - 2], 19) ^
                            (words[i - 2] >> 10);
        words[i] = words[i - 16] + s0 + words[i - 7] + s1;
    }

    uint32_t a = context->state[0];
    uint32_t b = context->state[1];
    uint32_t c = context->state[2];
    uint32_t d = context->state[3];
    uint32_t e = context->state[4];
    uint32_t f = context->state[5];
    uint32_t g = context->state[6];
    uint32_t h = context->state[7];

    for (size_t i = 0; i < 64; ++i) {
        const uint32_t big_s1 = rotate_right(e, 6) ^ rotate_right(e, 11) ^
                                rotate_right(e, 25);
        const uint32_t choose = (e & f) ^ (~e & g);
        const uint32_t temp1 = h + big_s1 + choose + kRoundConstants[i] +
                               words[i];
        const uint32_t big_s0 = rotate_right(a, 2) ^ rotate_right(a, 13) ^
                                rotate_right(a, 22);
        const uint32_t majority = (a & b) ^ (a & c) ^ (b & c);
        const uint32_t temp2 = big_s0 + majority;
        h = g;
        g = f;
        f = e;
        e = d + temp1;
        d = c;
        c = b;
        b = a;
        a = temp1 + temp2;
    }

    context->state[0] += a;
    context->state[1] += b;
    context->state[2] += c;
    context->state[3] += d;
    context->state[4] += e;
    context->state[5] += f;
    context->state[6] += g;
    context->state[7] += h;
}

}  // namespace

void sha256_init(Sha256Context* context)
{
    context->state[0] = 0x6a09e667u;
    context->state[1] = 0xbb67ae85u;
    context->state[2] = 0x3c6ef372u;
    context->state[3] = 0xa54ff53au;
    context->state[4] = 0x510e527fu;
    context->state[5] = 0x9b05688cu;
    context->state[6] = 0x1f83d9abu;
    context->state[7] = 0x5be0cd19u;
    context->byte_count = 0;
    context->block_used = 0;
}

void sha256_update(Sha256Context* context, const uint8_t* data, size_t length)
{
    context->byte_count += length;
    while (length != 0) {
        const size_t room = sizeof(context->block) - context->block_used;
        const size_t amount = length < room ? length : room;
        std::memcpy(context->block + context->block_used, data, amount);
        context->block_used += amount;
        data += amount;
        length -= amount;
        if (context->block_used == sizeof(context->block)) {
            transform(context, context->block);
            context->block_used = 0;
        }
    }
}

void sha256_final(Sha256Context* context, uint8_t digest[32])
{
    const uint64_t bit_count = context->byte_count * 8u;
    context->block[context->block_used++] = 0x80;
    if (context->block_used > 56) {
        std::memset(context->block + context->block_used, 0,
                    sizeof(context->block) - context->block_used);
        transform(context, context->block);
        context->block_used = 0;
    }
    std::memset(context->block + context->block_used, 0,
                56 - context->block_used);
    for (size_t i = 0; i < 8; ++i) {
        context->block[63 - i] = static_cast<uint8_t>(bit_count >> (i * 8));
    }
    transform(context, context->block);
    for (size_t i = 0; i < 8; ++i) {
        store_be32(digest + i * 4, context->state[i]);
    }
    std::memset(context, 0, sizeof(*context));
}

void sha256(const uint8_t* data, size_t length, uint8_t digest[32])
{
    Sha256Context context;
    sha256_init(&context);
    sha256_update(&context, data, length);
    sha256_final(&context, digest);
}

}  // namespace firmware_update
