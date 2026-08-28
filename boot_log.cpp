#include "boot_log.h"

#include <cstdarg>
#include <cstdio>
#include <cstring>

namespace {

char lines[kBootLogCapacity][kBootLogLineLength];
size_t line_count = 0;
size_t next_line = 0;

}  // namespace

void boot_log_reset()
{
    std::memset(lines, 0, sizeof(lines));
    line_count = 0;
    next_line = 0;
}

void boot_logf(const char* format, ...)
{
    if (!format) {
        return;
    }

    va_list arguments;
    va_start(arguments, format);
    std::vsnprintf(lines[next_line], sizeof(lines[next_line]), format, arguments);
    va_end(arguments);

    next_line = (next_line + 1) % kBootLogCapacity;
    if (line_count < kBootLogCapacity) {
        ++line_count;
    }
}

size_t boot_log_count()
{
    return line_count;
}

const char* boot_log_line(size_t index)
{
    if (index >= line_count) {
        return nullptr;
    }
    const size_t oldest = line_count == kBootLogCapacity ? next_line : 0;
    return lines[(oldest + index) % kBootLogCapacity];
}
