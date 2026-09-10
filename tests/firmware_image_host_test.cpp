#include <algorithm>
#include <cstdint>
#include <cstdio>
#include <fstream>
#include <iterator>
#include <string>
#include <vector>

#include "firmware_image.h"
#include "sha256.h"

namespace {

bool expect(bool condition, const char* message)
{
    if (!condition) {
        std::fprintf(stderr, "host firmware-image test failed: %s\n", message);
    }
    return condition;
}

}  // namespace

int main(int argc, char** argv)
{
    if (argc != 3) {
        std::fprintf(stderr, "usage: %s <package.k2fw> <B0C|B3B>\n", argv[0]);
        return 2;
    }

    constexpr uint8_t expected_abc[32] = {
        0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
        0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
        0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
        0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad,
    };
    uint8_t digest[32];
    firmware_update::sha256(reinterpret_cast<const uint8_t*>("abc"), 3,
                            digest);
    if (!expect(std::equal(std::begin(digest), std::end(digest),
                           std::begin(expected_abc)),
                "SHA-256 known-answer vector")) {
        return 1;
    }

    const std::string board_name = argv[2];
    const auto board = board_name == "B0C"
                           ? firmware_update::BoardRevision::B0C
                           : firmware_update::BoardRevision::B3B;
    if (board_name != "B0C" && board_name != "B3B") {
        std::fprintf(stderr, "unknown board revision: %s\n", argv[2]);
        return 2;
    }

    std::ifstream input(argv[1], std::ios::binary);
    std::vector<uint8_t> package((std::istreambuf_iterator<char>(input)),
                                 std::istreambuf_iterator<char>());
    if (!expect(input.good() || input.eof(), "read generated package") ||
        !expect(package.size() > firmware_update::kManifestSectorSize,
                "read generated package")) {
        return 1;
    }

    using firmware_update::ImageValidation;
    if (!expect(firmware_update::validate_firmware_image(package.data(), board) ==
                    ImageValidation::Ok,
                "Python-generated package accepted by C++ validator")) {
        return 1;
    }
    const auto other_board = board == firmware_update::BoardRevision::B0C
                                 ? firmware_update::BoardRevision::B3B
                                 : firmware_update::BoardRevision::B0C;
    if (!expect(firmware_update::validate_firmware_image(package.data(),
                                                          other_board) ==
                    ImageValidation::WrongBoard,
                "wrong-board package rejected")) {
        return 1;
    }

    auto future_loader = package;
    future_loader[10] = firmware_update::kLoaderAbiVersion + 1;
    if (!expect(firmware_update::validate_firmware_image(future_loader.data(),
                                                          board) ==
                    ImageValidation::IncompatibleLoader,
                "future loader ABI rejected")) {
        return 1;
    }

    auto corrupt_header = package;
    corrupt_header[16] ^= 1;
    if (!expect(firmware_update::validate_firmware_image(corrupt_header.data(),
                                                          board) ==
                    ImageValidation::BadHeaderCrc,
                "header corruption rejected by CRC")) {
        return 1;
    }

    auto corrupt_payload = package;
    corrupt_payload.back() ^= 1;
    if (!expect(firmware_update::validate_firmware_image(corrupt_payload.data(),
                                                          board) ==
                    ImageValidation::BadPayloadHash,
                "payload corruption rejected by SHA-256")) {
        return 1;
    }
    return 0;
}
