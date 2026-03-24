/******************************************************************************
 * adaptive_controller.c
 * ----------------------
 * Software-side adaptive mode selection for the HLS accelerator.
 *****************************************************************************/
#include "adaptive_controller.h"
#include "uart_debug.h"

/* ------------------------------------------------------------------ */
void adaptive_compute_stats(const uint8_t *img, SwImageStats *stats)
{
    uint32_t sum = 0;
    uint8_t  min_v = 255, max_v = 0;

    /* Pass 1: mean, min, max */
    for (uint32_t i = 0; i < IMG_SIZE; i++) {
        uint8_t p = img[i];
        sum += p;
        if (p < min_v) min_v = p;
        if (p > max_v) max_v = p;
    }

    uint8_t mean = (uint8_t)(sum / IMG_SIZE);

    /* Pass 2: standard deviation (integer approximation) */
    uint64_t var_sum = 0;
    for (uint32_t i = 0; i < IMG_SIZE; i++) {
        int16_t diff = (int16_t)img[i] - (int16_t)mean;
        var_sum += (uint32_t)(diff * diff);
    }
    uint32_t variance = (uint32_t)(var_sum / IMG_SIZE);

    /* Integer square root (Newton's method) */
    uint32_t s = variance;
    if (s > 0) {
        for (int iter = 0; iter < 16; iter++) {
            uint32_t next = (s + variance / s) / 2;
            if (next >= s) break;
            s = next;
        }
    }

    stats->mean     = mean;
    stats->std_dev  = (uint8_t)(s > 255 ? 255 : s);
    stats->contrast = max_v - min_v;
    stats->min_val  = min_v;
    stats->max_val  = max_v;
}

/* ------------------------------------------------------------------ */
uint8_t adaptive_select_mode(const SwImageStats *stats)
{
    if (stats->contrast >= 150 && stats->std_dev >= 50)
        return PROCESSING_MODE_FAST;
    if (stats->contrast >= 80 && stats->std_dev >= 25)
        return PROCESSING_MODE_NORMAL;
    return PROCESSING_MODE_CAREFUL;
}

/* ------------------------------------------------------------------ */
void adaptive_print_decision(const SwImageStats *stats, uint8_t mode)
{
    uart_print("\r\n--- Adaptive Mode Selection ---\r\n");
    uart_print_uint("  Mean:     ", stats->mean);
    uart_print_uint("  Std Dev:  ", stats->std_dev);
    uart_print_uint("  Contrast: ", stats->contrast);
    uart_print_uint("  Min:      ", stats->min_val);
    uart_print_uint("  Max:      ", stats->max_val);

    uart_print("  Selected: ");
    switch (mode) {
        case PROCESSING_MODE_FAST:    uart_print("FAST\r\n");    break;
        case PROCESSING_MODE_NORMAL:  uart_print("NORMAL\r\n");  break;
        case PROCESSING_MODE_CAREFUL: uart_print("CAREFUL\r\n"); break;
        default:                      uart_print("UNKNOWN\r\n"); break;
    }
    uart_print("-------------------------------\r\n");
}
