# K2 FPGA Manager

K2 FPGA Manager turns the RP2040 on the Wildbits/K2 into an FPGA boot
supervisor. It chooses a core for the physical context selected by the DIP
switches, programs the Artix FPGA, and then stays available to the running K2
through a small supervisor mailbox.

The companion [K2 Core Manager](k2/README.md) application provides the user
interface. From the K2 itself it can browse cores on either SD card, copy them
between cards, install gzip images into replaceable flash, choose the next boot
core, inspect the boot log, and start a core without changing the saved default.

## Hardware revisions

K2 hardware was produced by Wildbits and by Foenix Retro Systems (FRS). The
firmware target is determined by the revision printed on the PCB:

| Hardware | Revision |
| --- | --- |
| Wildbits K2 or FRS purple board | RevB0C |
| Earlier FRS black prototype board | RevB3B |

The Wildbits PCB is also black, so color alone does not distinguish it from an
FRS black board. Use the printed revision when choosing firmware.

## What a context represents

The K2 has four hardware contexts selected by the physical DIP switches. A
context selects both an FPGA core and one 512 KiB slice of the K2's 2 MiB NOR
flash. The core defines the hardware presented by the FPGA; the associated NOR
slice supplies that context's firmware or operating environment. Changing the
context can therefore change the identity of the machine, rather than merely
selecting a different application.

Current examples include the 65816-based K2 2x core and a 6809 core intended
for NitrOS-9. Other platform-specific cores can use the remaining contexts and
their independent NOR slices. Because the DIP switches also select the NOR
slice, the manager can prepare another context but cannot switch the running
machine into it in software. Select the context physically and restart the K2.

## System model

The manager works with four physical FPGA contexts and four kinds of storage:

| Storage | Role |
| --- | --- |
| RP2040 SD card | Core library, organized as `CNTX1/` through `CNTX4/`. |
| K2/MicroKernel SD card | The user's normal filesystem and a convenient source or destination for core files. |
| K2 NOR flash | Four 512 KiB slices selected by the physical context switches. This is separate from the RP2040's flash. |
| RP2040 flash | One replaceable 2 MiB gzip slot per context, plus firmware and one immutable recovery core shared by contexts 1 and 4. |

Each context has an independent saved boot choice. The available choices are:

- `AUTO`: discover a core on the RP2040 SD card, then try the context's
  replaceable flash slot;
- an exact SD path: try that file, then the replaceable flash slot;
- `FLASH`: try the replaceable slot, then automatic SD discovery; or
- `GOLDEN`: boot the immutable recovery image. This choice exists in contexts
  1 and 4; both use the same embedded payload.

Contexts 1 and 4 add the immutable recovery image after the mutable fallbacks
above. Contexts 2 and 3 have no embedded core. If every mutable source for one
of those contexts fails, move the physical switches to context 1 or 4 and use
the recovery environment to repair the affected SD directory, flash slot, or
saved selection. Context 4 retains this fallback for compatibility with the
original K2 context layout; it does not consume a second copy of the image.

The embedded image is the board-specific K2 2x core shared by contexts 1 and 4:

- `fpga/B0C/context1.gz` for RevB0C hardware
- `fpga/B3B/context1.gz` for RevB3B hardware

The two FPGA bitstreams are not interchangeable and are clearly marked in the
releases as two separate versions.

## Recovery workflow

Context 1 is the normal 2x environment and the recommended recovery path for
the whole machine. Context 4 provides the same recovery image for historical
compatibility.

1. Set the physical context switches to context 1.
2. Restart the computer. If the saved context-1 sources are suspect, keep RESET
   held through the restart to force the embedded recovery core.
3. Run `k2coremgr.pgz`.
4. Use Left/Right to inspect another context. Copy a core from the local K2 SD
   with `F5`, program its flash slot with `F3`, or save a new default with
   `F7`.
5. Set the physical switches to the repaired context and restart the machine.

