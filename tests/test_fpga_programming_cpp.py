"""Host regression tests for FPGA completion/handoff and startup RESET handling.

The C++ harness models PIO status, time, and GPIO ownership; it does not replace
on-device timing validation. Functions are extracted so production code is
tested without requiring an ARM toolchain or mocking the entire application.
"""

from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]


class FpgaProgrammingTests(unittest.TestCase):
    def test_completion_and_gpio_handoff(self):
        compiler = shutil.which("c++")
        if compiler is None:
            self.skipTest("requires a host C++ compiler")
        source = (ROOT / "fpga_mgr.cpp").read_text()

        def function(name):
            match = re.search(
                rf"^static [^\n]*\b{re.escape(name)}\([^\n]*\)\n\{{.*?^\}}",
                source, re.MULTILINE | re.DOTALL,
            )
            self.assertIsNotNone(match, name)
            return match.group(0)

        constants = "\n".join(re.findall(
            r"^#define (?:FPGA_PIO_DRAIN_TIMEOUT_MS|STARTUP_RESET_HOLD_MS|FPGA_CONFIG_CCLK|"
            r"FPGA_CONFIG_INITn|FPGA_SYSTEM_RSTn|FPGA_BUS_D0)\s+\d+.*$",
            source, re.MULTILINE,
        ))
        with tempfile.TemporaryDirectory() as temporary:
            directory = Path(temporary)
            (directory / "fpga_completion_constants.inc").write_text(constants)
            functions = ["#if USE_PIO_FPGA"]
            functions += [function(name) for name in (
                "fpga_pio_set_gpio_mode", "fpga_pio_enable", "fpga_pio_wait_for_idle",
            )]
            functions += ["#endif", function("pulse_fpga_config_clock"),
                          function("finish_fpga_programming"),
                          function("startup_requests_recovery")]
            (directory / "fpga_completion_functions.inc").write_text("\n".join(functions))
            for pio in (0, 1):
                with self.subTest(pio=pio):
                    executable = directory / f"completion-{pio}"
                    subprocess.run([
                        compiler, "-std=c++17", "-Wall", "-Wextra", "-Werror",
                        f"-DUSE_PIO_FPGA={pio}", f"-I{directory}",
                        str(ROOT / "tests/fpga_programming_host_test.cpp"),
                        "-o", str(executable),
                    ], check=True)
                    subprocess.run([str(executable)], check=True)


if __name__ == "__main__":
    unittest.main()
