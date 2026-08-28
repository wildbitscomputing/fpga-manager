# K2 FPGA Manager and flash uploader

`k2coremgr.pgz` is the interactive K2 FPGA Manager. It obtains the image
catalog directly from the RP2040, including files on the manager's
configuration SD card, the replaceable flash slot, and the embedded golden
image. It marks the persistent selection with `*` and the source that actually
booted with `+`; `>` is the movable cursor.

Build and launch it from the development host with:

```sh
make -C k2 core-manager
just run-k2-core-manager
```

## K2 FPGA Manager controls

The manager starts in the RP2040 core catalog for the currently running
context. `Tab` switches between that catalog and a browser for the K2's local
65816/MicroKernel SD card.

If the running FPGA core does not expose an online RP2040 supervisor mailbox,
the manager reports that the supervisor is offline. Pressing any key at that
prompt restarts the K2 through the TinyVicky host-reset registers.

Keys available in both views:

| Key | Action |
| --- | --- |
| `Tab` | Switch between the RP2040 core catalog and local K2 SD browser. |
| `Up` / `Down` | Move the highlighted row. The list scrolls when necessary. |
| `F1` | Show the keyboard help screen. Press any key to return. |
| `F2` | Show the RP2040 boot diagnostics. Press any key to return. |
| `F3` | Copy the highlighted gzip core to the displayed context's replaceable flash slot. |
| `F5` | Copy the highlighted image from the current SD-card view to the other SD card. |
| `F8` | Restart the RP2040 supervisor and repeat FPGA loading with the saved boot policy. |
| `R` | Refresh the current view: rescan the core catalog or reread the local directory. |
| `Esc` or `Q` | Restart the K2 through the TinyVicky host-reset registers. |

On keyboards whose firmware layer maps the physical F-key row through Shift,
use the combination that produces the cooked `F2` value; `l` is always
available as an equivalent diagnostic shortcut.

RP2040 core catalog controls:

| Key | Action |
| --- | --- |
| `Left` / `Right` | Select the previous or next K2 context. Navigation wraps between contexts 1 and 4. |
| `Enter` | Run the highlighted entry once without changing the persistent boot selection. |
| `F7` | Save the highlighted entry as the persistent selection without running it. |
| `S` | Save the highlighted entry as the persistent selection and immediately reconfigure the FPGA with it. |
| `Delete` | Ask for confirmation, then permanently delete the highlighted manager-SD image. |

The catalog may browse and maintain any of the four contexts, but `Enter` and
`S` can run only the context selected by the physical DIP switches. Attempting
to run another context displays an explanatory message and leaves the running
FPGA and saved selections unchanged. Use `F7` if the intention is only to set
that other context's default for its next DIP-selected boot.

Catalog-view `F3` works only when the highlighted catalog entry has source `SD` and format
`gzip`. `AUTO`, `FLASH`, `GOLDEN`, and raw `.bin` entries cannot be copied this
way. The RP2040 verifies every programmed flash page by readback and commits
the gzip header page last. While copying, the area below the catalog shows
separate flash-erase, image-write, and metadata-finalization stages, a
full-width percentage bar, and confirmed KiB counts. After `Enter` or `S`
requests reconfiguration, the manager waits because the currently running FPGA
core—and therefore its mailbox—may be replaced underneath it.

Catalog-view `F5` works with visible manager-SD `.bin` and `.gz` entries. It
copies the selected image into the directory last viewed in the local K2 SD
browser (the filesystem root before that browser has been used). The RP2040
accepts only an exact entry from a freshly rebuilt context catalog. The K2
writes a hidden `.<name>.part` file, checks the complete byte count and CRC-32
against the RP2040, closes it, and then replaces the final local filename. A
progress bar reports bytes successfully written to the K2 SD. `F5` does not
change the default, program flash, or run the exported core.

The one-shot `Enter` path is held only in RP2040 RAM. It does not update the
two-sector metadata journal, so a later power cycle or reset still uses the
entry marked `*`. `F7` updates that marker without disturbing the running
core. `S` updates the marker and then launches the selected core.

