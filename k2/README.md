# K2 FPGA Manager

`k2coremgr.pgz` is the interactive K2 FPGA Manager. It obtains the image
catalog directly from the RP2040, including files on the manager's
configuration SD card, the replaceable flash slot, and the embedded recovery
image when browsing context 4. Contexts 1 through 3 have no embedded core.
The manager marks the persistent selection with `*` and the source that
actually booted with `+`; `>` is the movable cursor.

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
the manager reports that the supervisor is offline.

Keys available in both views:

| Key | Action |
| --- | --- |
| `Tab` | Switch between the RP2040 core catalog and local K2 SD browser |
| `Up` / `Down` | Move the highlighted row |
| `F1` | Show the keyboard help screen |
| `F2` | Show the RP2040 boot diagnostics |
| `F3` | Copy the selected gzip core to the displayed context's flash slot |
| `F5` | Copy the selected image from the current SD card to the other SD card |
| `F8` | Restart the RP2040 and repeat FPGA loading |
| `R` | Rescan the core catalog or reread the local directory |
| `Q` | Restart the K2 |

RP2040 core catalog controls:

| Key | Action |
| --- | --- |
| `Left` / `Right` | Select the previous or next K2 context. Navigation wraps between contexts 1 and 4 |
| `Enter` | Run the highlighted entry once without changing the persistent boot selection |
| `F7` | Save the selected entry as the default |
| `S` | Save the selected entry as default and run it |
| `Delete`/`D` | Ask for confirmation, then permanently delete the highlighted manager-SD image |

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
percentage bar, and confirmed KiB counts.

Catalog-view `F5` works with visible manager-SD `.bin` and `.gz` entries. It
copies the selected image into the directory last viewed in the local K2 SD
browser (the filesystem root before that browser has been used). The RP2040
accepts only an exact entry from a freshly rebuilt context catalog. The K2
writes a hidden `.<name>.part` file, checks the complete byte count and CRC-32
against the RP2040, closes it, and then replaces the final local filename. A
progress bar reports bytes successfully written to the K2 SD.

The one-shot `Enter` path is held only in RP2040 RAM. It does not update the
metadata journal, so a later power cycle or reset still uses the
entry marked `*`. `F7` updates that marker without disturbing the running
core. `S` updates the marker and then launches the selected core in one go.

Delete is restricted to entries on SD. The confirmation dialog shows the pathname
and requires `Y` to confirm the action. The RP2040 rebuilds the
catalog immediately before deletion and accepts only an exact, visible `.bin`
or `.gz` entry in the displayed `CNTXn` directory. Deleting the currently
running image does not stop the already-configured FPGA, but it will not be
available at the next boot. Files in the local K2 SD browser are not deleted by
this command.

Local K2 SD browser controls:

| Key | Action |
| --- | --- |
| `Up` / `Down` | Move by one entry |
| `Left` / `Right` | Move backward or forward by 10 entries |
| `Enter` on a directory | Open the highlighted directory |
| `F5` on `.bin` / `.gz` | Copy the highlighted image into the displayed context directory on the RP2040 manager SD card |
| `Backspace` or `Delete` | Return to the parent directory |

A local-view `F5` copy does not program flash or boot the image. It copies the file
from the K2-visible SD card to `CNTXn/` on the separate RP2040 manager SD card.
The manager first validates the format and size and calculates CRC-32. A second
pass writes a hidden temporary file; the RP2040 verifies the byte count, CRC,
and gzip structure before atomically replacing the destination. The UI then
returns to the catalog with the installed image highlighted. Press `Enter` to
run it once, `F7` to save it as the default without running it, `S` to save it
as the default and run it, or catalog-view `F3` to copy it from manager SD into
flash when it is a gzip image.

Local-view `F3` bypasses the manager SD and streams a gzip directly into the
replaceable flash slot for the displayed context. Raw `.bin` files and gzip
files larger than the 2 MiB slot are rejected before erasure. The flash upload
uses the same two-pass local-file validation, acknowledged byte counts, CRC-32,
gzip trailer check, page readback, first-page-last commit, filename metadata,
and progress display. It does not change the saved boot selection or run the
core. This path remains available when the RP2040 SD card is absent; `F5` then
reports that manager-SD installation is unavailable.

During either operation, the validation pass reports bytes scanned. The write
pass shows a percentage and the byte count acknowledged by the RP2040 rather
than merely the amount read from the local file.

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
visible characters. It records the selected boot policy, source paths or slots
attempted, gzip and FPGA configuration rejection reasons, fallback decisions,
and the image that ultimately loaded. For example, an unsuccessful explicit
flash selection can report:

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
does not cause flash wear.
