#include <algorithm>
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>
#define MINIZ_NO_ZLIB_COMPATIBLE_NAMES
#include "miniz.h"

constexpr size_t FPGA_SIZE = 9730652;
constexpr size_t BUFFER_SIZE = 32768;
uint8_t Buffer0[BUFFER_SIZE], gzip_file_buffer[2048];
using UINT = unsigned;
using FRESULT = int;
constexpr int FR_OK = 0;
struct FIL { std::vector<uint8_t> bytes; size_t position = 0; };
FRESULT f_read(FIL* file, void* data, UINT length, UINT* read) {
    *read = std::min<size_t>(length, file->bytes.size() - file->position);
    std::memcpy(data, file->bytes.data() + file->position, *read);
    file->position += *read;
    return FR_OK;
}
uint64_t time_us_64() { static uint64_t time = 0; return ++time; }
void boot_logf(const char*, ...) {}
std::vector<uint8_t> expected_output;
size_t transferred = 0;
bool finished = false;
bool f256k2_init_prg_fpga() { return true; }
bool f256k2_prg_block_fpga(const uint8_t* bytes, unsigned length) {
    for (unsigned i = 0; i < length; ++i) {
        assert(bytes[i] == (expected_output.empty() ? static_cast<uint8_t>(transferred + i) : expected_output.at(transferred + i)));
    }
    transferred += length;
    return true;
}
bool finish_fpga_programming() { finished = true; return true; }
std::vector<uint8_t> pool_input;
const uint8_t* core_flash_span(uint8_t, uint32_t offset, size_t* length) {
    *length = offset >= pool_input.size() ? 0 : std::min<size_t>(17 - offset % 17, pool_input.size() - offset);
    return *length ? pool_input.data() + offset : nullptr;
}
#include "gzip_functions.inc"
int main(int argc, char** argv) {
    assert(argc == 4 || argc == 5);
    if (argc == 5) {
        std::ifstream expected(argv[4], std::ios::binary);
        expected_output.assign(std::istreambuf_iterator<char>(expected), std::istreambuf_iterator<char>());
        assert(expected_output.size() == FPGA_SIZE);
    }
    std::ifstream input(argv[1], std::ios::binary);
    FIL file{{std::istreambuf_iterator<char>(input), std::istreambuf_iterator<char>()}};
    const bool expected = std::string(argv[2]) == "1";
    const std::string mode = argv[3];
    if (mode == "zlib") {
        std::vector<uint8_t> output(10000);
        mz_ulong length = output.size();
        const int result = mz_uncompress(output.data(), &length, file.bytes.data(), file.bytes.size());
        assert((result == MZ_OK) == expected);
        return 0;
    }
    gzip_source_t source{};
    if (mode == "pool") { pool_input = file.bytes; source.pool_slot = 0; }
    else if (mode == "file") source.file = &file;
    else { source.memory = file.bytes.data(); source.memory_size = file.bytes.size(); }
    const bool accepted = program_fpga_from_gzip_source(&source, mode == "memory");
    assert(accepted == expected);
    assert(finished == expected);
    if (expected) assert(transferred == FPGA_SIZE);
}
