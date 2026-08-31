# K2 FPGA Manager release

This package installs the RP2040 FPGA supervisor and the interactive
`k2coremgr.pgz` utility for the Wildbits/K2.

## Choose the correct firmware

Check the hardware revision printed on the K2 board before programming it.
FPGA images for the two revisions are not electrically interchangeable.

| Board revision | BOOTSEL image | SWD image |
| --- | --- | --- |
| Wildbits or purple board | `fpga_mgr_B0C.uf2` | `fpga_mgr_B0C.elf` |
| Black board | `fpga_mgr_B3B.uf2` | `fpga_mgr_B3B.elf` |

The UF2 and ELF contain the same supervisor firmware and a board-specific
immutable context-4 recovery core. They do not overwrite existing FPGA
flash slots.

The embedded recovery core is K2 FPGA release 02020104.

## Install through RP2040 BOOTSEL

1. Connect a USB cable with Dupont connectors to the internal header in the K2
   computer. Connect the other end of this cable to a PC or Mac.
2. Put the K2's RP2040 into BOOTSEL mode by pressing the small button next to the
   board connector while powering up the K2. The host should mount an `RPI-RP2`
   USB drive.
3. Copy the matching `fpga_mgr_B0C.uf2` or `fpga_mgr_B3B.uf2` onto that drive.
4. Wait for the copy to finish and for the drive to disappear. The K2 then
   restarts and loads the FPGA according to the selected context and saved boot
   policy.

Do not program a firmware file intended for the other board revision. The
bootloader still works, but you will get no video output when running the
embedded recovery core.

## Install with an SWD probe

This is an alternative update path, e.g. when the internal header for the BOOTSEL
update is missing for some reason.

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

Successful output includes `Programming Finished`, `Verified OK`, and a target
reset.

## Install and start the K2 utility

Copy `k2coremgr.pgz` to the K2's local SD card and launch it as a
PGZ program (`/- k2coremgr`). The currently running FPGA core must implement the RP2040
supervisor mailbox. If it does not, the utility reports that the supervisor is
offline.

The manager opens the RP2040 core catalog. `Tab` switches between it and the
K2's local SD-card browser.

### Main controls

| Key | Action |
| --- | --- |
| `Up` / `Down` | Move the selection |
| `Tab` | Switch between the RP2040 catalog and local K2 SD |
| `F1` | Show the built-in help screen |
| `F2` | Show the RP2040 boot and fallback log |
| `F3` | Copy the selected gzip core into replaceable FPGA flash |
| `F5` | Copy the selected image from the current SD-card view to the other SD card |
| `F8` | Restart the RP2040 and repeat FPGA loading using the saved policy |
| `R` | Refresh the current view |
| `Q` | Restart the K2 through the FPGA host-reset registers |

### RP2040 catalog controls

| Key | Action |
| --- | --- |
| `Left` / `Right` | Browse contexts 1 through 4 |
| `Enter` | Run the selected core once without changing the default |
| `F7` | Save the selected catalog entry as the default |
| `S` | Save the selection as the default and run it |
| `Delete`/D | Confirm and delete the selected image from the RP2040 SD card |

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
| `Left` / `Right` | Jump backward or forward by ten entries |
| `Enter` on a directory | Open a directory |
| `Backspace` / `Delete` | Return to the parent directory |
| `F5` on `.bin` / `.gz` | Copy the image to the displayed context on the RP2040 SD |
| `F3` on `.gz` | Program the image directly into the displayed context's flash slot |

Direct `F3` programming remains available when no RP2040 SD card is installed.
`F5` requires both SD cards. Flash accepts gzip images only; raw FPGA images
can be run from SD but do not fit in the 2 MiB replaceable flash slots.

## Boot and recovery

The physical context switches on the back of the compputer select the active FPGA
context. Each context can save automatic discovery, an exact RP2040-SD image, or
replaceable flash as its boot policy. Context 4 can additionally select its
immutable recovery image.

- `AUTO` tries RP2040 SD, then replaceable flash.
- An exact SD selection falls back to replaceable flash.
- `FLASH` tries flash, then automatic SD discovery.
- Context 4 adds embedded recovery after those mutable fallbacks.
- `GOLDEN`, available only in context 4, goes directly to recovery core.

The RP2040 SD card is optional. Missing `CNTX1` through `CNTX4` directories are
created automatically on a writable FAT16/FAT32 card. With no usable manager
SD card, boot continues through flash and, in context 4, embedded recovery.

Contexts 1 through 3 contain no embedded cores. If one of them cannot boot from
SD or flash, set the physical switches to context 4 and restart. From the
context-4 core, `k2coremgr.pgz` can browse the other contexts, copy a
replacement with `F5`, program a flash slot with `F3`, or set a new default
with `F7`. Change the switches back and restart when the repair is complete.

Holding the K2 RESET signal while the RP2040 starts forces recovery for the
selected context. Since only context 4 has an embedded recovery image, set the
switches to context 4 first. Once the system is running, holding RESET for five
seconds restarts the RP2040; keep RESET held through that restart to force the
context-4 image.

## Package contents

| File | Purpose |
| --- | --- |
| `fpga_mgr_B0C.uf2` / `.elf` | RevB0C supervisor and context-4 recovery core. |
| `fpga_mgr_B3B.uf2` / `.elf` | RevB3B supervisor and context-4 recovery core. |
| `k2coremgr.pgz` | Interactive manager for the K2. |
| `README.md` | This installation and quick-reference guide. |
| `K2-MANAGER.md` | Detailed manager behavior and diagnostics. |
| `LICENSE` | Project license. |