Delete is restricted to entries whose source is `SD`. The confirmation shows
the pathname and requires `Y`; every other key cancels. The RP2040 rebuilds the
catalog immediately before deletion and accepts only an exact, visible `.bin`
or `.gz` entry in the displayed `CNTXn` directory. If the file was the
persistent selection, that context is reset to `AUTO`. Deleting the currently
running image does not stop the already-configured FPGA, but it will not be
available at the next boot. Files in the local K2 SD browser are not deleted by
this command.

Local K2 SD browser controls:

| Key | Action |
| --- | --- |
| `Up` / `Down` | Move by one entry. |
| `Left` / `Right` | Move backward or forward by 10 entries, clamped at the first or last entry. |
| `Enter` on a directory | Open the highlighted directory. |
| `F5` on `.bin` / `.gz` | Copy the highlighted image into the displayed context directory on the RP2040 manager SD card. |
| `Enter` on a file | No action. |
| `Backspace` or `Delete` | Return to the parent directory. At the filesystem root this has no effect. |

A local-view `F5` copy does not program flash or boot the image. It copies the file
from the K2-visible SD card to `CNTXn/` on the separate RP2040 manager SD card.
The manager first validates the format and size and calculates CRC-32. A second
pass writes a hidden temporary file; the RP2040 verifies the byte count, CRC,
and gzip structure before atomically replacing the destination. The UI then
returns to the catalog with the installed image highlighted. Press `Enter` to
run it once, `F7` to save it as the default without running it, `S` to save it
as the default and run it, or catalog-view `F3` to
copy it from manager SD into flash when it is a gzip image.

Local-view `F3` bypasses the manager SD and streams a gzip directly into the
replaceable flash slot for the displayed context. Raw `.bin` files and gzip
files larger than the 2 MiB slot are rejected before erasure. The flash upload
uses the same two-pass local-file validation, acknowledged byte counts, CRC-32,
gzip trailer check, page readback, first-page-last commit, filename metadata,
and progress display as the standalone uploader. It does not change the saved
boot selection or run the core. This path remains available when the RP2040 SD
card is absent; `F5` then reports that manager-SD installation is unavailable.

During either operation, the validation pass reports bytes scanned. The write
pass shows a percentage and the byte count acknowledged by the RP2040 rather
than merely the amount read from the local file.

For keyboards or environments that report cooked character input, these
compatibility aliases are also accepted:

| Key | Equivalent |
| --- | --- |
| `b` | `Enter` (run once) |
| `c` | `Right` |
| `d` | `Delete` |
| `e` | `F5` (copy manager-SD image to local SD) |
| `l` | `F2` |
| `r` | Refresh current view |
| `q` | Restart the K2 (`Esc`) |

The catalog marker columns mean:

| Marker | Meaning |
| --- | --- |
| `>` | Movable cursor/currently highlighted entry. |
| `*` | Persistent boot selection for the displayed context. |
| `+` | Image that actually booted. This can differ from `*` after fallback. |

### Boot diagnostics

The `F2` screen shows up to 32 messages from the current RP2040 boot and later
runtime reconfiguration attempts, oldest first. Once full, the ring discards
the oldest line as each new line arrives. Individual lines retain at most 67
visible characters. It records the selected boot
policy, source paths or slots attempted, gzip and FPGA configuration rejection
reasons, fallback decisions, and the image that ultimately loaded. For
example, an unsuccessful explicit flash selection can report:

```text
Policy: FLASH
Try FLASH slot 4
Reject: data after gzip member is not erased
FLASH slot 4 failed
Fallback: FLASH -> automatic SD
Try SD: CNTX4/context4.bin
Loaded SD: CNTX4/WildbitsK2_example.bin.gz
```

The log is a bounded RAM buffer. It is cleared whenever the RP2040 reboots and
does not cause flash wear. It can only be displayed while the running FPGA core
implements the RP2040 supervisor mailbox. The diagnostic viewer and mailbox
command require supervisor firmware 1.6 or newer.

Incremental manager-SD-to-flash progress requires supervisor firmware 1.7 or
newer. The interactive manager uses the staged copy commands added in 1.7;
the earlier blocking copy command remains supported by the firmware for older
clients.

Catalog deletion requires supervisor firmware 1.8 or newer.

