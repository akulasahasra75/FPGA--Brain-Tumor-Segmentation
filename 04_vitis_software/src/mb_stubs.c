/*
 * mb_stubs.c — Minimal stubs for MicroBlaze standalone (no BSP).
 *
 * Provides exception handlers and init/clean hooks required by CRT0.
 * These are normally supplied by the Xilinx BSP (libxil), but since our
 * application has zero BSP dependencies, we provide trivial stubs.
 */
#include <stdint.h>
#include <stddef.h>  /* for size_t */

/* Exception / interrupt vector stubs — loop forever on unexpected exceptions */
void _exception_handler(void)    { for (;;); }
void _interrupt_handler(void)    { for (;;); }
void _hw_exception_handler(void) { for (;;); }

/* Program init / clean — nothing to do for bare-metal */
void _program_init(void)  { }
void _program_clean(void) { }

/* libc stubs — compiler may emit calls to these
 * Use weak attribute to allow standard library override if linked */
__attribute__((weak)) void *memset(void *s, int c, size_t n) {
    unsigned char *p = (unsigned char *)s;
    while (n--) *p++ = (unsigned char)c;
    return s;
}

__attribute__((weak)) void *memcpy(void *dest, const void *src, size_t n) {
    unsigned char *d = (unsigned char *)dest;
    const unsigned char *s2 = (const unsigned char *)src;
    while (n--) *d++ = *s2++;
    return dest;
}

__attribute__((weak)) int memcmp(const void *s1, const void *s2, size_t n) {
    const unsigned char *p1 = (const unsigned char *)s1;
    const unsigned char *p2 = (const unsigned char *)s2;
    while (n--) {
        if (*p1 != *p2) return (*p1 < *p2) ? -1 : 1;
        p1++; p2++;
    }
    return 0;
}
