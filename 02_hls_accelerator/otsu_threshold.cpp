/*******************************************************************************
 * otsu_threshold.cpp
 * -------------------
 * HLS implementation of Otsu thresholding with three processing modes.
 *
 * Pipeline overview
 * -----------------
 *   1. compute_histogram()  – build a 256-bin histogram
 *   2. otsu_compute()       – find optimal threshold (maximise σ²_B)
 *   3. apply_threshold()    – binarise the image
 *   4. morph_open / close   – optional morphological cleanup
 *
 * Modes
 * -----
 *   MODE_FAST     – Otsu + threshold only (no morphology)
 *   MODE_NORMAL   – Otsu + threshold + 1× open
 *   MODE_CAREFUL  – Otsu with adaptive fall-back + 1× open + 1× close
 ******************************************************************************/
#include "otsu_threshold.h"
#include <string.h> /* memset, memcpy */

/* ======================================================================
 * 1. Histogram
 * ====================================================================*/
void compute_histogram(const uint8_t img_in[IMG_SIZE],
                       uint32_t hist[NUM_BINS])
{
#pragma HLS INLINE off
/* Zero histogram */
HIST_ZERO:
    for (int i = 0; i < NUM_BINS; i++)
    {
#pragma HLS PIPELINE II = 1
        hist[i] = 0;
    }

/* Accumulate */
HIST_ACC:
    for (int i = 0; i < IMG_SIZE; i++)
    {
#pragma HLS PIPELINE II = 1
        hist[img_in[i]]++;
    }
}

/* ======================================================================
 * 2. Otsu threshold computation
 *    Maximise inter-class variance:
 *      σ²_B(t) = w0(t) · w1(t) · [μ0(t) − μ1(t)]²
 * ====================================================================*/
uint8_t otsu_compute(const uint32_t hist[NUM_BINS])
{
#pragma HLS INLINE off
    /* Total pixel count and cumulative mean */
    uint32_t total = IMG_SIZE;
    uint64_t sum_total = 0;

SUM_TOTAL:
    for (int i = 0; i < NUM_BINS; i++)
    {
#pragma HLS PIPELINE II = 1
        sum_total += (uint64_t)i * hist[i];
    }

    uint64_t sum_bg = 0;    /* cumulative intensity sum of background */
    uint32_t weight_bg = 0; /* cumulative pixel count of background   */
    uint64_t max_var = 0;   /* best inter-class variance (scaled)     */
    uint8_t best_thr = 0;

OTSU_SWEEP:
    for (int t = 0; t < NUM_BINS; t++)
    {
#pragma HLS PIPELINE II = 1
        weight_bg += hist[t];
        if (weight_bg == 0)
            continue;

        uint32_t weight_fg = total - weight_bg;
        if (weight_fg == 0)
            break;

        sum_bg += (uint64_t)t * hist[t];
        uint64_t sum_fg = sum_total - sum_bg;

        /*
         * σ²_B = w0 · w1 · (μ0 − μ1)²
         * To avoid 64-bit overflow in diff², compute class means via
         * integer division first, then form the product.
         *   mean_bg  = sum_bg / weight_bg   (0..255)
         *   mean_fg  = sum_fg / weight_fg   (0..255)
         *   var_between = w0 * w1 * (mean_bg - mean_fg)²
         * Max value: 65536² × 255² ≈ 2.8×10¹⁴  → fits uint64_t.
         */
        uint32_t mean_bg = (uint32_t)(sum_bg / weight_bg);
        uint32_t mean_fg = (uint32_t)(sum_fg / weight_fg);
        int32_t mean_diff = (int32_t)mean_bg - (int32_t)mean_fg;
        uint64_t var_between = (uint64_t)weight_bg * weight_fg *
                               (uint32_t)(mean_diff * mean_diff);

        if (var_between > max_var)
        {
            max_var = var_between;
            best_thr = (uint8_t)t;
        }
    }

    return best_thr;
}

/* ======================================================================
 * 3. Apply threshold – produce binary mask (0 / 255)
 * ====================================================================*/
