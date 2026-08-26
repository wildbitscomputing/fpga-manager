# fpga-manager

RP2040 (Raspberry Pi Pico) firmware that programs a Wildbits K2 FPGA from
an SD card, with an optional fallback to preloaded gzip images stored in flash.

## What it does

- Reads the 2-bit context DIP switch to select one of four FPGA contexts.
- Applies a persistent per-context choice of automatic discovery, an exact SD
  pathname, replaceable flash, or embedded golden recovery.
- Exposes the available images, saved choice, and source that actually booted
  to the K2 Core Manager through the supervisor mailbox.
- Prints diagnostics over USB stdio and the K2 FTDI manager UART.
- Provides a runtime SPI supervisor service to the configured FPGA.

## Runtime supervisor

After FPGA configuration, GPIO 0 through 3 become a PIO-based SPI mode 0
slave. The FPGA polls ADC channels 0 through 3 and can stream replacement FPGA
images to SD or one of the fixed flash slots. Runtime transfers use 256-byte
frames with up to 240 payload bytes. SD remains mounted while the service is
running; its hardware SPI0 interface is independent of the PIO supervisor.

The CPU-visible register map and wire protocol are documented in
`docs/rp2040-mailbox.md` in the FPGA cores repository.

Manager boot diagnostics are mirrored at 115200 8N1 on FTDI interface 1,
normally `/dev/ttyUSB1`. FoenixMgr uses the separate FTDI interface 2,
normally `/dev/ttyUSB2`. Configure with `-DFPGA_MGR_UART_DEBUG=OFF` to disable
the manager UART output while retaining USB stdio.

## SD card layout

The SD card must be formatted as a single FAT16 or FAT32 volume. The context DIP
switch determines which of the following directories is selected as a base path:

- `CNTX1/`
- `CNTX2/`
- `CNTX3/`
- `CNTX4/`

Within the base directory, the loader first checks the context-named runtime
update (`context1.bin` through `context4.bin`). It then looks for
`Wildbits*.{gz,bin}` images (the file name lookup is case-insensitive). If
multiple `Wildbits*` images share an extension, the loader selects the
case-insensitive lexicographically greatest filename; for example,
`wildbits-2026-07-18.bin.gz` takes precedence over
`Wildbits-2026-05-29.bin.gz`.

If no matching `Wildbits*` images are found, or if the loader cannot
successfully program the FPGA using any of the found images, it falls back to
the following per-context legacy base paths, which are probed in the same order
(`.bin.gz` first, then `.bin`):

- `CNTX1/CFP95600C.bin`
- `CNTX2/CFP95616E.bin`
- `CNTX3/f256k2t9.bin`
- `CNTX4/foenix138.bin`

Gzip members are fully checked while programming: the header, deflate stream,
trailer CRC-32, and uncompressed size must be valid, and the resulting FPGA
bitstream must be exactly 9,730,652 bytes. Raw images must have the same exact
size.

In AUTO mode this discovery order is followed by replaceable flash and golden
recovery. An exact SD selection tries only that pathname before flash and
golden. A FLASH selection tries the flash slot first, then automatic SD and
golden. A GOLDEN selection never tries mutable media. The selected source and
SD pathname are stored separately for all four contexts.

The manager also bounds the FPGA `INIT_B` reset handshake, monitors `INIT_B`
while streaming, and requires it to remain high after the final startup clocks.
A configuration error therefore rejects an otherwise well-formed image and
continues to the embedded golden fallback. The K2 board does not route the
FPGA `DONE` signal to the RP2040, so firmware cannot directly sample `DONE`;
that would require a hardware revision or bodge wire.

This is configuration-level validation, not an application-core health check.
A bitstream that is accepted by the FPGA but implements a broken core, lacks the
supervisor mailbox, or never reaches its own ready state is currently considered
successfully loaded. There is no post-configuration core-ready handshake or
automatic rollback for that case. Holding RESET through the manager reboot
remains the independent route to embedded golden recovery.

## Flash slots

The upper 8 MiB contains replaceable gzip blobs at fixed addresses (2 MiB each):

- Slot 0: `0x10800000`
- Slot 1: `0x10A00000`
- Slot 2: `0x10C00000`
- Slot 3: `0x10E00000`

`CMakeLists.txt` reserves the top 8 MiB for these blobs.

Two alternating, CRC-protected 4 KiB metadata records at flash offsets
`0x7FE000` and `0x7FF000` hold selections and flash labels. The newer valid
record wins; an erased, corrupt, or interrupted update safely defaults to AUTO.
The records sit below the replaceable bank and well above the linked firmware
and golden images.

## Golden recovery images

Three immutable golden gzip images are linked into the manager firmware below
the replaceable slot bank. The build requires:

- `fpga/context1.gz`
- `fpga/context3.gz`
- `fpga/context4.gz`

Context 2 has no core yet. Selecting context 2 in forced recovery loads the
context 1 golden image as a known rescue environment.

AUTO boot tries SD, then the corresponding replaceable flash slot, then its
embedded golden image. To bypass every saved selection, hold the active-low
system reset for at least 500 ms while powering or resetting the RP2040. The
two context switches select which golden image is loaded.

After startup has observed RESET released, holding it for five seconds causes
an RP2040 watchdog reboot. This restarts the complete FPGA load sequence even
though the physical button does not directly reset the RP2040. Keeping RESET
held through the reboot selects golden recovery.

Runtime update commands can erase only the upper replaceable slots. They do
not expose the firmware or embedded golden-image region. Flash uploads verify
every programmed page by reading it back and commit the gzip header page last;
an interrupted upload therefore remains invalid and falls through to golden
recovery rather than looking like a usable slot.

## Build

Prerequisites:

- Raspberry Pi Pico SDK
- CMake + a build tool (Ninja or Make)
- Python 3 (optional, used for UF2 concatenation)
- `picotool` (optional, for combined UF2 with FPGA blobs)
- [`just` command runner](https://github.com/casey/just) (optional, for simpler
  command-line builds)

Example build:

```sh
mkdir -p build
cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build .
```

or simply

```sh
just build
```

Artifacts (in `build/`):

- `fpga_mgr.uf2` (main firmware)
- `fpga_mgr.elf` / `fpga_mgr.bin`
- `fpga_mgr_with_fpga.uf2` (`--target fpga_mgr_with_fpga_uf2`, requires
  `picotool` + Python)

## Combined UF2 with FPGA images

If `picotool` and Python 3 are available, CMake exposes a target that bundles
the firmware UF2 with the gzip images from `fpga/` into one UF2:

```sh
cmake --build . --target fpga_mgr_with_fpga_uf2
```

or

```sh
just build-with-fpga-load
```

## Tools

- `tools/concat_uf2.py`: concatenates UF2 files to form a single image.
- `k2/k2uploader.asm`: builds KUP and PGZ versions of the K2 uploader, which
  streams a gzip image through the FPGA supervisor mailbox into a
  replaceable flash slot. See `k2/README.md` for usage.
- `k2/k2coremgr.asm`: builds the interactive PGZ catalog, selection, status,
  and immediate-reconfiguration UI.

## Future architecture

The proposed manifest-based core bundles, FPGA-SD runtime loader, 65816 and
MicroBlaze V loader options, and possible static-shell/partial-reconfiguration
architecture are recorded in
[`docs/core-bundles-and-loader.md`](docs/core-bundles-and-loader.md). They are
future design work and are not part of the current manager implementation.
