#pragma once

#include <cstddef>
#include <cstdint>

#include "firmware_update_layout.h"

namespace firmware_update {

constexpr uint32_t kManifestMagic = 0x5746324bu;  // "K2FW" little-endian.
constexpr uint16_t kManifestFormatVersion = 1;
constexpr size_t kManifestStructSize = 256;

enum class BoardRevision : uint8_t {
    B0C = 1,
    B3B = 2,
};

enum class ImageValidation : uint8_t {
    Ok = 0,
    BadMagic,
    BadFormat,
    BadHeaderSize,
    WrongBoard,
    IncompatibleLoader,
    BadFlags,
    BadSignatureFields,
    BadBuildId,
    BadHeaderPadding,
    BadHeaderCrc,
    BadPayloadSize,
    BadVectorOffset,
    BadStackPointer,
    BadResetVector,
    BadPayloadHash,
};

struct __attribute__((packed)) FirmwareImageManifest {
    uint32_t magic;
    uint16_t format_version;
    uint16_t manifest_size;
    uint16_t header_sector_size;
    uint16_t required_loader_abi;
    uint8_t board_revision;
    uint8_t flags;
    uint8_t signature_algorithm;
    uint8_t reserved0;
    uint16_t version_major;
    uint16_t version_minor;
    uint16_t version_patch;
    uint16_t reserved1;
    uint32_t payload_size;
    uint32_t vector_offset;
    char build_id[32];
    uint8_t payload_sha256[32];
    uint8_t signature_key_id[16];
    uint8_t signature[64];
    uint8_t reserved[76];
    uint32_t header_crc32;
};

static_assert(sizeof(FirmwareImageManifest) == kManifestStructSize);
static_assert(offsetof(FirmwareImageManifest, header_crc32) == 252);

uint32_t firmware_crc32(const uint8_t* data, size_t length);
uint32_t firmware_manifest_crc32(const uint8_t* manifest_sector);

// Validates only the manifest sector and constraints that do not require the
// payload to be present. This is used before staging is erased.
ImageValidation validate_firmware_manifest(const uint8_t* manifest_sector,
                                           BoardRevision expected_board);

ImageValidation validate_firmware_image(const uint8_t* slot,
                                        BoardRevision expected_board);

}  // namespace firmware_update