void apply_threshold(const uint8_t img_in[IMG_SIZE],
                     uint8_t img_out[IMG_SIZE],
                     uint8_t thr)
{
#pragma HLS INLINE off
APPLY_THR:
    for (int i = 0; i < IMG_SIZE; i++)
    {
#pragma HLS PIPELINE II = 1
        img_out[i] = (img_in[i] > thr) ? 255 : 0;
    }
}

/* ======================================================================
 * 4. 3×3 morphological operations (on binary mask in-place)
 *    Using a line-buffer approach for HLS efficiency.
 * ====================================================================*/

/* --- helpers: min / max of two uint8_t --- */
static inline uint8_t u8_min(uint8_t a, uint8_t b) { return (a < b) ? a : b; }
static inline uint8_t u8_max(uint8_t a, uint8_t b) { return (a > b) ? a : b; }

/*
 * erode_3x3  – minimum filter (3×3 neighbourhood)
 * Out-of-bounds pixels are treated as 255 (foreground) so borders
 * are only eroded by actual image content.
 */
static void erode_3x3(const uint8_t src[IMG_SIZE],
                      uint8_t dst[IMG_SIZE])
{
#pragma HLS INLINE off
ERODE_ROW:
    for (int r = 0; r < IMG_HEIGHT; r++)
    {
    ERODE_COL:
        for (int c = 0; c < IMG_WIDTH; c++)
        {
#pragma HLS PIPELINE II = 1
            uint8_t val = 255;
            for (int dr = -1; dr <= 1; dr++)
            {
                for (int dc = -1; dc <= 1; dc++)
                {
                    int rr = r + dr;
                    int cc = c + dc;
                    if (rr >= 0 && rr < IMG_HEIGHT && cc >= 0 && cc < IMG_WIDTH)
                    {
                        val = u8_min(val, src[rr * IMG_WIDTH + cc]);
                    }
                }
            }
            dst[r * IMG_WIDTH + c] = val;
        }
    }
}

/*
 * dilate_3x3 – maximum filter (3×3 neighbourhood)
 * Out-of-bounds pixels are treated as 0 (background).
 */
static void dilate_3x3(const uint8_t src[IMG_SIZE],
                       uint8_t dst[IMG_SIZE])
{
#pragma HLS INLINE off
DILATE_ROW:
    for (int r = 0; r < IMG_HEIGHT; r++)
    {
    DILATE_COL:
        for (int c = 0; c < IMG_WIDTH; c++)
        {
#pragma HLS PIPELINE II = 1
            uint8_t val = 0;
            for (int dr = -1; dr <= 1; dr++)
            {
                for (int dc = -1; dc <= 1; dc++)
                {
                    int rr = r + dr;
                    int cc = c + dc;
                    if (rr >= 0 && rr < IMG_HEIGHT && cc >= 0 && cc < IMG_WIDTH)
                    {
                        val = u8_max(val, src[rr * IMG_WIDTH + cc]);
                    }
                }
            }
            dst[r * IMG_WIDTH + c] = val;
        }
    }
}

/* --- Public morphological wrappers (in-place via temp buffer) --- */
void morph_open_3x3(uint8_t img[IMG_SIZE])
{
    uint8_t tmp[IMG_SIZE];
#pragma HLS BIND_STORAGE variable = tmp type = ram_2p impl = bram
    erode_3x3(img, tmp);
    dilate_3x3(tmp, img);
}

void morph_close_3x3(uint8_t img[IMG_SIZE])
{
    uint8_t tmp[IMG_SIZE];
#pragma HLS BIND_STORAGE variable = tmp type = ram_2p impl = bram
    dilate_3x3(img, tmp);
    erode_3x3(tmp, img);
}

/* ======================================================================
 * 5. Top-level accelerator function
 * ====================================================================*/
