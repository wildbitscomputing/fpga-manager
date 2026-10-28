#include "core_flash.h"
#include "boot_log.h"
#include "firmware_trial.h"
#include "gzip_inspect.h"
#include "rp2040_firmware_storage.h"
#include <algorithm>
#include <cstdio>
#include <cstring>

namespace
{
Rp2040FirmwareStorage storage;
core_store::Store store(storage);
core_store::Image imported[core_store::kContextCount];
core_store::Result migrate()
{
    using namespace core_store;
    if (store.state() == State::Ready)
    {
        return Result::Ok;
    }
    if (store.state() != State::Legacy || firmware_trial_active())
    {
        return Result::Invalid;
    }
    boot_logf("Migrating legacy flash allocation");
    std::memset(imported, 0, sizeof(imported));
    for (uint8_t slot = 0; slot < kContextCount; ++slot)
    {
        const auto *data =
            storage.read(kPoolOffset + slot * kLegacySlotSize, kLegacySlotSize);
        bool empty = true;
        for (size_t i = 0; i < kLegacySlotSize; ++i)
        {
            if (data[i] != 0xff)
            {
                empty = false;
                break;
            }
        }
        if (empty)
        {
            continue;
        }
        GzipInspection gzip{};
        auto &image = imported[slot];
        if (inspect_legacy_gzip(data, kLegacySlotSize, &gzip))
        {
            image.kind = Kind::Gzip;
            image.size = gzip.size;
            image.crc = gzip.crc;
            const auto legacy = boot_config_flash_slot(slot);
            if (legacy.valid && legacy.label[0])
            {
                std::snprintf(image.label, sizeof(image.label), "%s", legacy.label);
            }
            else
            {
                std::snprintf(image.label, sizeof(image.label),
                              "Migrated flash core %u", slot + 1);
            }
        }
        else
        {
            image.kind = Kind::Reserved;
            image.size = kLegacySlotSize;
            std::snprintf(image.label, sizeof(image.label),
                          "Unrecognized legacy data %u (delete to free)", slot + 1);
            boot_logf("Reserved unrecognized legacy slot %u", slot + 1);
        }
        image.count = (image.size + kBlockSize - 1) / kBlockSize;
        for (unsigned i = 0; i < image.count; ++i)
        {
            image.blocks[i] = slot * 32 + i;
        }
    }
    return store.migrate(imported);
}
} // namespace
void core_flash_init()
{
    const auto state = store.load();
    boot_logf(state == core_store::State::Legacy ? "Flash allocation: legacy"
              : state == core_store::State::Ready
                  ? "Flash allocation: 64 KiB pool"
                  : "Flash allocation corrupt: writes disabled");
}
bool core_flash_dynamic()
{
    return store.state() != core_store::State::Legacy;
}
FlashSlotInfo core_flash_info(uint8_t slot)
{
    if (!core_flash_dynamic())
    {
        return boot_config_flash_slot(slot);
    }
    const auto &i = store.image(slot);
    FlashSlotInfo result{};
    result.valid = i.kind == core_store::Kind::Gzip;
    result.compressed_size = i.size;
    result.compressed_crc = i.crc;
    std::memcpy(result.label, i.label, sizeof(result.label));
    return result;
}
bool core_flash_reserved(uint8_t slot)
{
    return store.image(slot).kind == core_store::Kind::Reserved;
}
const uint8_t *core_flash_span(uint8_t slot, uint32_t offset, size_t *length)
{
    if (core_flash_dynamic())
    {
        return store.span(slot, offset, length);
    }
    *length = 0;
    if (slot >= 4 || offset >= core_store::kLegacySlotSize)
    {
        return nullptr;
    }
    *length = core_store::kLegacySlotSize - offset;
    return storage.read(
        core_store::kPoolOffset + slot * core_store::kLegacySlotSize + offset, *length);
}
bool core_flash_read(uint8_t slot, uint32_t offset, void *dest, size_t length)
{
    if (core_flash_dynamic())
    {
        return store.read(slot, offset, dest, length);
    }
    size_t available;
    const auto *data = core_flash_span(slot, offset, &available);
    if (!data || length > available)
    {
        return false;
    }
    std::memcpy(dest, data, length);
    return true;
}
core_store::Result core_flash_begin(uint8_t slot, uint32_t size, const char *label)
{
    if (slot >= 4 || size < 18 || size > core_store::kCapacity || !label ||
        std::strlen(label) >= core_store::kLabelSize)
    {
        return core_store::Result::Invalid;
    }
    const auto status = migrate();
    return status == core_store::Result::Ok ? store.begin(slot, size, label) : status;
}
core_store::Result core_flash_erase_next()
{
    return store.erase_next();
}
bool core_flash_erased()
{
    return store.erased();
}
uint32_t core_flash_erase_size()
{
    return store.erase_size();
}
core_store::Result core_flash_write_page(uint32_t offset, const uint8_t *page)
{
    return store.write_page(offset, page);
}
core_store::Result core_flash_commit(uint32_t crc)
{
    const auto result = store.commit(crc);
    if (result == core_store::Result::Ok)
    {
        boot_logf("Flash committed; free %lu KiB",
                  static_cast<unsigned long>(store.free_bytes() / 1024));
    }
    return result;
}
void core_flash_abort()
{
    store.abort();
}
core_store::Result core_flash_clear(uint8_t slot)
{
    const auto status = migrate();
    return status == core_store::Result::Ok ? store.clear(slot) : status;
}
