# K2 Core Manager and FPGA flash uploader

`k2coremgr.pgz` is the interactive boot-image manager. It obtains the image
catalog directly from the RP2040, including files on the manager's
configuration SD card, the replaceable flash slot, and the embedded golden
image. It marks the persistent selection with `*` and the source that actually
booted with `>`.

Build and launch it from the development host with:

```sh
make -C k2 core-manager
just run-k2-core-manager
```

The manager starts on the currently running context. Press `c` to cycle
contexts, `r` to refresh, or choose an entry with the displayed digit or
uppercase letter. Press `b` to reconfigure the FPGA immediately from the saved
selection. The selection survives power cycles. AUTO preserves the traditional
SD → flash → golden search; an exact SD selection falls back to flash and then
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

Each data chunk is accepted only when the supervisor's cumulative compressed
byte count advances by exactly that chunk's length. A missing chunk is retried,
and completion is reported only after `IMAGE_STATUS` confirms that the upload
is inactive at the expected final size. The uploader also places a `PING`
before each payload command for compatibility with the current FPGA mailbox's
8-bit pipelined response sequence.

The uploader does not reconfigure the FPGA automatically. Reboot with the
desired context selected, or issue a separate `RECONFIGURE` mailbox command,
after a successful upload.
