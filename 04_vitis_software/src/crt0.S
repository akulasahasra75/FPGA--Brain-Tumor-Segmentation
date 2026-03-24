/*
 * crt0.S — Minimal MicroBlaze CRT0 startup
 *
 * Sets up stack pointer, SDA bases, clears BSS, calls main.
 * Placed at the reset vector (address 0x0).
 */

    .section .vectors.reset, "ax"
    .global _start
    .align 2
_start:
    brai    _crt0_start

    .section .vectors.sw_exception, "ax"
    .align 2
    brai    _exception_handler

    .section .vectors.interrupt, "ax"
    .align 2
    brai    _interrupt_handler

    .section .vectors.hw_exception, "ax"
    .align 2
    brai    _hw_exception_handler

    .section .text
    .global _crt0_start
    .align 2
_crt0_start:
    /* Disable interrupts and exceptions */
    mfs     r1, rmsr
    andi    r1, r1, 0xFFD5      /* clear IE, EE, EIP bits */
    mts     rmsr, r1

    /* Set stack pointer (r1) — top of stack from linker script */
    addik   r1, r0, _stack

    /* Set SDA base (r13) */
    addik   r13, r0, _SDA_BASE_

    /* Set SDA2 base (r2) */
    addik   r2, r0, _SDA2_BASE_

    /* Clear BSS section */
    addik   r5, r0, __bss_start      /* r5 = BSS start */
    addik   r6, r0, __bss_end        /* r6 = BSS end   */

    rsub    r7, r5, r6               /* r7 = end - start */
    blei    r7, .Lbss_done           /* skip if empty */

.Lbss_loop:
    swi     r0, r5, 0               /* *r5 = 0 */
    addik   r5, r5, 4               /* r5 += 4 */
    rsub    r7, r5, r6
    bgti    r7, .Lbss_loop

.Lbss_done:
    /* Call main */
    brlid   r15, main
    nop                              /* branch delay slot */

    /* If main returns, loop forever */
.Lhang:
    bri     .Lhang
