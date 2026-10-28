#include "gzip_inspect.h"
#include "miniz.h"
#include <cstring>

namespace
{
uint8_t output[32768];
uint32_t le32(const uint8_t *p)
{
    return uint32_t(p[0]) | uint32_t(p[1]) << 8 | uint32_t(p[2]) << 16 |
           uint32_t(p[3]) << 24;
}
} // namespace
bool inspect_legacy_gzip(const uint8_t *data, size_t capacity, GzipInspection *result)
{
    constexpr uint32_t expected_size = 9730652;
    if (!data || !result || capacity < 18 || data[0] != 0x1f || data[1] != 0x8b ||
        data[2] != 8 || (data[3] & 0xe0))
    {
        return false;
    }
    size_t pos = 10;
    if (data[3] & 4)
    {
        if (capacity - pos < 2)
        {
            return false;
        }
        const size_t n = data[pos] | (size_t(data[pos + 1]) << 8);
        pos += 2;
        if (n > capacity - pos)
        {
            return false;
        }
        pos += n;
    }
    for (unsigned flag = 8; flag <= 16; flag *= 2)
    {
        if (data[3] & flag)
        {
            while (pos < capacity && data[pos])
            {
                ++pos;
            }
            if (pos == capacity)
            {
                return false;
            }
            ++pos;
        }
    }
    if (data[3] & 2)
    {
        if (capacity - pos < 2 ||
            uint16_t(mz_crc32(0, data, pos)) !=
                (unsigned(data[pos]) | unsigned(data[pos + 1]) << 8))
        {
            return false;
        }
        pos += 2;
    }
    mz_stream stream{};
    if (mz_inflateInit2(&stream, -MZ_DEFAULT_WINDOW_BITS) != MZ_OK)
    {
        return false;
    }
    stream.next_in = data + pos;
    stream.avail_in = capacity - pos;
    uint32_t size = 0;
    mz_ulong crc = 0;
    int status;
    do
    {
        stream.next_out = output;
        stream.avail_out = sizeof(output);
        status = mz_inflate(&stream, MZ_NO_FLUSH);
        const size_t n = sizeof(output) - stream.avail_out;
        if (n > expected_size - size || (!n && status != MZ_STREAM_END))
        {
            mz_inflateEnd(&stream);
            return false;
        }
        size += n;
        crc = mz_crc32(crc, output, n);
    } while (status == MZ_OK);
    pos += stream.total_in;
    mz_inflateEnd(&stream);
    if (status != MZ_STREAM_END || size != expected_size || capacity - pos < 8 ||
        le32(data + pos) != crc || le32(data + pos + 4) != expected_size)
    {
        return false;
    }
    pos += 8;
    for (size_t i = pos; i < capacity; ++i)
    {
        if (data[i] != 0xff)
        {
            return false;
        }
    }
    result->size = pos;
    result->crc = mz_crc32(0, data, pos);
    return true;
}
