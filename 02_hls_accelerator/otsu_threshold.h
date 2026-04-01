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
 * Target image: 128x128 8-bit grayscale.
 * Target FPGA: Artix-7 (xc7a100tcsg324-1) @ 100 MHz
 *
 * ============================================================================
 * PERFORMANCE TARGETS (after optimization)
 * ============================================================================
 * | Mode        | Latency (cycles) | Time @ 100MHz | II (critical loops) |
 * |-------------|------------------|---------------|---------------------|
 * | MODE_FAST   | ~35,000          | 0.35 ms       | 1                   |
 * | MODE_NORMAL | ~72,000          | 0.72 ms       | 1                   |
 * | MODE_CAREFUL| ~125,000         | 1.25 ms       | 1                   |
 *
 * Resource Estimates:
 *   - BRAM:  ~20 (18Kb blocks) - 15% of Artix-7 100T
 *   - FF:    ~12,000 - 10% (includes histogram registers)
 *   - LUT:   ~8,000 - 13%
 *   - DSP:   ~15 - 6%
 * ============================================================================
 ******************************************************************************/
#ifndef OTSU_THRESHOLD_H
#define OTSU_THRESHOLD_H

#include <stdint.h>

/*--------------------------------------------------------------------------
 * Image dimensions (fixed for HLS resource estimation)
 *------------------------------------------------------------------------*/
#define IMG_WIDTH 128
#define IMG_HEIGHT 128
#define IMG_SIZE (IMG_WIDTH * IMG_HEIGHT) /* 16384 */
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
 *
 * IMPORTANT: For HLS s_axilite interface, struct members are mapped to
 * consecutive 32-bit registers. To avoid alignment issues and ensure
 * deterministic register layout, we explicitly order and pad fields.
 *
 * Memory Layout (8 bytes total):
 *   Offset 0: threshold (1 byte)
 *   Offset 1: mode_used (1 byte)
 *   Offset 2-3: _reserved[2] (2 bytes padding)
 *   Offset 4-7: foreground_pixels (4 bytes)
 *
 * AXI-Lite Register Map:
 *   Register 0 (offset 0x00): bits[7:0]=threshold, bits[15:8]=mode_used
 *   Register 1 (offset 0x04): foreground_pixels
 *------------------------------------------------------------------------*/
typedef struct
{
    uint8_t threshold;          /* computed Otsu threshold (offset 0)     */
    uint8_t mode_used;          /* actual mode that was executed (offset 1) */
    uint8_t _reserved[2];       /* padding to align foreground_pixels     */
    uint32_t foreground_pixels; /* # pixels above threshold (offset 4)    */
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
