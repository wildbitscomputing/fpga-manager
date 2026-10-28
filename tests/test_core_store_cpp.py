from pathlib import Path
import gzip
import random
import shutil
import subprocess
import tempfile
import unittest
ROOT = Path(__file__).resolve().parents[1]
class CoreStoreTests(unittest.TestCase):
    def test_allocation_and_power_failures(self):
        compiler = shutil.which('c++')
        if not compiler: self.skipTest('requires host C++ compiler')
        with tempfile.TemporaryDirectory() as temporary:
            exe = Path(temporary) / 'pool'
            subprocess.run([compiler, '-std=c++17', '-O2', '-Wall', '-Wextra', '-Werror', '-I'+str(ROOT),
                str(ROOT/'tests/core_store_host_test.cpp'), str(ROOT/'core_store.cpp'),
                str(ROOT/'firmware_image.cpp'), str(ROOT/'sha256.cpp'), '-o', str(exe)],check=True)
            subprocess.run([str(exe)],check=True)

    def test_legacy_migration_and_large_image(self):
        if not shutil.which('c++') or not shutil.which('cc'):
            self.skipTest('requires host compilers')
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            objects = []
            for name in ('miniz.c', 'miniz_tinfl.c'):
                obj = directory / (name+'.o')
                subprocess.run(['cc','-O2','-DMINIZ_NO_DEFLATE_APIS','-I'+str(ROOT),'-c',str(ROOT/name),'-o',str(obj)],check=True)
                objects.append(str(obj))
            exe = directory / 'migration'
            sources = ['tests/core_flash_host_test.cpp','core_flash.cpp','core_store.cpp',
                       'gzip_inspect.cpp','firmware_image.cpp','sha256.cpp']
            subprocess.run(['c++','-std=c++17','-O2','-Wall','-Wextra','-Werror',
                '-DMINIZ_NO_ZLIB_COMPATIBLE_NAMES','-I'+str(ROOT),
                *(str(ROOT/s) for s in sources),*objects,'-o',str(exe)],check=True)
            raw = random.Random(1).randbytes(3*1024*1024) + b'\0'*(9730652-3*1024*1024)
            large = directory/'large.gz';large.write_bytes(gzip.compress(raw,mtime=0))
            subprocess.run([str(exe),str(ROOT/'fpga/B0C/context1.gz'),str(large)],check=True)
