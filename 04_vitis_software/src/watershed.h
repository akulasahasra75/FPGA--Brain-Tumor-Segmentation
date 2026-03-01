/******************************************************************************
 * watershed.h
 * -------------
 * Software-side watershed-like post-processing for the binary mask produced
 * by the HLS Otsu accelerator.
 *
 * Implements connected-component labelling to identify distinct tumor regions
 * and compute region statistics (area, centroid, bounding box).
 *****************************************************************************/
#ifndef WATERSHED_H
#define WATERSHED_H

#include <stdint.h>
#include "platform_config.h"

/* Maximum number of distinct tumors we track */
#define MAX_REGIONS 16

/**
 * Descriptor for one connected component (tumor candidate).
 */
typedef struct
{
    uint32_t area;       /* number of foreground pixels               */
    uint16_t centroid_x; /* centre-of-mass X                          */
    uint16_t centroid_y; /* centre-of-mass Y                          */
    uint16_t bbox_x0;    /* bounding-box top-left X                   */
    uint16_t bbox_y0;    /* bounding-box top-left Y                   */
    uint16_t bbox_x1;    /* bounding-box bottom-right X               */
    uint16_t bbox_y1;    /* bounding-box bottom-right Y               */
    uint8_t label;       /* region label (1, 2, …)                    */
} RegionInfo;

/**
 * Result of watershed post-processing.
 */
typedef struct
{
    uint8_t num_regions;             /* how many regions found   */
    RegionInfo regions[MAX_REGIONS]; /* region descriptors       */
    uint32_t total_foreground;       /* total foreground pixels  */
    uint8_t label_map[IMG_SIZE];     /* per-pixel label map      */
} WatershedResult;

/**
 * Run connected-component labelling on a binary mask.
 *
 * The mask is expected to contain 0 (background) and 255 (foreground).
 * Uses a two-pass flood-fill approach (stack-free BFS with scanline trick)
 * suitable for the MicroBlaze memory footprint.
 *
 * @param mask       Input binary mask (IMG_SIZE bytes, 0 or 255)
 * @param result     Output: region list and label map
 */
void watershed_segment(const uint8_t *mask, WatershedResult *result);

/**
 * Print a human-readable summary of the watershed result via UART.
 *
 * @param result     Pointer to completed WatershedResult
 */
void watershed_print_summary(const WatershedResult *result);

#endif /* WATERSHED_H */
