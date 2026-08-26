# Future core bundles and runtime loader

Status: design direction only. This document records the architecture discussed
while developing the current RP2040 FPGA manager. It is not an implementation
plan for the current development cycle.

## Motivation

Some FPGA cores need more than a bitstream. An arcade recreation may also need
CPU, graphics, sound, palette, and sample ROMs; other cores may need firmware,
disk images, or writable save data. The K2 has two SD-card interfaces connected
to the FPGA, a physical 65816, external SRAM and DDR memory, and the separate
RP2040 FPGA manager.

A selectable core should therefore be represented by a logical bundle manifest
rather than by a bitstream filename alone. The manifest identifies the FPGA
image, its additional assets, their expected hashes, any preprocessing, and the
memory region into which each asset must be loaded.

The manifest is the bundle. Core images and assets need not all be copied into
one physical directory: a shared store avoids duplicating one core or parent ROM
set for several bundles. A future export tool may materialize a self-contained
directory for copying or archival.

One possible installed layout is:

```text
/cores/<core-id>/<version>/core.bin.gz
/manifests/<system>/<title>.wbm
/assets/<set-or-content-hash>/...
```

The two FPGA-connected cards should be enumerated by volume identity or a
manifest role instead of hard-coded slot numbers. They may conventionally be
used as a system/library card and a writable user/media card.

## Common loader semantics

The interface should describe logical transfers independently of the processor
that performs them:

- hold the application core in reset;
- mount an FPGA-connected SD card;
- read and validate the selected manifest;
- load named regions into SRAM, DDR, or BRAM;
- report progress and specific errors;
- verify sizes and hashes;
- release the application core only after all required regions succeed;
- optionally retain storage services for saves and removable media.

Large copies should be DMA-driven. A processor should parse metadata and set up
transfers rather than copy every byte itself. Compression is an attribute of an
asset, not of the loader protocol. Pre-normalized raw or gzip region files are a
sensible first format; complicated ROM interleaving can initially be performed
by a host-side bundle tool.

## Incremental implementation options

### Physical 65816

The 65816 could run the loader firmware if every participating FPGA core
provides a standard CPU bus, boot ROM window, SD block controller, DMA engine,
and memory-target registers. With DMA, filesystem and control work may be fast
enough despite the processor's limited performance. This option consumes no
soft-CPU logic and reuses the native K2 environment, so it should be measured
before choosing another processor.

The physical CPU survives FPGA configuration electrically, but its usable
execution state may not: the FPGA supplies its bus and memory interfaces.
Survival therefore requires an explicitly designed handover and common bus
environment.

### Loader soft CPU in every complete core

A small 32-bit RISC-V processor such as MicroBlaze V would make C firmware,
FatFs, gzip, large-address handling, and standard bus peripherals easier. A
minimal common subsystem could contain:

```text
RV32IC processor and BRAM firmware
SD block controller(s)
DMA/load-region engine
CRC/hash support
UART diagnostics
application reset and status registers
```

In this model the RP2040 programs a complete bitstream and then becomes idle.
The newly configured loader reads the bundle from an FPGA-connected SD card and
starts the application. The subsystem must be versioned and delivered as a
reusable platform component so that third-party core authors do not recreate
the protocol or vendor-IP configuration.

This processor is not equivalent to MiSTer's ARM supervisor: it is part of the
FPGA configuration and disappears during the next complete reconfiguration.

### Static supervisor and partial reconfiguration

A persistent soft-CPU supervisor requires a static FPGA shell. The shell would
own the MicroBlaze V, both SD interfaces, memory arbitration, RP2040 link,
configuration access, clocks, reset, and any common user interface. Application
cores would be partial bitstreams placed in a fixed reconfigurable region.

```text
RP2040: power-on boot, immutable recovery, golden shell
    |
static FPGA shell: bundle menu, SD, memory, ICAP, MicroBlaze V
    |
reconfigurable region: computer, console, or arcade application core
```

This would be the closest analogue to MiSTer's ARM/HPS architecture: the
supervisor remains active while it replaces and services the application core.
It could select a bundle, load a partial bitstream through ICAP, populate memory,
service saves, and return to the menu without using the RP2040 data path.

Dynamic Function eXchange also imposes substantial constraints:

- all application cores target an exact shell and partition interface version;
- static infrastructure permanently consumes FPGA resources;
- the reconfigurable region has a fixed floorplan and resource budget;
- I/O, clocking, memory, video, audio, and reset ownership must be standardized;
- partial bitstreams require strict shell/device compatibility checks;
- timing closure and build/release testing become more complicated;
- complete legacy and recovery images remain necessary.

The RP2040 should remain the recovery authority even if a static supervisor is
eventually adopted. It can load a known-good complete shell at power-on and
recover a failed or incompatible shell independently of the FPGA soft CPU.

## Recommended progression

1. Stabilize and test the current complete-image selection and recovery path.
2. Specify the bundle manifest and memory-region semantics independently of a
   particular loader CPU.
3. Develop reusable FPGA SD block and DMA components.
4. Prototype and benchmark a 65816 loader.
5. If necessary, prototype a minimal MicroBlaze V loader in a complete core.
6. Prove the same loader contract with at least two substantially different
   complete cores.
7. Consider a static-shell/partial-reconfiguration experiment only after the
   bundle and loader interfaces have proven stable.

## Related designs

MiSTer arcade `.mra` files similarly act as manifests: they identify an FPGA
core and ROM sources, describe how ROM regions are assembled, and pass those
regions to the configured core through a common loader interface. MiSTer keeps
its supervisor in a hard ARM processing system outside the reconfigured FPGA
fabric, which is the important architectural difference from an FPGA soft CPU.

- [MiSTer arcade ROM and MRA documentation](https://github.com/MiSTer-devel/Main_MiSTer/wiki/Arcade-Roms/62031c1feb011d443bd52b5e8aee8f7a64b2c6c2)
- [MiSTer `hps_io` data-transfer interface](https://mister-devel.github.io/MkDocs_MiSTer/developer/hps_io/)
- [AMD MicroBlaze V overview](https://www.amd.com/en/products/software/adaptive-socs-and-fpgas/microblaze-v.html)
- [AMD Dynamic Function eXchange guide](https://docs.amd.com/api/khub/documents/aKelve5HpAzsEgiAsRfyQA/content)
