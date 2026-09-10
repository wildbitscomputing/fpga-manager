from __future__ import annotations

import shutil
import struct
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))

import firmware_package as package


def application_payload(size: int = 4096) -> bytes:
    data = bytearray((index * 17 + 3) & 0xFF for index in range(size))
    payload_address = package.XIP_BASE + package.APPLICATION_PAYLOAD_OFFSET
    struct.pack_into(
        "<II",
        data,
        package.SDK_VECTOR_OFFSET,
        0x20042000,
        payload_address + 0x201,
    )
    return bytes(data)


class CppFirmwareImageTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        compiler = shutil.which("c++")
        if compiler is None:
            raise unittest.SkipTest("a host C++ compiler is not installed")
        cls.temporary = tempfile.TemporaryDirectory()
        cls.directory = Path(cls.temporary.name)
        cls.executable = cls.directory / "firmware_image_host_test"
        subprocess.run(
            [
                compiler,
                "-std=c++17",
                "-Wall",
                "-Wextra",
                "-Werror",
                f"-I{ROOT}",
                str(ROOT / "tests" / "firmware_image_host_test.cpp"),
                str(ROOT / "firmware_image.cpp"),
                str(ROOT / "sha256.cpp"),
                "-o",
                str(cls.executable),
            ],
            check=True,
        )
        cls.engine_executable = cls.directory / "firmware_update_engine_host_test"
        subprocess.run(
            [
                compiler,
                "-std=c++17",
                "-Wall",
                "-Wextra",
                "-Werror",
                f"-I{ROOT}",
                str(ROOT / "tests" / "firmware_update_engine_host_test.cpp"),
                str(ROOT / "firmware_update_engine.cpp"),
                str(ROOT / "firmware_image.cpp"),
                str(ROOT / "sha256.cpp"),
                "-o",
                str(cls.engine_executable),
            ],
            check=True,
        )
        cls.staging_executable = cls.directory / "firmware_staging_host_test"
        subprocess.run(
            [
                compiler,
                "-std=c++17",
                "-Wall",
                "-Wextra",
                "-Werror",
                f"-I{ROOT}",
                str(ROOT / "tests" / "firmware_staging_host_test.cpp"),
                str(ROOT / "firmware_staging.cpp"),
                str(ROOT / "firmware_update_engine.cpp"),
                str(ROOT / "firmware_image.cpp"),
                str(ROOT / "sha256.cpp"),
                "-o",
                str(cls.staging_executable),
            ],
            check=True,
        )

    @classmethod
    def tearDownClass(cls) -> None:
        if hasattr(cls, "temporary"):
            cls.temporary.cleanup()

    def test_python_packages_match_cpp_validator(self) -> None:
        for board in package.BOARD_IDS:
            with self.subTest(board=board):
                image = package.create_package(
                    application_payload(), board, "1.16", "cross-language-test"
                )
                path = self.directory / f"test-{board}.k2fw"
                path.write_bytes(image)
                subprocess.run(
                    [str(self.executable), str(path), board], check=True
                )

    def test_power_failure_state_machine(self) -> None:
        for board in package.BOARD_IDS:
            with self.subTest(board=board):
                old_path = self.directory / f"old-{board}.k2fw"
                candidate_path = self.directory / f"candidate-{board}.k2fw"
                old_path.write_bytes(
                    package.create_package(
                        application_payload(), board, "1.16", "old-image"
                    )
                )
                candidate_path.write_bytes(
                    package.create_package(
                        application_payload(6144),
                        board,
                        "1.17",
                        "candidate-image",
                    )
                )
                subprocess.run(
                    [
                        str(self.engine_executable),
                        str(old_path),
                        str(candidate_path),
                        board,
                    ],
                    check=True,
                )

    def test_incremental_staging_receiver(self) -> None:
        for board in package.BOARD_IDS:
            with self.subTest(board=board):
                old_path = self.directory / f"staging-old-{board}.k2fw"
                candidate_path = self.directory / f"staging-new-{board}.k2fw"
                older_path = self.directory / f"staging-older-{board}.k2fw"
                old_path.write_bytes(
                    package.create_package(
                        application_payload(), board, "1.16", "staging-old"
                    )
                )
                candidate_path.write_bytes(
                    package.create_package(
                        application_payload(6543),
                        board,
                        "1.17",
                        "staging-candidate",
                    )
                )
                older_path.write_bytes(
                    package.create_package(
                        application_payload(), board, "1.15", "staging-older"
                    )
                )
                subprocess.run(
                    [
                        str(self.staging_executable),
                        str(old_path),
                        str(candidate_path),
                        str(older_path),
                        board,
                    ],
                    check=True,
                )


if __name__ == "__main__":
    unittest.main()
