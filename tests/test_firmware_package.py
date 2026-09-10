from __future__ import annotations

import struct
import sys
import unittest
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools"))

import firmware_package as package


def application_payload(size: int = 4096) -> bytes:
    data = bytearray((index * 29 + 7) & 0xFF for index in range(size))
    payload_address = package.XIP_BASE + package.APPLICATION_PAYLOAD_OFFSET
    struct.pack_into(
        "<II",
        data,
        package.SDK_VECTOR_OFFSET,
        0x20042000,
        payload_address + 0x201,
    )
    return bytes(data)


class FirmwarePackageTests(unittest.TestCase):
    def make_package(self, board: str = "B0C") -> bytes:
        return package.create_package(
            application_payload(), board, "1.16", "test-build"
        )

    def test_round_trip(self) -> None:
        result = package.inspect_package(self.make_package(), "B0C")
        self.assertEqual(result.board, "B0C")
        self.assertEqual(result.version, "1.16.0")
        self.assertEqual(result.build_id, "test-build")
        self.assertEqual(result.payload_size, 4096)

    def test_factory_journal_matches_package(self) -> None:
        package_bytes = self.make_package()
        journal = package.create_factory_journal(package_bytes)
        self.assertEqual(len(journal), 8192)
        record = journal[:256]
        self.assertEqual(
            struct.unpack_from("<IHHIBBBB", record),
            (
                package.UPDATE_JOURNAL_MAGIC,
                package.UPDATE_JOURNAL_FORMAT_VERSION,
                256,
                1,
                1,
                package.BOARD_IDS["B0C"],
                0,
                0,
            ),
        )
        manifest = package.MANIFEST_PREFIX.unpack_from(package_bytes)
        self.assertEqual(record[16:48], manifest[15])
        self.assertEqual(record[48:80], manifest[16])
        self.assertEqual(
            struct.unpack_from("<I", record, 252)[0],
            zlib.crc32(record[:252]) & 0xFFFFFFFF,
        )
        self.assertEqual(journal[256:4096], b"\xFF" * (4096 - 256))
        self.assertEqual(journal[4096:], b"\0" * 4096)

    def test_wrong_board_is_rejected(self) -> None:
        with self.assertRaisesRegex(package.PackageError, "for B0C, not B3B"):
            package.inspect_package(self.make_package(), "B3B")

    def test_header_corruption_is_rejected(self) -> None:
        damaged = bytearray(self.make_package())
        damaged[200] ^= 0x80
        with self.assertRaises(package.PackageError):
            package.inspect_package(bytes(damaged))

    def test_payload_corruption_is_rejected(self) -> None:
        damaged = bytearray(self.make_package())
        damaged[-1] ^= 0x80
        with self.assertRaisesRegex(package.PackageError, "SHA-256"):
            package.inspect_package(bytes(damaged))

    def test_trailing_data_is_rejected(self) -> None:
        with self.assertRaisesRegex(package.PackageError, "length"):
            package.inspect_package(self.make_package() + b"extra")

    def test_bad_vector_is_rejected(self) -> None:
        payload = bytearray(application_payload())
        struct.pack_into("<I", payload, package.SDK_VECTOR_OFFSET + 4, 0x10000001)
        with self.assertRaisesRegex(package.PackageError, "reset vector"):
            package.create_package(bytes(payload), "B0C", "1.0", "bad-vector")

    def test_non_ascii_build_id_is_rejected(self) -> None:
        with self.assertRaisesRegex(package.PackageError, "ASCII"):
            package.create_package(
                application_payload(), "B0C", "1.0", "non-ASCII-☃"
            )

    def test_oversized_payload_is_rejected(self) -> None:
        with self.assertRaisesRegex(package.PackageError, "payload"):
            package.create_package(
                application_payload(package.APPLICATION_PAYLOAD_SIZE + 1),
                "B0C",
                "1.0",
                "too-large",
            )


if __name__ == "__main__":
    unittest.main()