void otsu_threshold_top(
    const uint8_t img_in[IMG_SIZE],
    uint8_t img_out[IMG_SIZE],
    uint8_t mode,
    OtsuResult *result)
{
#pragma HLS INTERFACE m_axi port = img_in offset = slave bundle = gmem0 depth = IMG_SIZE
#pragma HLS INTERFACE m_axi port = img_out offset = slave bundle = gmem1 depth = IMG_SIZE
#pragma HLS INTERFACE s_axilite port = mode bundle = control
#pragma HLS INTERFACE s_axilite port = result bundle = control
#pragma HLS INTERFACE s_axilite port = return bundle = control

    /* Local buffers */
    uint8_t local_in[IMG_SIZE];
    uint8_t local_out[IMG_SIZE];
    uint32_t hist[NUM_BINS];
#pragma HLS BIND_STORAGE variable = local_in type = ram_2p impl = bram
#pragma HLS BIND_STORAGE variable = local_out type = ram_2p impl = bram

/* Burst-read input image */
READ_IN:
    for (int i = 0; i < IMG_SIZE; i++)
    {
#pragma HLS PIPELINE II = 1
        local_in[i] = img_in[i];
    }

    /* Step 1 – Histogram */
    compute_histogram(local_in, hist);

    /* Step 2 – Otsu threshold */
    uint8_t thr = otsu_compute(hist);

    /* Step 3 – Adaptive fall-back for MODE_CAREFUL */
    if (mode == MODE_CAREFUL)
    {
        /* Compute image mean and count foreground fraction */
        uint32_t fg_count = 0;
    COUNT_FG:
        for (int i = 0; i < IMG_SIZE; i++)
        {
#pragma HLS PIPELINE II = 1
            if (local_in[i] > thr)
                fg_count++;
        }
        /* If Otsu selects > 20 % of image, use stricter threshold */
        uint32_t frac_limit = IMG_SIZE / 5; /* 20 % */
        if (fg_count > frac_limit)
        {
            /* Compute mean intensity */
            uint64_t sum = 0;
        SUM_MEAN:
            for (int i = 0; i < IMG_SIZE; i++)
            {
#pragma HLS PIPELINE II = 1
                sum += local_in[i];
            }
            uint8_t img_mean = (uint8_t)(sum / IMG_SIZE);

            /* Compute stddev (integer approximation) */
            uint64_t var_sum = 0;
        SUM_VAR:
            for (int i = 0; i < IMG_SIZE; i++)
            {
#pragma HLS PIPELINE II = 1
                int16_t diff = (int16_t)local_in[i] - (int16_t)img_mean;
                var_sum += (uint32_t)(diff * diff);
            }
            /* Integer square root via Newton's method */
            uint32_t var_avg = (uint32_t)(var_sum / IMG_SIZE);
            uint32_t s = var_avg;
            if (s > 0)
            {
                for (int iter = 0; iter < 16; iter++)
                {
                    uint32_t s_new = (s + var_avg / s) / 2;
                    if (s_new >= s)
                        break;
                    s = s_new;
                }
            }
            /* s ≈ stddev */
            /* strict threshold = mean + 0.6 * std ≈ mean + (3*std)/5 */
            uint16_t strict_t = (uint16_t)img_mean + (uint16_t)((3 * s) / 5);
            if (strict_t > 255)
                strict_t = 255;
            if (strict_t < 1)
                strict_t = 1;
            thr = (uint8_t)strict_t;
        }
    }

    /* Step 4 – Apply threshold */
    apply_threshold(local_in, local_out, thr);

    /* Step 5 – Morphological post-processing (mode-dependent) */
    if (mode >= MODE_NORMAL)
    {
        morph_open_3x3(local_out); /* remove small noise */
    }
    if (mode == MODE_CAREFUL)
    {
        morph_close_3x3(local_out); /* fill small holes  */
    }

    /* Count foreground pixels */
    uint32_t fg = 0;
COUNT_FINAL:
    for (int i = 0; i < IMG_SIZE; i++)
    {
#pragma HLS PIPELINE II = 1
        fg += (local_out[i] > 0) ? 1 : 0;
    }

/* Burst-write output image */
WRITE_OUT:
    for (int i = 0; i < IMG_SIZE; i++)
    {
#pragma HLS PIPELINE II = 1
        img_out[i] = local_out[i];
    }

    /* Fill result struct */
    result->threshold = thr;
    result->foreground_pixels = fg;
    result->mode_used = mode;
}
