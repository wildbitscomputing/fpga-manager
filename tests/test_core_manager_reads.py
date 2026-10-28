"""Execute the assembled transfer path with old/fixed MicroKernel responses.

Requires 64tass and py65, e.g.:
    uv run --with py65 python3 -m unittest discover -s tests -p test_core_manager_reads.py -v

The tested path uses the 65816's 8-bit mode; BRL is handled alongside py65's
65C02 instruction set.
Kernel calls are mocked; this does not emulate hardware or the whole kernel.
"""

from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest

try:
    from py65.devices.mpu65c02 import MPU
except ImportError:
    MPU = None


ROOT = Path(__file__).resolve().parents[1]


@unittest.skipUnless(MPU and shutil.which("64tass"), "requires py65 and 64tass")
class CoreManagerReadTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.images = []
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "coremgr.bin"
            labels = Path(directory) / "coremgr.labels"
            for kup in (0, 1):
                subprocess.run(
                    ["64tass", "--quiet", "--long-branch", "-b",
                     "-D", f"CORE_MGR_KUP={kup}", f"--labels={labels}",
                     "-o", str(output), str(ROOT / "k2/k2coremgr.asm")],
                    check=True,
                )
                symbols = {}
                for name, value in re.findall(
                    r"^(\w+)\s*=\s*(\$[0-9a-fA-F]+|[0-9]+)\s*$",
                    labels.read_text(), re.MULTILINE,
                ):
                    symbols[name] = (int(value[1:], 16) if value.startswith("$")
                                     else int(value))
                cls.images.append((kup, output.read_bytes(), symbols))

    def setup_cpu(self, image, count=240, phase=0, buffer=1):
        _, binary, self.symbols = image
        self.cpu = MPU()
        self.cpu.memory[0x8000:0x8000 + len(binary)] = binary
        for name, value in {
            "EVENT_TYPE": self.symbols["EVENT_FILE_DATA"],
            "EVENT_STREAM": 7, "transfer_stream": 7,
            "EVENT_DATA_BUFFER": buffer, "EVENT_FILE_READ_COUNT": count,
            "transfer_phase": phase,
        }.items():
            self.cpu.memory[self.symbols[name]] = value
        self.payload = bytes((i * 37 + 11) & 255 for i in range(240))
        self.read_calls = 0

    def run_path(self, start, old_kernel=False, failed_call=None):
        cpu, symbols = self.cpu, self.symbols
        cpu.pc = symbols[start]
        stops = {symbols[name]: name for name in (
            "scan_chunk", "transfer_upload_data", "transfer_event_loop",
            "transfer_fail_and_close",
        )}
        for _ in range(200):
            if cpu.pc in stops:
                return stops[cpu.pc]
            if cpu.pc == symbols["KERNEL_READ_DATA"]:
                self.read_calls += 1
                length = cpu.memory[symbols["KARGS_BUFLEN"]] or 256
                destination = cpu.WordAt(symbols["KARGS_BUF"])
                cpu.memory[destination:destination + length] = self.payload[:length]
                cpu.p = (cpu.p | cpu.CARRY if old_kernel else cpu.p & ~cpu.CARRY)
                cpu.memory[cpu.pc] = 0x60  # RTS, preserving the kernel's carry
            elif failed_call and cpu.pc == symbols[failed_call]:
                cpu.p |= cpu.CARRY
                cpu.memory[cpu.pc] = 0x60
            if cpu.memory[cpu.pc] == 0x82:  # 65816 BRL from --long-branch
                offset = cpu.WordAt(cpu.pc + 1)
                cpu.pc = (cpu.pc + 3 + offset) & 0xFFFF
                continue
            cpu.step()
        self.fail("transfer path did not reach an expected boundary")

    def test_old_and_fixed_kernel_copy_identical_data(self):
        for image in self.images:
            for old in (False, True):
                for phase in (0, 1):
                    for count in (1, 239, 240):
                        with self.subTest(kup=image[0], old=old, phase=phase, count=count):
                            self.setup_cpu(image, count=count, phase=phase)
                            self.assertEqual(
                                self.run_path("transfer_data", old_kernel=old),
                                "transfer_upload_data" if phase else "scan_chunk",
                            )
                            self.assertEqual(self.read_calls, 1)
                            start = self.symbols["io_buffer"]
                            self.assertEqual(bytes(self.cpu.memory[start:start + count]),
                                             self.payload[:count])
                            self.assertEqual(self.cpu.memory[self.symbols["chunk_length"]], count)

    def test_invalid_data_event_fails_before_copy(self):
        for image in self.images:
            for count, buffer in ((0, 1), (241, 1), (255, 1), (240, 0)):
                with self.subTest(kup=image[0], count=count, buffer=buffer):
                    self.setup_cpu(image, count=count, buffer=buffer)
                    self.assertEqual(self.run_path("transfer_data"), "transfer_fail_and_close")
                    self.assertEqual(self.read_calls, 0)
                    self.assertEqual(self.cpu.memory[self.symbols["mailbox_error"]], 0xE5)

    def test_other_stream_is_ignored(self):
        for image in self.images:
            self.setup_cpu(image)
            self.cpu.memory[self.symbols["EVENT_STREAM"]] = 8
            self.assertEqual(self.run_path("transfer_data"), "transfer_event_loop")
            self.assertEqual(self.read_calls, 0)

    def test_file_errors_still_report_e5(self):
        for image in self.images:
            for event in ("EVENT_FILE_ERROR", "EVENT_FILE_NOT_FOUND"):
                with self.subTest(kup=image[0], event=event):
                    self.setup_cpu(image)
                    self.cpu.memory[self.symbols["EVENT_TYPE"]] = self.symbols[event]
                    self.assertEqual(self.run_path("transfer_have_event"), "transfer_fail_and_close")
                    self.assertEqual(self.cpu.memory[self.symbols["mailbox_error"]], 0xE5)
            for start, call in (("transfer_request_next", "KERNEL_FILE_READ"),
                                ("transfer_close_file", "KERNEL_FILE_CLOSE")):
                with self.subTest(kup=image[0], call=call):
                    self.setup_cpu(image)
                    self.assertEqual(self.run_path(start, failed_call=call), "transfer_fail_and_close")
                    self.assertEqual(self.cpu.memory[self.symbols["mailbox_error"]], 0xE5)


if __name__ == "__main__":
    unittest.main()
