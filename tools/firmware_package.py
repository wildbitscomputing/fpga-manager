#!/usr/bin/env python3
"""Create and inspect K2 RP2040 FPGA Manager update packages."""

from __future__ import annotations

import argparse
import hashlib
import json
import struct
import sys
import zlib
from dataclasses import asdict, dataclass
from pathlib import Path

MANIFEST_MAGIC = 0x5746324B
MANIFEST_FORMAT_VERSION = 1
MANIFEST_STRUCT_SIZE = 256
MANIFEST_SECTOR_SIZE = 0x1000
MANIFEST_CRC_OFFSET = 252
LOADER_ABI_VERSION = 1

XIP_BASE = 0x10000000
ACTIVE_OFFSET = 0x010000
APPLICATION_SLOT_SIZE = 0x270000
APPLICATION_PAYLOAD_OFFSET = ACTIVE_OFFSET + MANIFEST_SECTOR_SIZE
APPLICATION_PAYLOAD_SIZE = APPLICATION_SLOT_SIZE - MANIFEST_SECTOR_SIZE
SDK_VECTOR_OFFSET = 0x100
UPDATE_JOURNAL_MAGIC = 0x4A55324B
UPDATE_JOURNAL_FORMAT_VERSION = 1
UPDATE_JOURNAL_RECORD_SIZE = 256
UPDATE_JOURNAL_SECTOR_SIZE = 0x1000

BOARD_IDS = {"B0C": 1, "B3B": 2}
BOARD_NAMES = {value: key for key, value in BOARD_IDS.items()}

# Fields through the signature. Reserved bytes and CRC are filled separately.
MANIFEST_PREFIX = struct.Struct("<IHHHHBBBBHHHHII32s32s16s64s")
assert MANIFEST_PREFIX.size == 176


class PackageError(ValueError):
    """A package or application payload is invalid."""


@dataclass(frozen=True)
class PackageInfo:
    board: str
    version: str
    loader_abi: int
    payload_size: int
    vector_offset: int
    build_id: str
    payload_sha256: str
    header_crc32: str


def parse_version(value: str) -> tuple[int, int, int]:
    parts = value.split(".")
    if not 1 <= len(parts) <= 3:
        raise PackageError("version must contain one to three numeric components")
    try:
        numbers = [int(part, 10) for part in parts]
    except ValueError as error:
        raise PackageError("version components must be decimal integers") from error
    numbers.extend([0] * (3 - len(numbers)))
    if any(number < 0 or number > 0xFFFF for number in numbers):
        raise PackageError("version components must fit in 16 bits")
    return numbers[0], numbers[1], numbers[2]


def validate_vectors(payload: bytes, vector_offset: int = SDK_VECTOR_OFFSET) -> None:
    if not payload or len(payload) > APPLICATION_PAYLOAD_SIZE:
        raise PackageError(
            f"payload must be 1..{APPLICATION_PAYLOAD_SIZE} bytes"
        )
    if vector_offset & 0xFF or vector_offset + 8 > len(payload):
        raise PackageError("vector table must be 256-byte aligned and inside payload")
    stack_pointer, reset_vector = struct.unpack_from("<II", payload, vector_offset)
    if (
        stack_pointer & 7
        or stack_pointer < 0x20000000
        or stack_pointer > 0x20042000
    ):
        raise PackageError(f"invalid initial stack pointer 0x{stack_pointer:08x}")
    payload_address = XIP_BASE + APPLICATION_PAYLOAD_OFFSET
    reset_address = reset_vector & ~1
    if not reset_vector & 1 or not (
        payload_address <= reset_address < payload_address + len(payload)
    ):
        raise PackageError(f"invalid reset vector 0x{reset_vector:08x}")


def manifest_crc32(sector: bytes | bytearray) -> int:
    if len(sector) != MANIFEST_SECTOR_SIZE:
        raise PackageError("manifest sector has the wrong size")
    crc_input = bytearray(sector)
    crc_input[MANIFEST_CRC_OFFSET : MANIFEST_CRC_OFFSET + 4] = b"\0" * 4
    return zlib.crc32(crc_input) & 0xFFFFFFFF


