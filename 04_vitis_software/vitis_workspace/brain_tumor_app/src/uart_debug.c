/******************************************************************************
 * uart_debug.c
 * --------------
 * UART print functions using AXI UART Lite in polled mode.
 *****************************************************************************/
#include "uart_debug.h"
#include "platform_config.h"

/* ---- AXI UART Lite register offsets ---- */
#define UART_RX_FIFO    0x00   /* Receive data FIFO  (read-only)  */
#define UART_TX_FIFO    0x04   /* Transmit data FIFO (write-only) */
#define UART_STATUS     0x08   /* Status register    (read-only)  */
#define UART_CONTROL    0x0C   /* Control register   (write-only) */

/* Status register bits */
#define UART_SR_RX_VALID   (1 << 0)   /* Rx FIFO has data       */
#define UART_SR_RX_FULL    (1 << 1)   /* Rx FIFO full           */
#define UART_SR_TX_EMPTY   (1 << 2)   /* Tx FIFO empty          */
#define UART_SR_TX_FULL    (1 << 3)   /* Tx FIFO full           */
#define UART_SR_INTR       (1 << 4)   /* Interrupt active       */
#define UART_SR_OVERRUN    (1 << 5)   /* Rx overrun error       */
#define UART_SR_FRAME_ERR  (1 << 6)   /* Framing error          */
#define UART_SR_PARITY_ERR (1 << 7)   /* Parity error           */

/* Control register bits */
#define UART_CR_RST_TX     (1 << 0)   /* Reset TX FIFO          */
#define UART_CR_RST_RX     (1 << 1)   /* Reset RX FIFO          */
#define UART_CR_INTR_EN    (1 << 4)   /* Enable interrupt       */

#define UART_BASE  XPAR_AXI_UARTLITE_0_BASEADDR

/* ------------------------------------------------------------------ */
void uart_init(void)
{
    /* Reset both FIFOs */
    REG_WRITE(UART_BASE, UART_CONTROL, UART_CR_RST_TX | UART_CR_RST_RX);
}

/* ------------------------------------------------------------------ */
void uart_putc(char c)
{
    /* Wait until TX FIFO is not full */
    while (REG_READ(UART_BASE, UART_STATUS) & UART_SR_TX_FULL)
        ;
    REG_WRITE(UART_BASE, UART_TX_FIFO, (uint32_t)c);
}

/* ------------------------------------------------------------------ */
void uart_print(const char *str)
{
    while (*str) {
        uart_putc(*str++);
    }
}

/* ------------------------------------------------------------------ */
void uart_print_uint(const char *label, uint32_t val)
{
    uart_print(label);

    if (val == 0) {
        uart_putc('0');
    } else {
        /* Convert to decimal (max 10 digits for uint32) */
        char buf[11];
        int pos = 0;
        uint32_t v = val;
        while (v > 0) {
            buf[pos++] = '0' + (char)(v % 10);
            v /= 10;
        }
        /* Print in reverse */
        for (int i = pos - 1; i >= 0; i--) {
            uart_putc(buf[i]);
        }
    }
    uart_print("\r\n");
}

/* ------------------------------------------------------------------ */
void uart_print_hex(const char *label, uint32_t val)
{
    static const char hex_chars[] = "0123456789ABCDEF";

    uart_print(label);
    uart_print("0x");

    for (int i = 28; i >= 0; i -= 4) {
        uart_putc(hex_chars[(val >> i) & 0xF]);
    }
    uart_print("\r\n");
}

/* ------------------------------------------------------------------ */
void uart_print_separator(void)
{
    uart_print("----------------------------------------\r\n");
}
