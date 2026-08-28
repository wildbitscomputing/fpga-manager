#pragma once

#include <cstddef>

constexpr size_t kBootLogCapacity = 32;
constexpr size_t kBootLogLineLength = 68;

void boot_log_reset();
void boot_logf(const char* format, ...)
    __attribute__((format(printf, 1, 2)));

size_t boot_log_count();
const char* boot_log_line(size_t index);
