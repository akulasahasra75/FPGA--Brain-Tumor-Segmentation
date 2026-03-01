/******************************************************************************
 * energy_analyzer.c
 * ------------------
 * Timer-based energy analysis and speedup measurement.
 *
 * Power estimates are based on:
 *   - Artix-7 typical dynamic power for image-processing designs (~50 mW)
 *   - MicroBlaze SW-only power estimate (~200 mW including BRAM + logic)
 *   - These are conservative estimates; actual values come from Vivado
 *     power analysis (post-implementation).
 *****************************************************************************/
#include "energy_analyzer.h"
#include "uart_debug.h"
#include <string.h>

/* ---- AXI Timer register offsets (Xilinx AXI Timer v2.0) ---- */
#define TCSR0   0x00   /* Timer Control/Status Register 0 */
#define TLR0    0x04   /* Timer Load Register 0           */
#define TCR0    0x08   /* Timer Counter Register 0        */

/* TCSR0 bits */
#define TCSR_MDT    (1 << 0)   /* Timer mode (0=generate, 1=capture) */
#define TCSR_UDT    (1 << 1)   /* Up/Down (0=up, 1=down)             */
#define TCSR_GENT   (1 << 2)   /* Generate out (not used)            */
#define TCSR_CAPT   (1 << 3)   /* Capture (not used)                 */
#define TCSR_ARHT   (1 << 4)   /* Auto-reload                        */
#define TCSR_LOAD   (1 << 5)   /* Load TLR into counter              */
#define TCSR_ENIT   (1 << 6)   /* Enable interrupt                   */
#define TCSR_ENT    (1 << 7)   /* Enable timer                       */
#define TCSR_T0INT  (1 << 8)   /* Timer interrupt occurred            */
#define TCSR_PWMA   (1 << 9)   /* PWM enable (not used)              */
#define TCSR_ENALL  (1 << 10)  /* Enable all timers                  */

/* ---- Power estimates (mW) ---- */
#define FPGA_HLS_POWER_MW     50.0f    /* HLS accelerator dynamic power  */
#define SW_ONLY_POWER_MW     200.0f    /* MicroBlaze SW-only power       */

/* ------------------------------------------------------------------ */
void energy_timer_start(void)
{
    /* Stop timer, load 0, start counting up */
    REG_WRITE(XPAR_AXI_TIMER_0_BASEADDR, TCSR0, 0);           /* stop        */
    REG_WRITE(XPAR_AXI_TIMER_0_BASEADDR, TLR0, 0);            /* load val=0  */
    REG_WRITE(XPAR_AXI_TIMER_0_BASEADDR, TCSR0, TCSR_LOAD);   /* load        */
    REG_WRITE(XPAR_AXI_TIMER_0_BASEADDR, TCSR0, TCSR_ENT);    /* start up    */
}

/* ------------------------------------------------------------------ */
uint32_t energy_timer_stop(void)
{
    uint32_t cycles = REG_READ(XPAR_AXI_TIMER_0_BASEADDR, TCR0);
    REG_WRITE(XPAR_AXI_TIMER_0_BASEADDR, TCSR0, 0);  /* stop timer */
    return cycles;
}

/* ------------------------------------------------------------------ */
/*
 * SW baseline: simple Otsu on MicroBlaze (no HLS).
 * This gives us the comparison point for speedup / energy metrics.
 */
