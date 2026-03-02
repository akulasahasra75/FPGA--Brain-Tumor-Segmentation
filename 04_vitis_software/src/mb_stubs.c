/*
 * mb_stubs.c — Minimal stubs for MicroBlaze standalone (no BSP).
 *
 * Provides exception handlers and init/clean hooks required by CRT0.
 * These are normally supplied by the Xilinx BSP (libxil), but since our
 * application has zero BSP dependencies, we provide trivial stubs.
 */
#include <stdint.h>

/* Exception / interrupt vector stubs — loop forever on unexpected exceptions */
void _exception_handler(void)    { for (;;); }
void _interrupt_handler(void)    { for (;;); }
void _hw_exception_handler(void) { for (;;); }

/* Program init / clean — nothing to do for bare-metal */
void _program_init(void)  { }
void _program_clean(void) { }
