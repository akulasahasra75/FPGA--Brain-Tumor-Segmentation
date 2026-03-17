/******************************************************************************
 * platform_config.h
 * ------------------
 * Hardware base addresses and system-wide constants for the Brain Tumor
 * Segmentation SoC running on Nexys A7-100T (Artix-7).
 *
 * These addresses must match the Vivado block design address map
 * (see 03_vivado_hardware/build.tcl, Step 5).
 *****************************************************************************/
#ifndef PLATFORM_CONFIG_H
#define PLATFORM_CONFIG_H

#include <stdint.h>

/* =====================================================================
 * Peripheral base addresses (from Vivado address map)
 * ===================================================================*/
#define XPAR_AXI_UARTLITE_0_BASEADDR 0x40600000U
#define XPAR_AXI_GPIO_0_BASEADDR 0x40000000U
#define XPAR_AXI_TIMER_0_BASEADDR 0x41C00000U

/* HLS Otsu IP has TWO AXI-Lite slave interfaces: */
#define XPAR_HLS_OTSU_0_BASEADDR   0x44A00000U  /* s_axi_control  */
#define XPAR_HLS_OTSU_0_R_BASEADDR 0x44A10000U  /* s_axi_control_r */

/* =====================================================================
 * HLS Otsu accelerator – s_axi_control register offsets
 * (mode, result, ap_ctrl – from xotsu_threshold_top_hw.h)
 * ===================================================================*/
#define HLS_OTSU_CONTROL          0x00  /* ap_ctrl: bit0=start, bit1=done, bit2=idle */
#define HLS_OTSU_GIE              0x04  /* global interrupt enable          */
#define HLS_OTSU_IER              0x08  /* interrupt enable register        */
#define HLS_OTSU_ISR              0x0C  /* interrupt status register        */
#define HLS_OTSU_MODE             0x10  /* mode (bits 7:0, R/W)             */
#define HLS_OTSU_RESULT_I_0       0x20  /* result input word 0 (R/W)        */
#define HLS_OTSU_RESULT_I_1       0x24  /* result input word 1 (R/W)        */
#define HLS_OTSU_RESULT_I_2       0x28  /* result input word 2 (R/W)        */
#define HLS_OTSU_RESULT_THRESH    0x30  /* result_o word 0: threshold (R/O) */
#define HLS_OTSU_RESULT_FG_PIX    0x34  /* result_o word 1: fg_pixels (R/O) */
#define HLS_OTSU_RESULT_MODE_USED 0x38  /* result_o word 2: mode_used (R/O) */
#define HLS_OTSU_RESULT_VLD       0x3C  /* result_o valid flag (R/COR)      */

/* =====================================================================
 * HLS Otsu accelerator – s_axi_control_r register offsets
 * (img_in / img_out pointers – from xotsu_threshold_top_hw.h)
 * ===================================================================*/
#define HLS_OTSU_IMG_IN_LO        0x10  /* img_in[31:0]  (R/W)  */
#define HLS_OTSU_IMG_IN_HI        0x14  /* img_in[63:32] (R/W)  */
#define HLS_OTSU_IMG_OUT_LO       0x1C  /* img_out[31:0] (R/W)  */
#define HLS_OTSU_IMG_OUT_HI       0x20  /* img_out[63:32] (R/W) */

/* =====================================================================
 * Image parameters
 * ===================================================================*/
#define IMG_WIDTH 128
#define IMG_HEIGHT 128
#define IMG_SIZE (IMG_WIDTH * IMG_HEIGHT) /* 16384 */
#define IMG_SIZE_BYTES IMG_SIZE           /* 8-bit grayscale  */

/* =====================================================================
 * System parameters
 * ===================================================================*/
#define SYS_CLK_FREQ_HZ 100000000U /* 100 MHz system clock       */
#define UART_BAUD_RATE 115200U     /* UART baud rate             */

/* =====================================================================
 * LED bit positions (active-high via AXI GPIO)
 * ===================================================================*/
#define LED_HEARTBEAT (1U << 0)
#define LED_PROCESSING (1U << 1)
#define LED_MODE_BIT0 (1U << 2)
#define LED_MODE_BIT1 (1U << 3)
#define LED_DONE (1U << 4)

/* =====================================================================
 * Memory map – image BRAM (128 KB at 0x80000000, AXI-accessible)
 *
 * Layout (total 112 KB used of 128 KB):
 *   +0x00000 (16 KB)  input image buffer
 *   +0x04000 (16 KB)  HLS output mask
 *   +0x08000 (16 KB)  SW baseline result
 *   +0x0C000 (32 KB)  watershed BFS queue  – uint16_t[16384]
 *   +0x14000 (16 KB)  watershed label map
 *   +0x18000 (16 KB)  CPU thumbnail build buffer
 * ===================================================================*/
#define IMG_INPUT_BASE       0x80000000U
#define IMG_OUTPUT_BASE      (IMG_INPUT_BASE       + IMG_SIZE)
#define SW_MASK_BASE         (IMG_OUTPUT_BASE      + IMG_SIZE)
#define WATERSHED_QUEUE_BASE (SW_MASK_BASE         + IMG_SIZE)
#define WATERSHED_LABEL_BASE (WATERSHED_QUEUE_BASE + (IMG_SIZE * 2U))
#define CPU_IMG_BUILD_BASE   (WATERSHED_LABEL_BASE + IMG_SIZE)

/* =====================================================================
 * Register access helpers
 * ===================================================================*/
#define REG_WRITE(base, offset, val) \
    (*(volatile uint32_t *)((base) + (offset)) = (val))

#define REG_READ(base, offset) \
    (*(volatile uint32_t *)((base) + (offset)))

#endif /* PLATFORM_CONFIG_H */
