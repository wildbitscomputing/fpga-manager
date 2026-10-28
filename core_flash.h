#pragma once
#include "boot_config.h"
#include "core_store.h"

void core_flash_init();
bool core_flash_dynamic();
FlashSlotInfo core_flash_info(uint8_t slot);
bool core_flash_reserved(uint8_t slot);
const uint8_t *core_flash_span(uint8_t slot, uint32_t offset, size_t *length);
bool core_flash_read(uint8_t slot, uint32_t offset, void *dest, size_t length);
core_store::Result core_flash_begin(uint8_t slot, uint32_t size, const char *label);
core_store::Result core_flash_erase_next();
bool core_flash_erased();
uint32_t core_flash_erase_size();
core_store::Result core_flash_write_page(uint32_t offset, const uint8_t *page);
core_store::Result core_flash_commit(uint32_t crc);
void core_flash_abort();
core_store::Result core_flash_clear(uint8_t slot);
