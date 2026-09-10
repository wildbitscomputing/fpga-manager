/*
 * The updateable FPGA Manager always executes from the active application
 * slot.  The first 4 KiB of that slot is the package manifest, so the Pico SDK
 * payload begins at flash offset 0x11000.
 */
FLASH(rx) : ORIGIN = 0x10011000, LENGTH = 0x26F000
