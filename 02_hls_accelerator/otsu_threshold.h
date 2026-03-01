/*******************************************************************************
 * otsu_threshold.h
 * -----------------
 * HLS-synthesisable Otsu thresholding for brain-tumor segmentation.
 *
 * Three processing modes offer a quality-vs-speed trade-off:
 *   MODE_FAST     – single-pass histogram, minimal post-processing
 *   MODE_NORMAL   – standard Otsu + light morphological cleanup
 *   MODE_CAREFUL  – Otsu with adaptive fall-back threshold + full cleanup
 *
 * Target image: 256x256 8-bit grayscale.
 ******************************************************************************/
#ifndef OTSU_THRESHOLD_H
#define OTSU_THRESHOLD_H

#include <stdint.h>

/*--------------------------------------------------------------------------
 * Image dimensions (fixed for HLS resource estimation)
 *------------------------------------------------------------------------*/
#define IMG_WIDTH 256
#define IMG_HEIGHT 256
#define IMG_SIZE (IMG_WIDTH * IMG_HEIGHT) /* 65536 */
#define NUM_BINS 256                      /* 8-bit histogram */

/*--------------------------------------------------------------------------
 * Processing modes
 *------------------------------------------------------------------------*/
typedef enum
{
    MODE_FAST = 0,   /* speed-optimised, less accuracy     */
    MODE_NORMAL = 1, /* balanced                           */
    MODE_CAREFUL = 2 /* accuracy-optimised, slower          */
} ProcessingMode;

/*--------------------------------------------------------------------------
 * Result structure returned by the accelerator
 *------------------------------------------------------------------------*/
typedef struct
{
    uint8_t threshold;          /* computed Otsu threshold           */
    uint32_t foreground_pixels; /* # pixels above threshold          */
    uint8_t mode_used;          /* actual mode that was executed      */
} OtsuResult;

/*--------------------------------------------------------------------------
 * Top-level HLS function  (AXI-Lite control, BRAM / AXI-Stream data)
 *   img_in    – input  grayscale image  (flattened row-major)
 *   img_out   – output binary mask      (flattened row-major, 0 or 255)
 *   mode      – processing mode selector
 *   result    – output result metadata
 *------------------------------------------------------------------------*/
void otsu_threshold_top(
    const uint8_t img_in[IMG_SIZE],
    uint8_t img_out[IMG_SIZE],
    uint8_t mode,
    OtsuResult *result);

/*--------------------------------------------------------------------------
 * Internal helpers (exposed for unit-testing)
 *------------------------------------------------------------------------*/

/* Build 256-bin histogram of img_in */
void compute_histogram(const uint8_t img_in[IMG_SIZE],
                       uint32_t hist[NUM_BINS]);

/* Classical Otsu: find threshold that maximises inter-class variance */
uint8_t otsu_compute(const uint32_t hist[NUM_BINS]);

/* Apply threshold to image and write binary mask */
void apply_threshold(const uint8_t img_in[IMG_SIZE],
                     uint8_t img_out[IMG_SIZE],
                     uint8_t thr);

/* 3x3 morphological open (erosion then dilation) on binary mask */
void morph_open_3x3(uint8_t img[IMG_SIZE]);

/* 3x3 morphological close (dilation then erosion) on binary mask */
void morph_close_3x3(uint8_t img[IMG_SIZE]);

#endif /* OTSU_THRESHOLD_H */
