#include "core_store.h"
#include <algorithm>
#include <cstring>

namespace core_store
{
using namespace firmware_update;
namespace
{
uint32_t checksum(const Record &r)
{
    return firmware_crc32(reinterpret_cast<const uint8_t *>(&r), offsetof(Record, crc));
}
bool newer(uint32_t a, uint32_t b)
{
    return static_cast<int32_t>(a - b) > 0;
}
bool blank(const uint8_t *bytes, size_t length)
{
    if (!bytes)
    {
        return false;
    }
    for (size_t i = 0; i < length; ++i)
    {
        if (bytes[i] != 0xff)
        {
            return false;
        }
    }
    return true;
}
} // namespace
bool record_valid(const Record &r)
{
    if (r.magic != kMagic || r.format != kFormat || r.size != sizeof(r) ||
        r.crc != checksum(r))
    {
        return false;
    }
    bool used[kBlockCount]{};
    for (const Image &image : r.images)
    {
        if (image.reserved || !std::memchr(image.label, 0, sizeof(image.label)))
        {
            return false;
        }
        if (image.kind == Kind::Empty)
        {
            if (image.count || image.size)
            {
                return false;
            }
            continue;
        }
        if ((image.kind != Kind::Gzip && image.kind != Kind::Reserved) ||
            image.size < 18 || image.size > kCapacity ||
            image.count != (image.size + kBlockSize - 1) / kBlockSize)
        {
            return false;
        }
        for (unsigned n = 0; n < image.count; ++n)
        {
            const unsigned block = image.blocks[n];
            if (block >= kBlockCount || used[block])
            {
                return false;
            }
            used[block] = true;
        }
    }
    return true;
}
bool requires_pool_firmware(FirmwareStorage &storage)
{
    // Any programmed guard byte fences off old firmware, even if a write tore.
    if (!blank(storage.read(kGuardOffset, 256), 256))
    {
        return true;
    }
    for (uint32_t offset : {kRecordA, kRecordB})
    {
        const auto *r =
            reinterpret_cast<const Record *>(storage.read(offset, sizeof(Record)));
        if (!r || r->magic == kMagic)
        {
            return true;
        }
    }
    return false;
}
State Store::load()
{
    active_ = false;
    const auto *a =
        reinterpret_cast<const Record *>(storage_.read(kRecordA, sizeof(Record)));
    const auto *b =
        reinterpret_cast<const Record *>(storage_.read(kRecordB, sizeof(Record)));
    const bool av = a && record_valid(*a), bv = b && record_valid(*b);
    if (av || bv)
    {
        current_offset_ =
            av && (!bv || newer(a->sequence, b->sequence)) ? kRecordA : kRecordB;
        record_ = current_offset_ == kRecordA ? *a : *b;
        return state_ = State::Ready;
    }
    // Before the guard is committed no pool data can have been changed.
    state_ =
        blank(storage_.read(kGuardOffset, 256), 256) ? State::Legacy : State::Corrupt;
    return state_;
}
const Image &Store::image(uint8_t slot) const
{
    static const Image empty{};
    return state_ == State::Ready && slot < kContextCount ? record_.images[slot]
                                                          : empty;
}
uint32_t Store::free_bytes() const
{
    if (state_ != State::Ready)
    {
        return 0;
    }
    uint32_t blocks = kBlockCount;
    for (const auto &i : record_.images)
    {
        blocks -= i.count;
    }
    return blocks * kBlockSize;
}
bool Store::program(uint32_t offset, const uint8_t *bytes)
{
    if (storage_.program_page(offset, bytes) != StorageResult::Ok)
    {
        return false;
    }
    const auto *back = storage_.read(offset, 256);
    return back && std::memcmp(back, bytes, 256) == 0;
}
bool Store::persist()
{
    record_.sequence++;
    record_.crc = checksum(record_);
    const uint32_t dest = current_offset_ == kRecordA ? kRecordB : kRecordA;
    if (storage_.erase_sector(dest) != StorageResult::Ok)
    {
        return false;
    }
    // CRC is in the last page written, so an interrupted write is invalid.
    const auto *bytes = reinterpret_cast<const uint8_t *>(&record_);
    for (size_t pos = 0; pos < sizeof(record_); pos += 256)
    {
        std::memset(page_, 0xff, sizeof(page_));
        std::memcpy(page_, bytes + pos, std::min(sizeof(page_), sizeof(record_) - pos));
        if (!program(dest + pos, page_))
        {
            return false;
        }
    }
    const auto *back =
        reinterpret_cast<const Record *>(storage_.read(dest, sizeof(Record)));
    if (!back || !record_valid(*back) || std::memcmp(back, &record_, sizeof(record_)))
    {
        return false;
    }
    current_offset_ = dest;
    return true;
}
bool Store::guard()
{
    if (!blank(storage_.read(kGuardOffset, 256), 256))
    {
        return true;
    }
    std::memset(page_, 0xff, sizeof(page_));
    std::memcpy(page_, &kMagic, sizeof(kMagic));
    return program(kGuardOffset, page_);
}
bool Store::prepare_mutation()
{
    if (state_ != State::Ready)
    {
        return false;
    }
    // Checkpoint the current map over the older generation before reusing
    // blocks it referenced. Both surviving maps then protect every live block.
    if (!persist())
    {
        load();
        return false;
    }
    return guard();
}
Result Store::migrate(const Image (&images)[kContextCount])
{
    if (state_ != State::Legacy || active_)
    {
        return Result::Invalid;
    }
    record_ = {};
    record_.magic = kMagic;
    record_.format = kFormat;
    record_.size = sizeof(record_);
    std::memcpy(record_.images, images, sizeof(record_.images));
    record_.crc = checksum(record_);
    if (!record_valid(record_))
    {
        return Result::Invalid;
    }
    current_offset_ = kRecordB;
    if (!persist())
    {
        load();
        return Result::StorageError;
    }
    state_ = State::Ready;
    return prepare_mutation() ? Result::Ok : Result::StorageError;
}
Result Store::begin(uint8_t slot, uint32_t size, const char *label)
{
    if (active_)
    {
        return Result::Busy;
    }
    if (state_ != State::Ready || slot >= kContextCount || size < 18 ||
        size > kCapacity || !label || std::strlen(label) >= kLabelSize)
    {
        return Result::Invalid;
    }
    if (size > free_bytes())
    {
        return Result::NoSpace;
    }
    if (!prepare_mutation())
    {
        return Result::StorageError;
    }
    bool used[kBlockCount]{};
    for (const auto &image : record_.images)
    {
        for (unsigned i = 0; i < image.count; ++i)
        {
            used[image.blocks[i]] = true;
        }
    }
    pending_ = {};
    pending_.kind = Kind::Gzip;
    pending_.size = size;
    std::strcpy(pending_.label, label);
    const unsigned needed = (size + kBlockSize - 1) / kBlockSize;
    for (unsigned block = 0; block < kBlockCount && pending_.count < needed; ++block)
    {
        if (!used[block])
        {
            pending_.blocks[pending_.count++] = block;
        }
    }
    if (pending_.count != needed)
    {
        return Result::NoSpace;
    }
    pending_slot_ = slot;
    erased_blocks_ = 0;
    written_ = 0;
    active_ = true;
    return Result::Ok;
}
Result Store::erase_next()
{
    if (!active_ || erased())
    {
        return Result::Invalid;
    }
    const uint32_t offset = kPoolOffset + pending_.blocks[erased_blocks_] * kBlockSize;
    for (uint32_t n = 0; n < kBlockSize; n += kFlashSectorSize)
    {
        if (storage_.erase_sector(offset + n) != StorageResult::Ok)
        {
            return Result::StorageError;
        }
    }
    if (!blank(storage_.read(offset, kBlockSize), kBlockSize))
    {
        return Result::StorageError;
    }
    ++erased_blocks_;
    return Result::Ok;
}
Result Store::write_page(uint32_t offset, const uint8_t *page)
{
    if (!erased() || offset != written_ || offset >= pending_.size || !page)
    {
        return Result::Invalid;
    }
    const uint32_t physical = kPoolOffset +
                              pending_.blocks[offset / kBlockSize] * kBlockSize +
                              offset % kBlockSize;
    if (!program(physical, page))
    {
        return Result::StorageError;
    }
    written_ += 256;
    return Result::Ok;
}
Result Store::commit(uint32_t crc)
{
    if (!active_ || written_ < pending_.size)
    {
        return Result::Invalid;
    }
    pending_.crc = crc;
    record_.images[pending_slot_] = pending_;
    if (!persist())
    {
        load();
        return Result::StorageError;
    }
    active_ = false;
    return Result::Ok;
}
Result Store::clear(uint8_t slot)
{
    if (active_)
    {
        return Result::Busy;
    }
    if (slot >= kContextCount || state_ != State::Ready)
    {
        return Result::Invalid;
    }
    if (!prepare_mutation())
    {
        return Result::StorageError;
    }
    record_.images[slot] = {};
    if (!persist())
    {
        load();
        return Result::StorageError;
    }
    return Result::Ok;
}
const uint8_t *Store::span(uint8_t slot, uint32_t offset, size_t *length) const
{
    *length = 0;
    const Image &i = image(slot);
    if (i.kind != Kind::Gzip || offset >= i.size)
    {
        return nullptr;
    }
    *length = std::min(i.size - offset, kBlockSize - offset % kBlockSize);
    return storage_.read(kPoolOffset + i.blocks[offset / kBlockSize] * kBlockSize +
                             offset % kBlockSize,
                         *length);
}
bool Store::read(uint8_t slot, uint32_t offset, void *dest, size_t length) const
{
    const Image &i = image(slot);
    if (offset > i.size || length > i.size - offset)
    {
        return false;
    }
    auto *output = static_cast<uint8_t *>(dest);
    while (length)
    {
        size_t available;
        const auto *bytes = span(slot, offset, &available);
        if (!bytes || !available)
        {
            return false;
        }
        available = std::min(available, length);
        std::memcpy(output, bytes, available);
        output += available;
        offset += available;
        length -= available;
    }
    return true;
}
} // namespace core_store
