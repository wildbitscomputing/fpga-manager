"""Exercise production boot selection and gzip streaming on the host."""
from pathlib import Path
import gzip
import re
import random
import shutil
import subprocess
import tempfile
import unittest
import zlib

ROOT = Path(__file__).resolve().parents[1]


def extract(source, name):
    match = re.search(rf"^(?:static )?[^\n]*\b{name}\([^;{{]*\)\n\{{.*?^\}}",
                      source, re.M | re.S)
    if not match:
        raise AssertionError(name)
    return match[0]


class BootSpeedTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        if not shutil.which('c++') or not shutil.which('cc'):
            raise unittest.SkipTest('requires host C/C++ compilers')
        cls.tmp = tempfile.TemporaryDirectory()
        cls.directory = Path(cls.tmp.name)
        source = (ROOT / 'fpga_mgr.cpp').read_text()
        helpers = source[source.index('struct gzip_source_t {'):source.index('static inline void pulse_fpga_config_clock')]
        timing = source[source.index('struct GzipBootTiming {'):source.index('static bool program_fpga_from_gzip_source')]
        (cls.directory / 'gzip_functions.inc').write_text(
            helpers + timing + extract(source, 'program_fpga_from_gzip_source'))
        (cls.directory / 'selection_functions.inc').write_text('\n'.join(
            extract(source, name) for name in ('manager_sd_is_mounted', 'manager_sd_mount',
                'program_context_selection', 'program_selected_context', 'program_transient_context')))
        cls.gzip_exe = cls.directory / 'gzip-test'
        objects = []
        for name in ('miniz.c', 'miniz_tinfl.c'):
            obj = cls.directory / (name + '.o')
            subprocess.run(['cc', '-O2', '-DMINIZ_NO_DEFLATE_APIS', '-I'+str(ROOT),
                            '-c', str(ROOT / name), '-o', str(obj)], check=True)
            objects.append(str(obj))
        for harness, executable, extra in (
            ('gzip_boot_host_test.cpp', cls.gzip_exe, objects),
            ('boot_selection_host_test.cpp', cls.directory / 'selection-test', []),
        ):
            subprocess.run(['c++', '-std=c++17', '-O2', '-Wall', '-Wextra', '-Werror',
                            '-I'+str(ROOT), '-I'+str(cls.directory),
                            str(ROOT / 'tests' / harness), *extra, '-o', str(executable)], check=True)

    @classmethod
    def tearDownClass(cls):
        if hasattr(cls, 'tmp'):
            cls.tmp.cleanup()

    def test_lazy_sd_and_fallbacks(self):
        subprocess.run([str(self.directory / 'selection-test')], check=True)

    def test_gzip_boot_checks(self):
        # Cross multiple 32 KiB output blocks, using the real full FPGA image size.
        raw = (bytes(range(256)) * ((9730652 + 255) // 256))[:9730652]
        compressed = gzip.compress(raw, mtime=0)
        bad_crc = bytearray(compressed)
        bad_crc[-8] ^= 0x80
        bad_size = bytearray(compressed)
        bad_size[-4] ^= 1
        bad_deflate = bytearray(compressed)
        bad_deflate[10] = 7  # Reserved deflate block type.
        cases = [
            ('valid', compressed, True), ('crc-ignored', bad_crc, True),
            ('bad-size', bad_size, False), ('truncated', compressed[:-5], False),
            ('bad-deflate', bad_deflate, False),
            ('erased-padding', compressed + b'\xff' * 100, True),
            ('bad-padding', compressed + b'\xff\x00', False),
            ('wrong-output-size', gzip.compress(raw[:-1], mtime=0), False),
        ]
        for name, data, expected in cases:
            path = self.directory / (name + '.gz')
            path.write_bytes(data)
            for mode in ("memory", "file", "pool"):
                # SD files must end immediately after the gzip member.
                accepted = expected and not (mode != 'memory' and name == 'erased-padding')
                with self.subTest(case=name, mode=mode):
                    subprocess.run([str(self.gzip_exe), str(path), str(int(accepted)),
                                    mode], check=True,
                                   stdout=subprocess.DEVNULL)

    def test_large_fragmented_gzip_boot(self):
        raw = random.Random(42).randbytes(3*1024*1024) + b'\0'*(9730652-3*1024*1024)
        compressed = gzip.compress(raw, mtime=0)
        self.assertGreater(len(compressed), 3*1024*1024)
        source = self.directory / 'large-core.gz'
        expected = self.directory / 'large-core.bin'
        source.write_bytes(compressed)
        expected.write_bytes(raw)
        subprocess.run([str(self.gzip_exe), str(source), '1', 'pool', str(expected)],
                       check=True, stdout=subprocess.DEVNULL)

    def test_zlib_adler_still_checked(self):
        compressed = zlib.compress(b'wrapped zlib still needs its checksum' * 100)
        for corrupt in (False, True):
            data = bytearray(compressed)
            if corrupt:
                data[-1] ^= 1
            path = self.directory / 'wrapped.zlib'
            path.write_bytes(data)
            subprocess.run([str(self.gzip_exe), str(path), str(int(not corrupt)), 'zlib'], check=True)


if __name__ == '__main__':
    unittest.main()
