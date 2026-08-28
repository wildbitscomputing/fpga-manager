# fpga-manager

RP2040 (Raspberry Pi Pico) firmware that programs a Wildbits K2 FPGA from
an SD card, with an optional fallback to preloaded gzip images stored in flash.

## What it does

- Reads the 2-bit context DIP switch to select one of four FPGA contexts.
- Applies a persistent per-context choice of automatic discovery, an exact SD
  pathname, replaceable flash, or embedded golden recovery.
- Exposes the available images, saved choice, and source that actually booted
  to the K2 FPGA Manager through the supervisor mailbox.
- Accepts named, transactional `.bin`/`.gz` installs from the K2's separate
  MicroKernel SD card and can copy a selected manager-SD gzip into flash.
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

### Supervisor command overview

The current wire protocol is version 1 and supervisor firmware is version 1.13.
Command payloads are at most 240 bytes; contexts in the protocol are zero-based
(`0`–`3`). Multi-byte values are little-endian. The FPGA-side mailbox
specification named above is authoritative for exact request/response layouts,
status bits, error values, pipelining, retries, and nonce validation.

| Command | Name | Purpose | Added |
| --- | --- | --- | --- |
| `$00` | POLL | Advance the pipelined transport and collect an outstanding response. | 1.0 |
| `$01` | PING | Zero-payload synchronization/no-op. | 1.0 |
| `$02` | IMAGE_BEGIN | Begin a raw-SD, flash-gzip, or named-SD upload. | 1.0; targets 2/3 in 1.1/1.5 |
| `$03` | IMAGE_DATA | Append up to 240 bytes and return the cumulative accepted count. | 1.0; count in 1.2 |
| `$04` | IMAGE_END | Verify and transactionally commit the active upload. | 1.0; count in 1.2 |
| `$05` | IMAGE_ABORT | Abort an upload or incremental copy and remove temporary SD data. | 1.0 |
| `$06` | RECONFIGURE | Reconfigure a context using its saved boot policy (legacy form). | 1.0 |
| `$07` | IMAGE_STATUS | Report active/inactive state and cumulative accepted bytes. | 1.2 |
| `$08` | CATALOG_BEGIN | Snapshot one context's AUTO, SD, flash, and golden catalog. | 1.4 |
| `$09` | CATALOG_GET | Read a generation-checked catalog entry. | 1.4 |
| `$0A` | GET_SELECTION | Read one context's persistent boot selection. | 1.4 |
| `$0B` | SET_SELECTION | Persist AUTO, exact SD, FLASH, or GOLDEN for one context. | 1.4 |
| `$0C` | RECONFIGURE_SELECTED | Acknowledged reconfiguration using the saved selection. | 1.4 |
| `$0D` | CLEAR_FLASH | Invalidate a replaceable slot and clear its metadata. | 1.4 |
| `$0E` | GET_BOOT_STATUS | Report the source/name that actually configured the FPGA. | 1.4 |
| `$0F` | COPY_SD_TO_FLASH | Perform a blocking, verified manager-SD-to-flash copy. | 1.5 |
| `$10` | GET_BOOT_LOG | Read one line from the 32-line RP2040 diagnostic ring. | 1.6 |
| `$11` | COPY_SD_TO_FLASH_BEGIN | Start a staged copy with erase/write/finalize progress. | 1.7 |
| `$12` | COPY_SD_TO_FLASH_STEP | Advance and report a staged copy. | 1.7 |
| `$13` | DELETE_SD_IMAGE | Delete an exact visible SD catalog image safely. | 1.8 |
| `$14` | RECONFIGURE_ONCE | Run a source/path without changing persistent selection. | 1.9 |
| `$15` | RESTART_SUPERVISOR | Acknowledge, then restart the RP2040 and repeat FPGA loading. | 1.10 |
| `$16` | READ_SD_BEGIN | Open an exact visible manager-SD catalog image for export. | 1.11 |
| `$17` | READ_SD_DATA | Read an offset-checked, retryable chunk of that image. | 1.11 |
| `$18` | READ_SD_END | Close the export and return its verified size and CRC-32. | 1.11 |

IMAGE_BEGIN targets are legacy context-named raw SD (`0`), retired (`1`),
replaceable flash gzip (`2`), and named manager-SD install (`3`). Boot sources
are AUTO (`0`), exact SD (`1`), FLASH (`2`), and GOLDEN (`3`).

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

After mounting a writable card, the manager creates any missing context
directories automatically. A freshly formatted FAT card therefore needs no
manual folder setup. Named uploads also create their destination context
directory lazily in case it was removed while the supervisor was running.

Within the base directory, the loader first checks the context-named runtime
update (`context1.bin` through `context4.bin`). It then looks for
`Wildbits*.{gz,bin}` images (the file name lookup is case-insensitive). If
multiple `Wildbits*` images share an extension, the loader selects the
case-insensitive lexicographically greatest filename; for example,
`wildbits-2026-07-18.bin.gz` takes precedence over
`Wildbits-2026-05-29.bin.gz`.

The runtime catalog omits directories, FAT hidden or system files, and names
beginning with `.`. These entries never appear in the K2 FPGA Manager.

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

Each embedded image carries immutable build-time metadata containing its
display name, compressed size, and source context. The in-tree golden images
have their original core names assigned in `CMakeLists.txt`. A build using a
different `GOLDEN_CONTEXTn` file derives the name from that filename, or can
set `GOLDEN_CONTEXTn_LABEL` explicitly, for example:

```sh
cmake -S . -B build \
  -DGOLDEN_CONTEXT4_LABEL=WildbitsK2_2x_B0C_02020103_20260827.bin.gz
```

The catalog, running-core status, and serial boot diagnostics all report this
same embedded name. Golden metadata is compiled into the firmware rather than
written to the mutable boot journal, so it cannot become stale when firmware
and its embedded recovery images are replaced together.

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

The RP2040 SD card is optional for boot and supervisor operation. If it is
absent or cannot be mounted, SD catalog entries and SD boot attempts are
skipped; AUTO continues with the replaceable flash slot and then embedded
golden recovery. The K2 FPGA Manager still exposes the local K2 SD browser.
In that view, `F3` streams a selected gzip directly from the K2 SD interface to
the displayed context's replaceable flash slot, without staging it on the
RP2040 SD card. `F5` copying into `CNTXn/` is unavailable until a
manager SD is mounted.

Runtime update commands can erase only the upper replaceable slots. They do
not expose the firmware or embedded golden-image region. Flash uploads verify
every programmed page by reading it back and commit the gzip header page last;
an interrupted upload therefore remains invalid and falls through to golden
recovery rather than looking like a usable slot.

Supervisor firmware 1.5 adds upload target 3 for named SD installs. Its label
is a basename, its context byte selects `CNTX1` through `CNTX4`, and completion
atomically replaces `CNTXn/<basename>` through hidden `.upload`/`.old` files.
Command `0x0f` copies a validated catalog SD gzip directly into the matching
replaceable flash slot and returns only after page readback and metadata commit
succeed. Both operations reject traversal, absolute paths, unsupported
extensions, invalid FPGA sizes, and malformed gzip structure.

Supervisor firmware 1.6 adds command `0x10`, which exposes a bounded RP2040
boot diagnostic log to the K2 FPGA Manager. The 32-line RAM log records boot
policy, attempted sources, validation failures, fallbacks, and the source that
ultimately loaded. It is cleared on RP2040 reboot and therefore causes no flash
wear. Press `F2` in the K2 FPGA Manager to view it.

Supervisor firmware 1.7 adds incremental manager-SD-to-flash commands `0x11`
and `0x12`. A copy advances through independently reported erase, write, and
finalize stages; each response contains the current and total byte counts.
Flash is erased and verified in 64 KiB steps, while image data is copied and
page-verified in bounded steps. The original blocking command `0x0f` remains
available for compatibility. The K2 FPGA Manager displays these values below
the catalog as a full-width percentage bar and confirmed KiB counts.

Supervisor firmware 1.8 adds command `0x13` for deleting an RP2040 manager-SD
core image. The command accepts only an exact image from a freshly rebuilt
catalog in the requested `CNTXn` directory. It cannot delete local K2 SD files,
directories, hidden files, flash slots, golden images, or arbitrary paths. If
the deleted pathname was the persistent selection, the context returns to
`AUTO`.

Supervisor firmware 1.9 adds one-shot reconfiguration command `0x14`. Its
payload is nonce, context, source, path length, and the optional manager-SD
catalog path—the same selection shape used by command `0x0b`. The request is
validated and retained only in RAM until the acknowledged runtime
reconfiguration begins; it never updates the persistent metadata journal. In
the K2 FPGA Manager, `Enter` uses this path while `S` explicitly saves the
highlighted entry as the default before launching it.

Supervisor firmware 1.10 adds command `0x15`, an acknowledged RP2040 watchdog
restart. The K2 FPGA Manager maps `F8` to this command so the supervisor reruns
the complete saved-policy FPGA loading sequence. This is distinct from
quitting the manager: `Esc` or `Q` requests a K2 host restart through the
TinyVicky reset registers without deliberately restarting the RP2040.

Supervisor firmware 1.11 adds catalog-constrained manager-SD read commands
`0x16` through `0x18`. The K2 FPGA Manager maps catalog-view `F5` to these
commands and writes the selected `.bin` or `.gz` image into the current local
K2 SD directory. Transfer publication is staged under a hidden `.part` name;
the manager compares byte counts and CRC-32 values before replacing the final
local filename. The RP2040 rebuilds its catalog before opening the source, so
the interface cannot read arbitrary manager-SD paths.

Supervisor firmware 1.12 rejects runtime reconfiguration when the requested
context differs from the context selected by the physical DIP switches. The
catalog, SD contents, flash slot, and saved default of another context can
still be maintained, but changing context requires setting the switches and
restarting the machine.

Supervisor firmware 1.13 automatically provisions missing `CNTX1` through
`CNTX4` directories on a mounted manager SD card and retries directory creation
before SD uploads. Boot fallback remains available if the card is absent,
read-only, or otherwise cannot be provisioned.

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
- `k2/k2coremgr.asm`: builds the interactive PGZ catalog, local-SD browser,
  transactional manager-SD installer, direct local-SD-to-flash uploader,
  manager-SD-to-flash copier, selection, status, and immediate-reconfiguration
  UI.

## Future architecture

The proposed manifest-based core bundles, FPGA-SD runtime loader, 65816 and
MicroBlaze V loader options, and possible static-shell/partial-reconfiguration
architecture are recorded in
[`docs/core-bundles-and-loader.md`](docs/core-bundles-and-loader.md). They are
future design work and are not part of the current manager implementation.