One-shot catalog reconfiguration requires supervisor firmware 1.9 or newer.
Command `0x14` accepts the displayed context plus a catalog source/path and
arms that exact policy for the next runtime load without writing the persistent
selection journal. The usual source-specific recovery path remains active if
the requested image cannot configure the FPGA.

Supervisor restart through `F8` requires supervisor firmware 1.10 or newer.
Command `0x15` acknowledges the request before arming a watchdog restart; the
RP2040 then repeats context detection and the complete FPGA boot-selection and
fallback sequence.

Manager-SD-to-local-SD copying through catalog-view `F5` requires supervisor firmware 1.11 or newer.
Commands `0x16` through `0x18` provide a catalog-constrained read session with
offset validation, one-chunk replay for retry recovery, and a final size and
CRC-32 result.

Supervisor firmware 1.12 or newer also enforces the physical context on every
runtime reconfiguration command, so an older or custom client cannot bypass
the manager UI's context check.

The adapted pexec UI portions retain pexec's MIT license; see
[`PEXEC-NOTICE.md`](PEXEC-NOTICE.md).

The selection survives power cycles. AUTO preserves the traditional SD →
flash → golden search; an exact SD selection falls back to flash and then
golden if unavailable; FLASH falls back to automatic SD and then golden; and
GOLDEN always uses embedded recovery. Holding RESET during manager startup
still overrides every saved choice and forces golden.

The uploader remains available for adding or replacing a flash image.

The uploader is available as both a one-block KUP command (`k2uploader.bin`)
and a PGZ program (`k2uploader.pgz`). Both stream a gzip FPGA image from a
MicroKernel filesystem into one of the RP2040 manager's four replaceable
2 MiB flash slots.

Build both versions with:

```sh
make -C k2
```

Use `make -C k2 kup` or `make -C k2 pgz` to build only one format.

Copy the desired uploader and a `.bin.gz` FPGA image to a K2-accessible
filesystem. Run the KUP command directly:

```text
k2uploader.bin <slot 1-4> <file.bin.gz>
```

For example:

```text
k2uploader.bin 2 0:WildbitsK2_test.bin.gz
```

The current PGZ is a hardware-test build with fixed inputs: slot 4 and
`0:fe.gz`. It can therefore be launched directly from the development host
without moving the K2 SD card:

```text
just run-k2-uploader
```

The ignored project-local `foenixmgr.ini` selects the stable by-id path for
`/dev/ttyUSB2` and the MicroKernel CROSSDEV launch mode.

It can also be launched through `pexec`; command-line arguments are ignored by
this test build:

```text
/- k2uploader.pgz
```

After the PGZ uploader succeeds or reports an error, it waits safely and asks
for a K2 reset.

Slot numbers are user-facing context numbers 1 through 4. The program scans
the file once to calculate its compressed size and CRC-32, checks the gzip
header and the expected FPGA size in its trailer, then reopens it for the
upload. Do not power off after the program starts erasing the selected slot.

The K2 filesystem and the RP2040 configuration card are separate hardware
interfaces, so the supervisor may keep its configuration card mounted while
the program reads the upload image through the MicroKernel filesystem.

Flash slots accept standard gzip files containing the 9,730,652-byte raw FPGA
bitstream. The RP2040 validates the gzip CRC-32 and uncompressed size while
programming the FPGA. Raw `.bin` files remain supported when loading directly
from SD, but they are too large for the 2 MiB flash slots. Runtime gzip upload
target 2 requires RP2040 supervisor firmware 1.1 or newer. This uploader
requires firmware 1.3 or newer: it uses the cumulative byte-count and final
commit-status verification added in 1.2, and sends the pathname-label extension
added in 1.3. The label, compressed size, and CRC appear in the flash catalog.
The integrated manager-SD install target and SD-to-flash command require
supervisor firmware 1.5 or newer.

Each data chunk is accepted only when the supervisor's cumulative compressed
byte count advances by exactly that chunk's length. A missing chunk is retried,
and completion is reported only after `IMAGE_STATUS` confirms that the upload
is inactive at the expected final size. The uploader also places a `PING`
before each payload command for compatibility with the current FPGA mailbox's
8-bit pipelined response sequence.

The uploader does not reconfigure the FPGA automatically. Reboot with the
desired context selected, or issue a separate `RECONFIGURE` mailbox command,
after a successful upload.
