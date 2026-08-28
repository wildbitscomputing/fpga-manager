# K2 FPGA Manager release

This package installs the RP2040 FPGA supervisor and the interactive
`k2coremgr.pgz` utility for the Wildbits K2.

## Choose the correct firmware

Check the hardware revision printed on the K2 board before programming it.
FPGA images for the two revisions are not electrically interchangeable.

| Board revision | BOOTSEL image | SWD image |
| --- | --- | --- |
| RevB0C | `fpga_mgr_B0C.uf2` | `fpga_mgr_B0C.elf` |
| RevB3B | `fpga_mgr_B3B.uf2` | `fpga_mgr_B3B.elf` |

The UF2 and ELF contain the same supervisor firmware and board-specific
immutable golden recovery cores. They do not overwrite the mutable FPGA flash
slots.

## Install through RP2040 BOOTSEL

1. Put the K2's RP2040 into BOOTSEL mode. The host should mount an `RPI-RP2`
   USB drive.
2. Copy the matching `fpga_mgr_B0C.uf2` or `fpga_mgr_B3B.uf2` onto that drive.
3. Wait for the copy to finish and for the drive to disappear. The RP2040 then
   restarts and loads the FPGA according to the selected context and saved boot
   policy.

Do not program a firmware file intended for the other board revision.

## Install with an SWD probe

Connect a CMSIS-DAP probe, such as the Raspberry Pi Debug Probe, to the
RP2040's SWDIO, SWCLK, and GND signals. From a command prompt configured for
the Raspberry Pi Pico SDK's OpenOCD installation, run the command matching the
board revision:

```text
openocd -f interface/cmsis-dap.cfg -f target/rp2040.cfg -c "adapter speed 5000" -c "program fpga_mgr_B0C.elf verify reset exit"
```

or:

```text
openocd -f interface/cmsis-dap.cfg -f target/rp2040.cfg -c "adapter speed 5000" -c "program fpga_mgr_B3B.elf verify reset exit"
```

The `interface/cmsis-dap.cfg` and `target/rp2040.cfg` files come from OpenOCD,
not this release ZIP. OpenOCD normally finds them in its scripts directory. If
it does not, add `-s "C:\path\to\openocd\scripts"` before the `-f` options.

Successful output includes `Programming Finished`, `Verified OK`, and a target
reset. An `Invalid command argument` message means the `program` command line
was parsed incorrectly; use the complete quoted command above.

## Install and start the K2 utility

Copy `k2coremgr.pgz` to the K2's local MicroKernel SD card and launch it as a
PGZ program. The currently running FPGA core must implement the RP2040
supervisor mailbox. If it does not, the utility reports that the supervisor is
offline; pressing any key then restarts the K2.

The manager opens the RP2040 core catalog. `Tab` switches between it and the
K2's local SD-card browser.

### Main controls

| Key | Action |
| --- | --- |
| `Up` / `Down` | Move the selection by one entry. |
| `Tab` | Switch between the RP2040 catalog and local K2 SD. |
| `F1` | Show the built-in help screen. |
| `F2` | Show the RP2040 boot and fallback log. |
| `F3` | Copy the selected gzip core into replaceable FPGA flash. |
| `F5` | Copy the selected image from the current SD-card view to the other SD card. |
| `F8` | Restart the RP2040 and repeat FPGA loading using the saved policy. |
| `R` | Refresh the current view. |
| `Esc` / `Q` | Restart the K2 through the FPGA host-reset registers. |

Some keyboards require holding Shift to generate an F-key. `L` is also an
alias for the `F2` diagnostics screen.

### RP2040 catalog controls

| Key | Action |
| --- | --- |
| `Left` / `Right` | Browse contexts 1 through 4. |
| `Enter` | Run the selected core once without changing the saved default. |
| `F7` | Save the selection as the default without running it. |
| `S` | Save the selection as the default and run it. |
| `Delete` | Confirm and delete the selected image from the RP2040 SD card. |

`Enter` and `S` can only run the context selected by the physical DIP
switches. The manager can browse another context and use `F7` to prepare its
default, but the K2 must be restarted after changing the switches before that
context can run.

Catalog markers are `>` for the cursor, `*` for the saved default, and `+` for
the image that actually booted. The running image can differ from the default
when fallback was necessary.

### Local K2 SD controls

| Key | Action |
| --- | --- |
| `Left` / `Right` | Jump backward or forward by ten entries. |
| `Enter` on a directory | Open the directory. |
| `Backspace` / `Delete` | Return to the parent directory. |
| `F5` on `.bin` / `.gz` | Copy the image to the displayed context on the RP2040 SD. |
| `F3` on `.gz` | Program the image directly into the displayed context's flash slot. |

Direct `F3` programming remains available when no RP2040 SD card is installed.
`F5` requires both SD cards. Flash accepts gzip images only; raw FPGA images
can be run from SD but do not fit in the 2 MiB replaceable flash slots.

## Boot and recovery summary

The physical context switches select the active FPGA context. Each context can
save one of four policies: automatic discovery, an exact RP2040-SD image,
replaceable flash, or immutable golden recovery.

- `AUTO` tries RP2040 SD, then replaceable flash, then golden recovery.
- An exact SD selection falls back to flash and then golden recovery.
- `FLASH` tries flash, then automatic SD discovery, then golden recovery.
- `GOLDEN` always uses the embedded recovery image.

The RP2040 SD card is optional. Missing `CNTX1` through `CNTX4` directories are
created automatically on a writable FAT16/FAT32 card. With no usable manager
SD card, boot continues through flash and golden recovery.

Holding the K2 RESET signal while the RP2040 starts forces embedded golden
recovery. Once the system is running, holding RESET for five seconds restarts
the RP2040; keep RESET held through that restart to force golden recovery.

## Package contents

| File | Purpose |
| --- | --- |
| `fpga_mgr_B0C.uf2` / `.elf` | RevB0C supervisor and B0C golden cores. |
| `fpga_mgr_B3B.uf2` / `.elf` | RevB3B supervisor and B3B golden cores. |
| `k2coremgr.pgz` | Interactive manager for the K2. |
| `README.md` | This installation and quick-reference guide. |
| `K2-MANAGER.md` | Detailed manager behavior and diagnostics. |
| `TECHNICAL.md` | Firmware architecture, protocol, and build documentation. |
| `LICENSE` | Project license. |

