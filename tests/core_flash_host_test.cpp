#include "core_flash.h"
#include "gzip_inspect.h"
#include "rp2040_firmware_storage.h"
#include <algorithm>
#include <cassert>
#include <cstring>
#include <fstream>
#include <iterator>
#include <vector>
using namespace firmware_update;
using namespace core_store;
std::vector<uint8_t> flash(kFlashSize, 0xff);
bool trial = false;
const uint8_t *Rp2040FirmwareStorage::read(uint32_t offset, size_t length)
{
    assert(offset + length <= flash.size());
    return flash.data() + offset;
}
StorageResult Rp2040FirmwareStorage::erase_sector(uint32_t offset)
{
    assert(offset % 4096 == 0);
    std::fill_n(flash.begin() + offset, 4096, 0xff);
    return StorageResult::Ok;
}
StorageResult Rp2040FirmwareStorage::program_page(uint32_t offset, const uint8_t *bytes)
{
    assert(offset % 256 == 0);
    for (unsigned i = 0; i < 256; ++i)
    {
        assert((flash[offset + i] & bytes[i]) == bytes[i]);
        flash[offset + i] &= bytes[i];
    }
    return StorageResult::Ok;
}
StorageResult Rp2040FirmwareStorage::checkpoint(UpdateCheckpoint)
{
    return StorageResult::Ok;
}
FlashSlotInfo boot_config_flash_slot(uint8_t)
{
    FlashSlotInfo info{};
    info.valid = true;
    std::strcpy(info.label, "legacy");
    return info;
}
void boot_logf(const char *, ...) {}
bool firmware_trial_active()
{
    return trial;
}
std::vector<uint8_t> file(const char *path)
{
    std::ifstream f(path, std::ios::binary);
    return {std::istreambuf_iterator<char>(f), {}};
}
int main(int argc, char **argv)
{
    assert(argc == 3);
    auto old = file(argv[1]), large = file(argv[2]);
    std::fill(flash.begin() + kReservedOffset, flash.begin() + kUpdateJournalOffsetA, 0);
    assert(old.size() < kLegacySlotSize && large.size() > 3 * 1024 * 1024);
    std::copy(old.begin(), old.end(), flash.begin() + kPoolOffset);
    std::copy(old.begin(), old.end(),
              flash.begin() + kPoolOffset + 3 * kLegacySlotSize);
    flash[kPoolOffset + kLegacySlotSize + 10] =
        0x12; // Unknown data must not disappear.
    auto original = flash;
    core_flash_init();
    assert(!core_flash_dynamic());
    trial = true;
    assert(core_flash_begin(2, large.size(), "large") != Result::Ok);
    assert(flash == original);
    trial = false;
    assert(core_flash_begin(2, large.size(), "large") == Result::Ok);
    assert(core_flash_dynamic() && core_flash_reserved(1));
    assert(core_flash_info(0).compressed_size == old.size());
    while (!core_flash_erased())
    {
        assert(core_flash_erase_next() == Result::Ok);
    }
    for (size_t pos = 0; pos < large.size(); pos += 256)
    {
        uint8_t page[256];
        std::memset(page, 0xff, sizeof(page));
        std::memcpy(page, large.data() + pos,
                    std::min<size_t>(256, large.size() - pos));
        assert(core_flash_write_page(pos, page) == Result::Ok);
    }
    // Map is unchanged until commit, even though new data is fully written.
    assert(!core_flash_info(2).valid);
    assert(core_flash_commit(0x1234) == Result::Ok);
    core_flash_init();
    assert(core_flash_info(2).valid);
    std::vector<uint8_t> readback(large.size());
    assert(core_flash_read(2, 0, readback.data(), readback.size()));
    assert(readback == large);
    size_t offset = 0, spans = 0;
    while (offset < large.size())
    {
        size_t length;
        auto *data = core_flash_span(2, offset, &length);
        assert(data && length <= kBlockSize);
        assert(!std::memcmp(data, large.data() + offset, length));
        offset += length;
        ++spans;
    }
    assert(spans > 48);
    assert(!std::memcmp(flash.data() + kPoolOffset, old.data(), old.size()));
    assert(!std::memcmp(flash.data() + kPoolOffset + 3 * kLegacySlotSize, old.data(),
                        old.size()));
    assert(std::equal(flash.begin() + kPoolOffset + kLegacySlotSize,
                      flash.begin() + kPoolOffset + 2 * kLegacySlotSize,
                      original.begin() + kPoolOffset + kLegacySlotSize));
    assert(core_flash_clear(1) == Result::Ok && !core_flash_reserved(1));
    GzipInspection result{};
    assert(inspect_legacy_gzip(large.data(), large.size(), &result));
    assert(result.size == large.size());
    large[large.size() - 8] ^= 1;
    assert(!inspect_legacy_gzip(large.data(), large.size(), &result));
    std::puts("Migration, reserved legacy data, fragmented >3 MiB upload/export and "
              "gzip validation passed");
}