The manager may maintain another context while a recovery core is running, but
it cannot run that context in place: the DIP switches also select the
corresponding FLASH area for the core to use and must be changed before boot.

## Core files and SD layout

The RP2040 SD card must contain a single FAT16 or FAT32 volume. Missing context
directories are created automatically when the card is writable:

```text
CNTX1/
CNTX2/
CNTX3/
CNTX4/
```

The card is optional. Without it, the supervisor can still boot and update the
replaceable flash slots, and contexts 1 and 4 can still use embedded recovery.

Raw `.bin` and gzip-compressed `.bin.gz`/`.gz` cores are accepted from SD. The
uncompressed FPGA payload must be exactly 9,730,652 bytes. Replaceable flash
accepts gzip only, and the compressed file must fit in its 2 MiB slot.

Automatic SD discovery checks, in order:

1. `CNTXn/contextn.bin`;
2. visible `Wildbits*.gz` and `Wildbits*.bin` files, newest name first by
   case-insensitive lexical order;
3. the traditional context basename (`CFP95600C`, `CFP95616E`, `f256k2t9`, or
   `foenix138`), compressed before raw.

Directories, dotfiles, and FAT hidden/system entries are omitted from the
catalog. Named uploads use hidden temporary and backup files so an interrupted
copy does not replace the previous destination.

## Using the K2 application

`k2coremgr.pgz` opens the RP2040 catalog. `Tab` switches to the K2's local SD
browser. The most important controls are:

| Key | Action |
| --- | --- |
| Up/Down | Move the selection |
| Left/Right | Change context in the catalog, or jump ten entries in the local SD browser |
| Enter | Run the selected core once without changing the default |
| `F3` | Copy the selected gzip core into the displayed context's flash slot |
| `F5` | Copy a local-SD core to RP2040 SD, or copy an SD, flash, or golden catalog image to K2 SD |
| `F7` | Save the selected catalog entry as the default |
| `S` | Save the selected entry as default and run it |
| `F2` | Display the RP2040 boot and fallback log |
| `F8` | Restart the RP2040 and repeat FPGA loading |
| `U` | From the local SD view, install a board-specific `.k2fw` FPGA Manager update |
| Q | Restart the K2 through the FPGA host-reset registers |
| RUN/STOP | Close Help or Diagnostics; cancel image validation |

Catalog markers are an amber triangle for the cursor, a green check for the
saved default, and an orange dot for the core that actually booted. See
[k2/README.md](k2/README.md) for more details.

## Safety and validation

The manager validates gzip structure, CRC-32, uncompressed size, FPGA `INIT_B`
behavior, flash page readback, and persistent metadata. Flash uploads erase and
verify in bounded steps, write the gzip header page last, and commit metadata
only after the image is complete. An interrupted upload is therefore invalid
rather than deceptively bootable.

Boot selections and flash labels live in alternating CRC-protected metadata
sectors. A corrupt or erased journal defaults context 1 to `GOLDEN` and the
other contexts to `AUTO`. Context 4's `AUTO` path still ends with the shared
embedded recovery image if its SD and replaceable-flash candidates fail.

The K2 does not route the FPGA `DONE` pin to the RP2040. The manager can prove
that a bitstream has the right shape and that `INIT_B` remained healthy, but it
cannot prove that the loaded core reached a useful application state. A core
that lacks the supervisor mailbox also cannot be managed after it starts.
The embedded recovery core in context 1 or 4 is the independent way back from
either case.

## Installing firmware

Release packages contain separate UF2 and ELF files for the two board
revisions. Check the revision of your K2 PCB and use only the matching
file:

| PCB revision | BOOTSEL | SWD |
| --- | --- | --- |
| RevB0C | `fpga_mgr_B0C.uf2` | `fpga_mgr_B0C.elf` |
| RevB3B | `fpga_mgr_B3B.uf2` | `fpga_mgr_B3B.elf` |

The release package's `K2-FPGA-MANAGER.pdf` contains the installation guide,
operating reference, and recovery procedures.
The UF2 and ELF include the same supervisor firmware and matching immutable
recovery core, shared by contexts 1 and 4. They do not overwrite the four
replaceable slots.

