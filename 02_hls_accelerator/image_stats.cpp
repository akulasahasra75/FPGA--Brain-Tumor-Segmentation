/*******************************************************************************
 * image_stats.cpp
 * ----------------
 * NOVELTY MODULE – Adaptive image-analysis and mode selection.
 *
 * All arithmetic is integer-only and fully HLS-synthesisable.
 ******************************************************************************/
#include "image_stats.h"

/* ======================================================================
 * compute_image_stats – single-pass mean / std / contrast
 * ====================================================================*/
void compute_image_stats(const uint8_t img[IMG_SIZE],
                         ImageStats *stats)
{
#pragma HLS INLINE off

    uint64_t sum = 0;
    uint64_t sum_sq = 0;
    uint8_t v_min = 255;
    uint8_t v_max = 0;

STATS_LOOP:
    for (int i = 0; i < IMG_SIZE; i++)
    {
#pragma HLS PIPELINE II = 1
        uint8_t px = img[i];
        sum += px;
        sum_sq += (uint32_t)px * px;
        if (px < v_min)
            v_min = px;
        if (px > v_max)
            v_max = px;
    }

    uint8_t mean = (uint8_t)(sum / IMG_SIZE);

    /* variance = E[x²] − (E[x])² */
    uint32_t mean_sq = (uint32_t)mean * mean;
    uint32_t e_x2 = (uint32_t)(sum_sq / IMG_SIZE);
    uint32_t variance = (e_x2 > mean_sq) ? (e_x2 - mean_sq) : 0;

    /* Integer square root via Newton's method (start high, converge down) */
    uint32_t s = 0;
    if (variance > 0)
    {
        s = variance; /* initial guess = variance itself (always >= sqrt) */
    SQRT_LOOP:
        for (int i = 0; i < 16; i++)
        {
#pragma HLS PIPELINE II = 1
            uint32_t s_new = (s + variance / s) / 2;
            if (s_new >= s)
                break; /* converged */
            s = s_new;
        }
    }
    if (s > 255)
        s = 255;

    stats->mean = mean;
    stats->std_dev = (uint8_t)s;
    stats->contrast = v_max - v_min;
    stats->min_val = v_min;
    stats->max_val = v_max;
}

/* ======================================================================
 * select_mode – rule-based adaptive mode selector
 *
 * Heuristics (tuneable thresholds):
 *   contrast >= 150  AND  std_dev >= 50   → MODE_FAST
 *   contrast >= 80   AND  std_dev >= 25   → MODE_NORMAL
 *   otherwise                              → MODE_CAREFUL
 * ====================================================================*/
ProcessingMode select_mode(const ImageStats *stats)
{
#pragma HLS INLINE

    if (stats->contrast >= 150 && stats->std_dev >= 50)
    {
        return MODE_FAST;
    }
    if (stats->contrast >= 80 && stats->std_dev >= 25)
    {
        return MODE_NORMAL;
    }
    return MODE_CAREFUL;
}
