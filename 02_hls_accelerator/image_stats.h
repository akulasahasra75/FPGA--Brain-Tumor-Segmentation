/*******************************************************************************
 * image_stats.h
 * --------------
 * NOVELTY MODULE – Adaptive processing-mode selection.
 *
 * Computes lightweight image statistics (mean, standard deviation, contrast)
 * and selects the optimal processing mode (FAST / NORMAL / CAREFUL) based on
 * image complexity.  This allows the FPGA to balance speed and accuracy at
 * runtime without user intervention.
 ******************************************************************************/
#ifndef IMAGE_STATS_H
#define IMAGE_STATS_H

#include <stdint.h>
#include "otsu_threshold.h" /* IMG_SIZE, ProcessingMode */

/*--------------------------------------------------------------------------
 * Statistics structure
 *------------------------------------------------------------------------*/
typedef struct
{
    uint8_t mean;     /* mean pixel intensity (0-255)                 */
    uint8_t std_dev;  /* standard deviation   (integer approx.)      */
    uint8_t contrast; /* (max - min) dynamic range                   */
    uint8_t min_val;  /* minimum pixel value                         */
    uint8_t max_val;  /* maximum pixel value                         */
} ImageStats;

/*--------------------------------------------------------------------------
 * Compute image statistics (HLS-synthesisable)
 *------------------------------------------------------------------------*/
void compute_image_stats(const uint8_t img[IMG_SIZE],
                         ImageStats *stats);

/*--------------------------------------------------------------------------
 * Select processing mode from statistics
 *   High contrast, clear separation  → MODE_FAST
 *   Medium contrast                  → MODE_NORMAL
 *   Low contrast / noisy             → MODE_CAREFUL
 *------------------------------------------------------------------------*/
ProcessingMode select_mode(const ImageStats *stats);

#endif /* IMAGE_STATS_H */
