#include "firmware_image.h"

#include <cstring>

#include "sha256.h"

namespace firmware_update {

uint32_t firmware_crc32(const uint8_t* data, size_t length)
{
    uint32_t crc = 0xffffffffu;
    for (size_t i = 0; i < length; ++i) {
        crc ^= data[i];
        for (unsigned bit = 0; bit < 8; ++bit) {
            crc = (crc >> 1) ^ (0xedb88320u & (0u - (crc & 1u)));
        }
    }
    return ~crc;
}

uint32_t firmware_manifest_crc32(const uint8_t* manifest_sector)
{
    constexpr size_t crc_offset = offsetof(FirmwareImageManifest, header_crc32);
    uint32_t crc = 0xffffffffu;
    for (size_t i = 0; i < kManifestSectorSize; ++i) {
        const uint8_t value =
            i >= crc_offset && i < crc_offset + sizeof(uint32_t)
                ? 0
                : manifest_sector[i];
        crc ^= value;
        for (unsigned bit = 0; bit < 8; ++bit) {
            crc = (crc >> 1) ^ (0xedb88320u & (0u - (crc & 1u)));
        }
    }
    return ~crc;
}

ImageValidation validate_firmware_manifest(const uint8_t* slot,
                                           BoardRevision expected_board)
{
    if (!slot) {
        return ImageValidation::BadMagic;
    }
    const auto* manifest =
        reinterpret_cast<const FirmwareImageManifest*>(slot);
    if (manifest->magic != kManifestMagic) {
        return ImageValidation::BadMagic;
    }
    if (manifest->format_version != kManifestFormatVersion) {
        return ImageValidation::BadFormat;
    }
    if (manifest->manifest_size != sizeof(FirmwareImageManifest) ||
        manifest->header_sector_size != kManifestSectorSize) {
        return ImageValidation::BadHeaderSize;
    }
    if (manifest->board_revision != static_cast<uint8_t>(expected_board)) {
        return ImageValidation::WrongBoard;
    }
    if (manifest->required_loader_abi > kLoaderAbiVersion) {
        return ImageValidation::IncompatibleLoader;
    }
    if (manifest->flags != 0 || manifest->reserved0 != 0 ||
        manifest->reserved1 != 0) {
        return ImageValidation::BadFlags;
    }
    if (manifest->signature_algorithm != 0) {
        return ImageValidation::BadSignatureFields;
    }
    for (uint8_t value : manifest->signature_key_id) {
        if (value != 0) {
            return ImageValidation::BadSignatureFields;
        }
    }
    for (uint8_t value : manifest->signature) {
        if (value != 0) {
            return ImageValidation::BadSignatureFields;
        }
    }
    if (std::memchr(manifest->build_id, '\0', sizeof(manifest->build_id)) ==
        nullptr) {
        return ImageValidation::BadBuildId;
    }
    for (uint8_t value : manifest->reserved) {
        if (value != 0) {
            return ImageValidation::BadHeaderPadding;
        }
    }
    for (size_t i = sizeof(FirmwareImageManifest); i < kManifestSectorSize;
         ++i) {
        if (slot[i] != 0xff) {
            return ImageValidation::BadHeaderPadding;
        }
    }
    if (manifest->header_crc32 != firmware_manifest_crc32(slot)) {
        return ImageValidation::BadHeaderCrc;
    }
    if (manifest->payload_size == 0 ||
        manifest->payload_size > kApplicationPayloadSize) {
        return ImageValidation::BadPayloadSize;
    }
    if ((manifest->vector_offset & 0xffu) != 0 ||
        manifest->vector_offset + 8u > manifest->payload_size) {
        return ImageValidation::BadVectorOffset;
    }

    return ImageValidation::Ok;
}

ImageValidation validate_firmware_image(const uint8_t* slot,
                                        BoardRevision expected_board)
{
    const ImageValidation manifest_result =
        validate_firmware_manifest(slot, expected_board);
    if (manifest_result != ImageValidation::Ok) {
        return manifest_result;
    }
    const auto* manifest =
        reinterpret_cast<const FirmwareImageManifest*>(slot);

    const uint8_t* payload = slot + kManifestSectorSize;
    const uint32_t* vectors = reinterpret_cast<const uint32_t*>(
        payload + manifest->vector_offset);
    const uint32_t stack_pointer = vectors[0];
    const uint32_t reset_vector = vectors[1];
    if ((stack_pointer & 7u) != 0 || stack_pointer < 0x20000000u ||
        stack_pointer > 0x20042000u) {
        return ImageValidation::BadStackPointer;
    }
    const uintptr_t payload_address = kXipBase + kApplicationPayloadOffset;
    if ((reset_vector & 1u) == 0 || (reset_vector & ~1u) < payload_address ||
        (reset_vector & ~1u) >= payload_address + manifest->payload_size) {
        return ImageValidation::BadResetVector;
    }

    uint8_t digest[32];
    sha256(payload, manifest->payload_size, digest);
    if (std::memcmp(digest, manifest->payload_sha256, sizeof(digest)) != 0) {
        return ImageValidation::BadPayloadHash;
    }
    return ImageValidation::Ok;
}

}  // namespace firmware_update
