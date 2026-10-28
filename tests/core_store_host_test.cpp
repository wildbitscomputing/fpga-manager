#include "core_store.h"
#include <algorithm>
#include <cassert>
#include <cstdio>
#include <cstring>
#include <stdexcept>
#include <vector>
using namespace core_store;
using namespace firmware_update;
struct PowerLoss
{
};
class Flash : public FirmwareStorage
{
  public:
    std::vector<uint8_t> bytes = std::vector<uint8_t>(kFlashSize, 0xff);
    unsigned operations = 0, cut = 0, phase = 0;
    bool fail = false;
    const uint8_t *read(uint32_t offset, size_t size) override
    {
        assert(offset <= bytes.size() && size <= bytes.size() - offset);
        return bytes.data() + offset;
    }
    StorageResult mutate(uint32_t offset, const uint8_t *data, size_t size)
    {
        assert(offset >= kPoolOffset || offset == kGuardOffset ||
               (offset >= kRecordA && offset < kRecordA + 4096) ||
               (offset >= kRecordB && offset < kRecordB + 4096));
        ++operations;
        const bool stop = operations == cut;
        size_t n = stop ? (phase == 0 ? 0 : phase == 1 ? size / 2 : size) : size;
        for (size_t i = 0; i < n; ++i)
        {
            if (data)
            {
                assert((bytes[offset + i] & data[i]) == data[i]);
                bytes[offset + i] &= data[i];
            }
            else
            {
                bytes[offset + i] = 0xff;
            }
        }
        if (stop)
        {
            if (fail)
            {
                return StorageResult::Error;
            }
            throw PowerLoss{};
        }
        return StorageResult::Ok;
    }
    StorageResult erase_sector(uint32_t offset) override
    {
        assert(offset % 4096 == 0);
        return mutate(offset, nullptr, 4096);
    }
    StorageResult program_page(uint32_t offset, const uint8_t *data) override
    {
        assert(offset % 256 == 0);
        return mutate(offset, data, 256);
    }
    StorageResult checkpoint(UpdateCheckpoint) override
    {
        return StorageResult::Ok;
    }
};
Image legacy(unsigned slot, unsigned blocks, uint8_t value, Flash &flash)
{
    Image image{};
    image.kind = Kind::Gzip;
    image.count = blocks;
    image.size = blocks * kBlockSize - 123;
    std::snprintf(image.label, sizeof(image.label), "%u", value);
    for (unsigned n = 0; n < blocks; ++n)
    {
        image.blocks[n] = slot * 32 + n;
        std::fill_n(flash.bytes.begin() + kPoolOffset + image.blocks[n] * kBlockSize,
                    kBlockSize, value);
    }
    return image;
}
void verify(Store &store)
{
    assert(store.state() == State::Ready);
    bool used[kBlockCount]{};
    for (unsigned slot = 0; slot < 4; ++slot)
    {
        const auto &image = store.image(slot);
        for (unsigned i = 0; i < image.count; ++i)
        {
            assert(!used[image.blocks[i]]);
            used[image.blocks[i]] = true;
        }
        if (image.kind != Kind::Gzip)
        {
            continue;
        }
        unsigned value = 0;
        assert(std::sscanf(image.label, "%u", &value) == 1);
        uint32_t offset = 0;
        while (offset < image.size)
        {
            size_t length;
            const auto *data = store.span(slot, offset, &length);
            assert(data && length && length <= kBlockSize);
            for (size_t i = 0; i < length; ++i)
            {
                assert(data[i] == value);
            }
            offset += length;
        }
        uint8_t boundary[300];
        if (image.size > kBlockSize + 200)
        {
            assert(store.read(slot, kBlockSize - 100, boundary, sizeof(boundary)));
            for (auto byte : boundary)
            {
                assert(byte == value);
            }
        }
        assert(!store.read(slot, image.size, boundary, 1));
    }
}
bool upload(Store &store, unsigned slot, uint32_t size, uint8_t value)
{
    char label[8];
    std::snprintf(label, sizeof(label), "%u", value);
    if (store.begin(slot, size, label) != Result::Ok)
    {
        return false;
    }
    assert(store.commit(0) == Result::Invalid);
    while (!store.erased())
    {
        if (store.erase_next() != Result::Ok)
        {
            return false;
        }
    }
    uint8_t page[256];
    std::memset(page, value, sizeof(page));
    for (uint32_t offset = 0; offset < size; offset += 256)
    {
        if (store.write_page(offset, page) != Result::Ok)
        {
            return false;
        }
    }
    return store.commit(0x12345678) == Result::Ok;
}
void corrupt_newest(Flash &flash)
{
    const auto *a =
        reinterpret_cast<const Record *>(flash.read(kRecordA, sizeof(Record)));
    const auto *b =
        reinterpret_cast<const Record *>(flash.read(kRecordB, sizeof(Record)));
    uint32_t which = record_valid(*a) && (!record_valid(*b) ||
                                          int32_t(a->sequence - b->sequence) > 0)
                         ? kRecordA
                         : kRecordB;
    flash.bytes[which + offsetof(Record, crc)] ^= 1;
}
int main()
{
    Flash original;
    // Legacy flat factory binaries zero-fill their address gaps. These are
    // not evidence of a migrated pool; the guard must be beyond that range.
    std::fill(original.bytes.begin() + kReservedOffset,
              original.bytes.begin() + kUpdateJournalOffsetA, 0);
    assert(!requires_pool_firmware(original));
    Image images[4]{};
    for (unsigned i = 0; i < 4; ++i)
    {
        images[i] = legacy(i, 2, 10 + i, original);
    }
    Flash migrated = original;
    Store initial(migrated);
    assert(initial.load() == State::Legacy);
    assert(initial.migrate(images) == Result::Ok);
    verify(initial);
    unsigned migration_ops = migrated.operations;
    for (unsigned cut = 1; cut <= migration_ops; ++cut)
    {
        for (unsigned phase = 0; phase < 3; ++phase)
        {
            Flash f = original;
            f.cut = cut;
            f.phase = phase;
            try
            {
                Store s(f);
                s.load();
                s.migrate(images);
            }
            catch (PowerLoss &)
            {
            }
            Store restart(f);
            if (restart.load() == State::Legacy)
            {
                f.cut = 0;
                assert(restart.migrate(images) == Result::Ok);
            }
            verify(restart);
            assert(std::equal(original.bytes.begin() + kPoolOffset,
                              original.bytes.end(), f.bytes.begin() + kPoolOffset));
        }
    }
    // An image over 3 MiB spans fragments around all four retained legacy cores.
    Store s(migrated);
    s.load();
    assert(upload(s, 0, 3 * kBlockSize * 16 + 77, 42));
    verify(s);
    assert(s.image(0).size > 3 * 1024 * 1024 &&
           s.image(0).blocks[30] != s.image(0).blocks[29] + 1);
    Flash committed = migrated;
    // Fault every erase/page/metadata write during replacement and then reuse.
    auto transaction = [](Store &st)
    {
        if (!upload(st, 0, 600, 43))
        {
            return false;
        }
        return upload(st, 1, 800, 44);
    };
    Flash successful = committed;
    successful.operations = 0;
    Store done(successful);
    done.load();
    assert(transaction(done));
    verify(done);
    unsigned events = successful.operations;
    for (unsigned cut = 1; cut <= events; ++cut)
    {
        for (unsigned phase = 0; phase < 3; ++phase)
        {
            for (bool fail : {false, true})
            {
                Flash f = committed;
                f.operations = 0;
                f.cut = cut;
                f.phase = phase;
                f.fail = fail;
                try
                {
                    Store st(f);
                    st.load();
                    transaction(st);
                }
                catch (PowerLoss &)
                {
                }
                Store restart(f);
                restart.load();
                verify(restart);
                // The surviving older generation must also remain readable.
                corrupt_newest(f);
                Store older(f);
                if (older.load() == State::Ready)
                {
                    verify(older);
                }
                else
                {
                    assert(older.state() == State::Corrupt);
                    assert(older.begin(0, 20, "99") == Result::Invalid);
                }
            }
        }
    }
    // Metadata deletion preserves all other cores and releases its blocks.
    Flash deleted = committed;
    Store del(deleted);
    del.load();
    assert(del.clear(2) == Result::Ok);
    assert(del.image(2).kind == Kind::Empty);
    verify(del);
    // Reject malformed maps, duplicates, bounds and corrupted metadata.
    Record record =
        *reinterpret_cast<const Record *>(migrated.read(kRecordA, sizeof(Record)));
    auto seal = [](Record &r)
    {
        r.crc = firmware_crc32(reinterpret_cast<const uint8_t *>(&r),
                               offsetof(Record, crc));
    };
    assert(record_valid(record));
    auto bad = record;
    bad.images[1].blocks[0] = bad.images[0].blocks[0];
    seal(bad);
    assert(!record_valid(bad));
    bad = record;
    bad.images[0].blocks[0] = 128;
    seal(bad);
    assert(!record_valid(bad));
    bad = record;
    bad.images[0].count = 129;
    seal(bad);
    assert(!record_valid(bad));
    bad = record;
    bad.images[0].size = kCapacity + 1;
    seal(bad);
    assert(!record_valid(bad));
    std::fill_n(migrated.bytes.begin() + kRecordA, 4096, 0xff);
    std::fill_n(migrated.bytes.begin() + kRecordB, 4096, 0xff);
    Store lost(migrated);
    assert(lost.load() == State::Corrupt);
    assert(lost.begin(0, 20, "x") == Result::Invalid);
    assert(requires_pool_firmware(migrated));
    Flash empty;
    Store full(empty);
    full.load();
    Image none[4]{};
    assert(full.migrate(none) == Result::Ok);
    assert(full.begin(0, kCapacity, "50") == Result::Ok &&
           full.erase_size() == kCapacity);
    full.abort();
    assert(full.begin(0, kCapacity + 1, "50") == Result::Invalid);
    assert(upload(full, 0, 5 * 1024 * 1024, 51));
    const auto snapshot = empty.bytes;
    assert(full.begin(0, 4 * 1024 * 1024, "52") == Result::NoSpace);
    assert(empty.bytes == snapshot);
    verify(full);
    std::printf("Core pool: %u migration and %u replacement mutation points, partial "
                "writes/errors, fragmentation and capacity passed\n",
                migration_ops, events);
}
