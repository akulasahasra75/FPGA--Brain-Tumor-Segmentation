/******************************************************************************
 * uart_debug.h
 * --------------
 * Lightweight UART print functions for MicroBlaze.
 * Uses AXI UART Lite peripheral (polled mode, no interrupts).
 *****************************************************************************/
#ifndef UART_DEBUG_H
#define UART_DEBUG_H

#include <stdint.h>

/**
 * Initialise UART (sets baud rate, clears FIFOs).
 */
void uart_init(void);

/**
 * Send a single character (blocking, waits for TX FIFO space).
 */
void uart_putc(char c);

/**
 * Send a null-terminated string.
 */
void uart_print(const char *str);

/**
 * Print a label followed by an unsigned 32-bit integer in decimal.
 * E.g. uart_print_uint("Count: ", 42)  →  "Count: 42\r\n"
 */
void uart_print_uint(const char *label, uint32_t val);

/**
 * Print a label followed by a 32-bit value in hexadecimal.
 * E.g. uart_print_hex("Addr: ", 0xDEAD)  →  "Addr: 0x0000DEAD\r\n"
 */
void uart_print_hex(const char *label, uint32_t val);

/**
 * Print a horizontal separator line.
 */
void uart_print_separator(void);

#endif /* UART_DEBUG_H */