def create_package(
    payload: bytes,
    board: str,
    version: str,
    build_id: str,
    loader_abi: int = LOADER_ABI_VERSION,
    vector_offset: int = SDK_VECTOR_OFFSET,
) -> bytes:
    if board not in BOARD_IDS:
        raise PackageError(f"unknown board revision {board!r}")
    version_numbers = parse_version(version)
    if not 0 <= loader_abi <= 0xFFFF:
        raise PackageError("loader ABI must fit in 16 bits")
    try:
        build_id_bytes = build_id.encode("ascii")
    except UnicodeEncodeError as error:
        raise PackageError("build ID must contain only ASCII characters") from error
    if len(build_id_bytes) >= 32:
        raise PackageError("build ID must be at most 31 ASCII bytes")
    validate_vectors(payload, vector_offset)

    digest = hashlib.sha256(payload).digest()
    prefix = MANIFEST_PREFIX.pack(
        MANIFEST_MAGIC,
        MANIFEST_FORMAT_VERSION,
        MANIFEST_STRUCT_SIZE,
        MANIFEST_SECTOR_SIZE,
        loader_abi,
        BOARD_IDS[board],
        0,  # flags
        0,  # signature algorithm: reserved, not currently used
        0,
        version_numbers[0],
        version_numbers[1],
        version_numbers[2],
        0,
        len(payload),
        vector_offset,
        build_id_bytes.ljust(32, b"\0"),
        digest,
        b"\0" * 16,
        b"\0" * 64,
    )
    sector = bytearray(b"\xFF" * MANIFEST_SECTOR_SIZE)
    sector[: len(prefix)] = prefix
    sector[len(prefix) : MANIFEST_CRC_OFFSET] = b"\0" * (
        MANIFEST_CRC_OFFSET - len(prefix)
    )
    struct.pack_into("<I", sector, MANIFEST_CRC_OFFSET, 0)
    struct.pack_into("<I", sector, MANIFEST_CRC_OFFSET, manifest_crc32(sector))
    return bytes(sector) + payload


def inspect_package(package: bytes, expected_board: str | None = None) -> PackageInfo:
    if len(package) < MANIFEST_SECTOR_SIZE + 1:
        raise PackageError("package is shorter than a manifest and payload")
    sector = package[:MANIFEST_SECTOR_SIZE]
    values = MANIFEST_PREFIX.unpack_from(sector)
    (
        magic,
        format_version,
        manifest_size,
        header_sector_size,
        loader_abi,
        board_id,
        flags,
        signature_algorithm,
        reserved0,
        version_major,
        version_minor,
        version_patch,
        reserved1,
        payload_size,
        vector_offset,
        build_id_raw,
        expected_digest,
        signature_key_id,
        signature,
    ) = values
    if magic != MANIFEST_MAGIC:
        raise PackageError("bad package magic")
    if format_version != MANIFEST_FORMAT_VERSION:
        raise PackageError("unsupported package format")
    if manifest_size != MANIFEST_STRUCT_SIZE or header_sector_size != MANIFEST_SECTOR_SIZE:
        raise PackageError("invalid manifest size")
    board = BOARD_NAMES.get(board_id)
    if board is None:
        raise PackageError("unknown board identifier")
    if expected_board is not None and board != expected_board:
        raise PackageError(f"package is for {board}, not {expected_board}")
    if flags or reserved0 or reserved1:
        raise PackageError("unsupported manifest flags")
    if signature_algorithm or any(signature_key_id) or any(signature):
        raise PackageError("signature fields must be empty in format version 1")
    if any(sector[MANIFEST_PREFIX.size:MANIFEST_CRC_OFFSET]):
        raise PackageError("reserved manifest bytes are not zero")
    if any(value != 0xFF for value in sector[MANIFEST_STRUCT_SIZE:]):
        raise PackageError("manifest-sector padding is not erased")
    stored_crc = struct.unpack_from("<I", sector, MANIFEST_CRC_OFFSET)[0]
    if stored_crc != manifest_crc32(sector):
        raise PackageError("manifest CRC-32 mismatch")
    if payload_size == 0 or payload_size > APPLICATION_PAYLOAD_SIZE:
        raise PackageError("payload size is outside the application slot")
    if len(package) != MANIFEST_SECTOR_SIZE + payload_size:
        raise PackageError("package length does not match its manifest")
    try:
        build_id = build_id_raw[: build_id_raw.index(0)].decode("ascii")
    except (ValueError, UnicodeDecodeError) as error:
        raise PackageError("build ID is not a terminated ASCII string") from error

    payload = package[MANIFEST_SECTOR_SIZE:]
    validate_vectors(payload, vector_offset)
    digest = hashlib.sha256(payload).digest()
    if digest != expected_digest:
        raise PackageError("payload SHA-256 mismatch")
    return PackageInfo(
        board=board,
        version=f"{version_major}.{version_minor}.{version_patch}",
        loader_abi=loader_abi,
        payload_size=payload_size,
        vector_offset=vector_offset,
        build_id=build_id,
        payload_sha256=digest.hex(),
        header_crc32=f"{stored_crc:08x}",
    )


