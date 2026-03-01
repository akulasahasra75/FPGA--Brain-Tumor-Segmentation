/******************************************************************************
 * energy_analyzer.h
 * ------------------
 * Power and energy estimation for the FPGA accelerator vs software baseline.
 *
 * Provides functions to measure execution time and estimate energy savings,
 * used to demonstrate the "99% energy savings" metric in the PRD.
 *****************************************************************************/
#ifndef ENERGY_ANALYZER_H
#define ENERGY_ANALYZER_H

#include <stdint.h>
#include "platform_config.h"

/**
 * Power profile for a processing run.
 */
typedef struct
{
    uint32_t hw_cycles;       /* cycles spent in HLS accelerator       */
    uint32_t sw_cycles;       /* cycles for equivalent SW processing   */
    uint32_t total_cycles;    /* total wall-clock cycles               */
    float hw_time_ms;         /* HLS execution time in ms              */
    float sw_time_ms;         /* software-only time in ms              */
    float speedup;            /* sw_time / hw_time                     */
    float hw_power_mw;        /* estimated FPGA dynamic power (mW)    */
    float sw_power_mw;        /* estimated SW-only power (mW)         */
    float hw_energy_uj;       /* FPGA energy (µJ)                      */
    float sw_energy_uj;       /* SW-only energy (µJ)                   */
    float energy_savings_pct; /* (1 - hw_energy/sw_energy) × 100      */
} EnergyReport;

/**
 * Start the hardware timer. Call before HLS invocation.
 */
void energy_timer_start(void);

/**
 * Stop the hardware timer. Call after HLS completes.
 *
 * @return  Elapsed cycles since energy_timer_start()
 */
uint32_t energy_timer_stop(void);

/**
 * Run the software-only baseline (Otsu on MicroBlaze) and measure time.
 *
 * @param img       Input image
 * @param mask_out  Output mask buffer
 * @return          Elapsed cycles for software processing
 */
uint32_t energy_sw_baseline(const uint8_t *img, uint8_t *mask_out);

/**
 * Compute a full energy report comparing HW vs SW.
 *
 * @param hw_cycles  Cycles measured for HLS acceleration
 * @param sw_cycles  Cycles measured for SW-only processing
 * @param report     Output report
 */
void energy_compute_report(uint32_t hw_cycles, uint32_t sw_cycles,
                           EnergyReport *report);

/**
 * Print the energy report via UART.
 *
 * @param report  Completed energy report
 */
void energy_print_report(const EnergyReport *report);

#endif /* ENERGY_ANALYZER_H */
