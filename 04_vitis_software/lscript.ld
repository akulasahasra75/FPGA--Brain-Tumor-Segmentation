/* ======================================================================
 * lscript.ld — MicroBlaze linker script for Brain Tumor Segmentation SoC
 *
 * Memory Map (from Vivado block design):
 *   LOCAL_BRAM : 0x00000000 – 0x0000FFFF  (64 KB) — code, data, stack
 *   IMAGE_BRAM : 0x80000000 – 0x8001FFFF  (128 KB) — image buffers (IO)
 *
 * The IMAGE_BRAM is accessed directly via volatile pointers in C code,
 * so it does not appear as a loadable section here.
 * ====================================================================== */

ENTRY(_start)

_TEXT_START_ADDR = 0x50;          /* after MicroBlaze vector table         */
_STACK_SIZE      = 0x2000;        /* 8 KB stack (grows downward)           */
_HEAP_SIZE       = 0x0;           /* no dynamic allocation                 */

MEMORY
{
    /* 64 KB local BRAM */
    LOCAL_BRAM (rwx) : ORIGIN = 0x00000000, LENGTH = 0x10000
}

SECTIONS
{
    /* -- MicroBlaze exception / reset vectors -- */
    .vectors.reset      0x00 : { KEEP(*(.vectors.reset))       } > LOCAL_BRAM = 0
    .vectors.sw_exception 0x08 : { KEEP(*(.vectors.sw_exception)) } > LOCAL_BRAM = 0
    .vectors.interrupt   0x10 : { KEEP(*(.vectors.interrupt))    } > LOCAL_BRAM = 0
    .vectors.debug_sw_break 0x18 : { KEEP(*(.vectors.debug_sw_break)) } > LOCAL_BRAM = 0
    .vectors.hw_exception 0x20 : { KEEP(*(.vectors.hw_exception)) } > LOCAL_BRAM = 0

    . = _TEXT_START_ADDR;
    _ftext = .;

    .text : {
        *(.text)
        *(.text.*)
        *(.gnu.linkonce.t.*)
    } > LOCAL_BRAM

    _etext = .;

    .init : { KEEP(*(.init)) } > LOCAL_BRAM = 0
    .fini : { KEEP(*(.fini)) } > LOCAL_BRAM = 0

    /* Constructors / destructors (C++) */
    .ctors : {
        KEEP(*crtbegin.o(.ctors))
        KEEP(*(EXCLUDE_FILE(*crtend.o) .ctors))
        KEEP(*(SORT(.ctors.*)))
        KEEP(*(.ctors))
    } > LOCAL_BRAM

    .dtors : {
        KEEP(*crtbegin.o(.dtors))
        KEEP(*(EXCLUDE_FILE(*crtend.o) .dtors))
        KEEP(*(SORT(.dtors.*)))
        KEEP(*(.dtors))
    } > LOCAL_BRAM

    . = ALIGN(4);
    _frodata = .;
    .rodata : {
        *(.rodata)
        *(.rodata.*)
        *(.gnu.linkonce.r.*)
    } > LOCAL_BRAM
    _erodata = .;

    /* Small read-write data (SDA2) */
    . = ALIGN(8);
    _ssrw = .;
    .sdata2 : { *(.sdata2) *(.sdata2.*) *(.gnu.linkonce.s2.*) } > LOCAL_BRAM
    . = ALIGN(4);
    .sbss2 : {
        PROVIDE(__sbss2_start = .);
        *(.sbss2) *(.sbss2.*) *(.gnu.linkonce.sb2.*)
        PROVIDE(__sbss2_end = .);
    } > LOCAL_BRAM
    . = ALIGN(8);
    _essrw = .;
    _ssrw_size = _essrw - _ssrw;
    PROVIDE(_SDA2_BASE_ = _ssrw + (_ssrw_size / 2));

    /* Initialized data */
    . = ALIGN(4);
    _fdata = .;
    .data : {
        *(.data)
        *(.data.*)
        *(.gnu.linkonce.d.*)
    } > LOCAL_BRAM
    _edata = .;

    .got   : { *(.got)  } > LOCAL_BRAM
    .got1  : { *(.got1) } > LOCAL_BRAM
    .got2  : { *(.got2) } > LOCAL_BRAM

    .eh_frame : { *(.eh_frame) } > LOCAL_BRAM
    .jcr      : { *(.jcr) } > LOCAL_BRAM
    .gcc_except_table : { *(.gcc_except_table) } > LOCAL_BRAM

    /* Small data (SDA) */
    . = ALIGN(8);
    _ssro = .;
    .sdata : { *(.sdata) *(.sdata.*) *(.gnu.linkonce.s.*) } > LOCAL_BRAM
    . = ALIGN(4);
    .sbss : {
        PROVIDE(__sbss_start = .);
        *(.sbss) *(.sbss.*) *(.gnu.linkonce.sb.*)
        PROVIDE(__sbss_end = .);
    } > LOCAL_BRAM
    . = ALIGN(8);
    _essro = .;
    _ssro_size = _essro - _ssro;
    PROVIDE(_SDA_BASE_ = _ssro + (_ssro_size / 2));

    /* Uninitialized data */
    . = ALIGN(4);
    _fbss = .;
    .bss : {
        PROVIDE(__bss_start = .);
        *(.bss) *(.bss.*) *(.gnu.linkonce.b.*) *(COMMON)
        . = ALIGN(4);
        PROVIDE(__bss_end = .);
    } > LOCAL_BRAM

    /* Heap (unused, but define symbols for completeness) */
    . = ALIGN(4);
    .heap : {
        _heap = .;
        _heap_start = .;
        . += _HEAP_SIZE;
        _heap_end = .;
    } > LOCAL_BRAM

    /* Stack at top of BRAM, grows downward */
    . = ALIGN(4);
    .stack : {
        _stack_end = .;
        . += _STACK_SIZE;
        . = ALIGN(8);
        _stack = .;
        __stack = .;
        _end = .;
    } > LOCAL_BRAM
}