def create_factory_journal(package: bytes) -> bytes:
    """Create a clean CONFIRMED A record and deliberately invalid B sector."""
    info = inspect_package(package)
    sector = package[:MANIFEST_SECTOR_SIZE]
    values = MANIFEST_PREFIX.unpack_from(sector)
    board_id = BOARD_IDS[info.board]
    build_id = values[15]
    payload_digest = values[16]

    record = bytearray(UPDATE_JOURNAL_RECORD_SIZE)
    struct.pack_into(
        "<IHHIBBBB",
        record,
        0,
        UPDATE_JOURNAL_MAGIC,
        UPDATE_JOURNAL_FORMAT_VERSION,
        UPDATE_JOURNAL_RECORD_SIZE,
        1,  # sequence
        1,  # CONFIRMED
        board_id,
        0,  # no previous update result
        0,
    )
    record[16:48] = build_id
    record[48:80] = payload_digest
    struct.pack_into("<I", record, 252, zlib.crc32(record[:252]) & 0xFFFFFFFF)
    sector_a = bytes(record) + b"\xFF" * (
        UPDATE_JOURNAL_SECTOR_SIZE - len(record)
    )
    # Programming zeros makes the factory image explicitly erase and
    # invalidate journal B; a stale higher sequence can never win over A.
    sector_b = b"\0" * UPDATE_JOURNAL_SECTOR_SIZE
    return sector_a + sector_b


def command_create(args: argparse.Namespace) -> None:
    payload = args.payload.read_bytes()
    package = create_package(
        payload=payload,
        board=args.board,
        version=args.version,
        build_id=args.build_id,
        loader_abi=args.loader_abi,
    )
    args.output.write_bytes(package)
    info = inspect_package(package, args.board)
    print(json.dumps(asdict(info), indent=2))


def command_inspect(args: argparse.Namespace) -> None:
    info = inspect_package(args.package.read_bytes(), args.board)
    print(json.dumps(asdict(info), indent=2))


def command_factory_journal(args: argparse.Namespace) -> None:
    package = args.package.read_bytes()
    journal = create_factory_journal(package)
    args.output.write_bytes(journal)


def make_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    create = subparsers.add_parser("create", help="build a .k2fw package")
    create.add_argument("--payload", required=True, type=Path)
    create.add_argument("--output", required=True, type=Path)
    create.add_argument("--board", required=True, choices=sorted(BOARD_IDS))
    create.add_argument("--version", required=True)
    create.add_argument("--build-id", required=True)
    create.add_argument("--loader-abi", type=int, default=LOADER_ABI_VERSION)
    create.set_defaults(handler=command_create)

    inspect = subparsers.add_parser("inspect", help="validate a .k2fw package")
    inspect.add_argument("package", type=Path)
    inspect.add_argument("--board", choices=sorted(BOARD_IDS))
    inspect.set_defaults(handler=command_inspect)

    journal = subparsers.add_parser(
        "factory-journal", help="create factory CONFIRMED update-journal sectors"
    )
    journal.add_argument("--package", required=True, type=Path)
    journal.add_argument("--output", required=True, type=Path)
    journal.set_defaults(handler=command_factory_journal)
    return parser


def main() -> int:
    try:
        args = make_parser().parse_args()
        args.handler(args)
    except (OSError, PackageError) as error:
        print(f"firmware package error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