These factory images introduce the protected first-stage loader and must be
installed once through BOOTSEL or SWD when migrating from older firmware.
They initialize the separate firmware-update journal but preserve core boot
metadata and all replaceable FPGA slots.
After that migration, normal releases can be installed in-system: copy the
matching `.k2fw` package to the K2 SD card, select it in the Core Manager's
Local SD view, and press `U`. The update does not require the optional RP2040
SD card. See [the firmware-update design](docs/rp2040-firmware-updates.md) for
the flash layout and rollback guarantees.

## Building

Prerequisites are the Raspberry Pi Pico SDK, CMake and a build tool. Python 3,
Node.js/npm, `picotool`, `64tass`, [`uv`](https://docs.astral.sh/uv/), and
[`just`](https://github.com/casey/just) support the combined UF2, K2
application, PDF documentation, and release workflows. The first PDF build
downloads pinned Mermaid CLI and headless-browser versions through `npx`.

```sh
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
make -C k2 core-manager
```

Equivalent shortcuts are:

```sh
just build
just build-k2-core-manager
just package-release
```

The main build produces board-qualified factory/recovery `.uf2`, `.elf`, and
`.bin` files in `build/`. It also produces board-qualified `.k2fw` application
packages and internally linked `fpga_mgr_app_*` artifacts. Use the factory UF2
or ELF for the one-time loader migration and for recovery; after that,
`k2coremgr.pgz` can install matching `.k2fw` packages in-system. The optional
`_with_fpga.uf2` target also initializes context 1's replaceable flash slot
with the recovery core; the normal firmware already contains its own immutable
copy.

Run the package-format and cross-language image-validation tests with:

```sh
just test-firmware-packages
```

The project version in `CMakeLists.txt` is the source of truth for UF2 metadata,
the mailbox firmware version, and the release ZIP name. Release builds keep USB
diagnostics enabled and disable the optional FTDI UART mirror. Configure with
`-DFPGA_MGR_UART_DEBUG=ON` when that UART trace is needed.

To substitute a different shared recovery image in a private build:

```sh
cmake -S . -B build \
  -DGOLDEN_B0C_CONTEXT1=/path/to/core.bin.gz \
  -DGOLDEN_B0C_CONTEXT1_LABEL=descriptive-name.bin.gz
```

Use the corresponding `GOLDEN_B3B_CONTEXT1` variables for RevB3B.

## Runtime interface

After programming the FPGA, the RP2040 remains available as a PIO-based SPI
mode-0 slave. The FPGA exposes this service to the 65816 at `$DDE0-$DDEF`.
The protocol supports catalog snapshots, persistent selections, boot status
and logs, transactional SD transfers, verified flash programming, deletion,
one-shot reconfiguration, and supervisor restart.

The CPU register map and wire format are maintained in
`docs/rp2040-mailbox.md` in the FPGA cores repository. That specification is
authoritative for command layouts, response pipelining, retry behavior, and
error values; the top-level README deliberately does not duplicate a
version-by-version protocol changelog.

## Repository map

- `fpga_mgr.cpp`, `supervisor_service.cpp`: boot and runtime supervisor logic
- `boot_config.cpp`: persistent selections and replaceable-slot metadata
- `fpga/B0C/`, `fpga/B3B/`: board-specific recovery payloads shared by contexts 1 and 4
- `k2/`: interactive manager and standalone uploader for the 65816
- `release/README.md`: end-user installation and quick-reference guide
- `docs/core-bundles-and-loader.md`: future bundle/loader architecture notes
- `docs/rp2040-firmware-updates.md`: failure-safe in-system firmware update design and implementation

The firmware is distributed under the BSD 3-Clause License. The portions of
the K2 interface adapted from PEXEC retain their MIT notice in
[`k2/PEXEC-NOTICE.md`](k2/PEXEC-NOTICE.md).