uint32_t energy_sw_baseline(const uint8_t *img, uint8_t *mask_out)
{
    energy_timer_start();

    /* --- Histogram --- */
    uint32_t hist[256];
    memset(hist, 0, sizeof(hist));
    for (uint32_t i = 0; i < IMG_SIZE; i++) {
        hist[img[i]]++;
    }

    /* --- Otsu threshold (same algorithm as HLS) --- */
    uint32_t total = IMG_SIZE;
    uint32_t sum = 0;
    for (uint16_t t = 0; t < 256; t++) {
        sum += t * hist[t];
    }

    uint32_t sum_b = 0, w_b = 0;
    uint32_t best_var = 0;
    uint8_t  threshold = 0;

    for (uint16_t t = 0; t < 256; t++) {
        w_b += hist[t];
        if (w_b == 0) continue;
        uint32_t w_f = total - w_b;
        if (w_f == 0) break;

        sum_b += t * hist[t];
        uint32_t sum_f = sum - sum_b;

        /* Use integer math to avoid overflow:
         * between-class variance ∝ w_b * w_f * (mean_b - mean_f)^2
         * Compute means via integer division first */
        uint32_t mean_b = sum_b / w_b;
        uint32_t mean_f = sum_f / w_f;
        uint32_t diff = (mean_b > mean_f) ? (mean_b - mean_f) : (mean_f - mean_b);

        uint64_t var = (uint64_t)w_b * w_f * diff * diff;
        if (var > best_var) {
            best_var = (uint32_t)(var >> 16);  /* scale down to fit uint32 */
            threshold = (uint8_t)t;
            best_var = (uint32_t)(var > 0xFFFFFFFF ? 0xFFFFFFFF : var);
        }
    }

    /* --- Apply threshold --- */
    for (uint32_t i = 0; i < IMG_SIZE; i++) {
        mask_out[i] = (img[i] > threshold) ? 255 : 0;
    }

    return energy_timer_stop();
}

/* ------------------------------------------------------------------ */
void energy_compute_report(uint32_t hw_cycles, uint32_t sw_cycles,
                           EnergyReport *report)
{
    report->hw_cycles = hw_cycles;
    report->sw_cycles = sw_cycles;
    report->total_cycles = hw_cycles;  /* wall clock = HW time */

    float clk_period_ms = 1.0f / (SYS_CLK_FREQ_HZ / 1000.0f);  /* ms/cycle */

    report->hw_time_ms = hw_cycles * clk_period_ms;
    report->sw_time_ms = sw_cycles * clk_period_ms;

    report->speedup = (report->hw_time_ms > 0)
                      ? report->sw_time_ms / report->hw_time_ms
                      : 0.0f;

    report->hw_power_mw = FPGA_HLS_POWER_MW;
    report->sw_power_mw = SW_ONLY_POWER_MW;

    /* Energy = Power × Time  (mW × ms = µJ) */
    report->hw_energy_uj = report->hw_power_mw * report->hw_time_ms;
    report->sw_energy_uj = report->sw_power_mw * report->sw_time_ms;

    report->energy_savings_pct =
        (report->sw_energy_uj > 0)
        ? (1.0f - report->hw_energy_uj / report->sw_energy_uj) * 100.0f
        : 0.0f;
}

/* ------------------------------------------------------------------ */
void energy_print_report(const EnergyReport *report)
{
    uart_print("\r\n=== Energy & Performance Report ===\r\n");
    uart_print_uint("  HW cycles:      ", report->hw_cycles);
    uart_print_uint("  SW cycles:      ", report->sw_cycles);

    /* Print times as integer microseconds for simplicity */
    uint32_t hw_us = (uint32_t)(report->hw_time_ms * 1000);
    uint32_t sw_us = (uint32_t)(report->sw_time_ms * 1000);
    uart_print_uint("  HW time (us):   ", hw_us);
    uart_print_uint("  SW time (us):   ", sw_us);
    uart_print_uint("  Speedup (x10):  ", (uint32_t)(report->speedup * 10));

    uint32_t hw_uj = (uint32_t)(report->hw_energy_uj);
    uint32_t sw_uj = (uint32_t)(report->sw_energy_uj);
    uart_print_uint("  HW energy (uJ): ", hw_uj);
    uart_print_uint("  SW energy (uJ): ", sw_uj);
    uart_print_uint("  Savings (%):    ", (uint32_t)(report->energy_savings_pct));

    uart_print("===================================\r\n");
}
