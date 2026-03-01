/******************************************************************************
 * adaptive_controller.h
 * ----------------------
 * NOVELTY MODULE – Runtime adaptive processing-mode selection.
 *
 * Software-side companion to the HLS image_stats module.
 * Computes image statistics on the MicroBlaze and selects the optimal
 * processing mode before invoking the HLS accelerator.
 *****************************************************************************/
#ifndef ADAPTIVE_CONTROLLER_H
#define ADAPTIVE_CONTROLLER_H

#include <stdint.h>
#include "platform_config.h"

/* Processing modes (must match HLS ProcessingMode enum) */
#define PROCESSING_MODE_FAST 0
#define PROCESSING_MODE_NORMAL 1
#define PROCESSING_MODE_CAREFUL 2

/**
 * Image statistics computed on the software side.
 */
typedef struct
{
    uint8_t mean;
    uint8_t std_dev;
    uint8_t contrast; /* max - min */
    uint8_t min_val;
    uint8_t max_val;
} SwImageStats;

/**
 * Compute lightweight statistics for a grayscale image.
 *
 * @param img    Pointer to 256×256 8-bit grayscale image
 * @param stats  Output statistics
 */
void adaptive_compute_stats(const uint8_t *img, SwImageStats *stats);

/**
 * Select the optimal processing mode based on image statistics.
 * Uses the same thresholds as the HLS module for consistency:
 *   contrast >= 150 && std_dev >= 50 → FAST
 *   contrast >= 80  && std_dev >= 25 → NORMAL
 *   else                             → CAREFUL
 *
 * @param stats  Computed image statistics
 * @return       PROCESSING_MODE_FAST / NORMAL / CAREFUL
 */
uint8_t adaptive_select_mode(const SwImageStats *stats);

/**
 * Print mode-selection rationale to UART.
 *
 * @param stats  Image statistics
 * @param mode   Selected mode
 */
void adaptive_print_decision(const SwImageStats *stats, uint8_t mode);

#endif /* ADAPTIVE_CONTROLLER_H */
