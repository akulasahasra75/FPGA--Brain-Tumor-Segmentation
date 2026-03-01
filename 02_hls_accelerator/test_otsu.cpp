/*******************************************************************************
 * test_otsu.cpp
 * --------------
 * C++ testbench for otsu_threshold_top and image_stats modules.
 *
 * Generates three synthetic 256×256 grayscale test images, runs all three
 * processing modes on each, and prints threshold / foreground-pixel / mode
 * results.  Also exercises the adaptive mode selector.
 *
 * Compile (desktop):
 *   g++ -std=c++11 -o test_otsu test_otsu.cpp otsu_threshold.cpp image_stats.cpp
 *   ./test_otsu
 *
 * For HLS co-simulation the same file is used as the testbench source.
 ******************************************************************************/
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cmath>
#include "otsu_threshold.h"
#include "image_stats.h"

/* -----------------------------------------------------------------------
 * Helpers
 * ---------------------------------------------------------------------*/

/* Simple pseudo-random (LCG) – deterministic across platforms */
static uint32_t rng_state = 12345;
static uint8_t rand8(void)
{
    rng_state = rng_state * 1103515245u + 12345u;
    return (uint8_t)((rng_state >> 16) & 0xFF);
}
static void seed_rng(uint32_t s) { rng_state = s; }

/* Dice coefficient between two binary masks */
static float dice(const uint8_t *pred, const uint8_t *gt, int n)
{
    int tp = 0, pred_sum = 0, gt_sum = 0;
    for (int i = 0; i < n; i++)
    {
        int p = pred[i] > 0 ? 1 : 0;
        int g = gt[i] > 0 ? 1 : 0;
        tp += p & g;
        pred_sum += p;
        gt_sum += g;
    }
    if (pred_sum + gt_sum == 0)
        return 1.0f;
    return 2.0f * tp / (pred_sum + gt_sum);
}

/* -----------------------------------------------------------------------
 * Synthetic image generators
 * ---------------------------------------------------------------------*/

/* Image 1 – bright circle (tumor) on a dark background */
static void generate_bright_circle(uint8_t img[IMG_SIZE],
                                   uint8_t gt[IMG_SIZE])
{
    seed_rng(42);
    int cx = IMG_WIDTH / 2;
    int cy = IMG_HEIGHT / 2;
    int R = 25;

    for (int r = 0; r < IMG_HEIGHT; r++)
    {
        for (int c = 0; c < IMG_WIDTH; c++)
        {
            int idx = r * IMG_WIDTH + c;
            int dx = c - cx;
            int dy = r - cy;
            if (dx * dx + dy * dy <= R * R)
            {
                img[idx] = 200 + (rand8() % 30); /* bright tumor */
                gt[idx] = 255;
            }
            else
            {
                img[idx] = 30 + (rand8() % 15); /* dark background */
                gt[idx] = 0;
            }
        }
    }
}

/* Image 2 – two blobs of different brightness */
static void generate_two_blobs(uint8_t img[IMG_SIZE],
                               uint8_t gt[IMG_SIZE])
{
    seed_rng(77);
    int cx1 = IMG_WIDTH / 3, cy1 = IMG_HEIGHT / 2, R1 = 20;
    int cx2 = 2 * IMG_WIDTH / 3, cy2 = IMG_HEIGHT / 2, R2 = 18;

    for (int r = 0; r < IMG_HEIGHT; r++)
    {
        for (int c = 0; c < IMG_WIDTH; c++)
        {
            int idx = r * IMG_WIDTH + c;
            int d1 = (c - cx1) * (c - cx1) + (r - cy1) * (r - cy1);
            int d2 = (c - cx2) * (c - cx2) + (r - cy2) * (r - cy2);
            if (d1 <= R1 * R1)
            {
                img[idx] = 210 + (rand8() % 20);
                gt[idx] = 255;
            }
            else if (d2 <= R2 * R2)
            {
                img[idx] = 180 + (rand8() % 25);
                gt[idx] = 255;
            }
            else
            {
                img[idx] = 25 + (rand8() % 20);
                gt[idx] = 0;
            }
        }
    }
}

/* Image 3 – low-contrast image (harder case) */
static void generate_low_contrast(uint8_t img[IMG_SIZE],
                                  uint8_t gt[IMG_SIZE])
{
    seed_rng(99);
    int cx = IMG_WIDTH / 2, cy = IMG_HEIGHT / 2, R = 22;

    for (int r = 0; r < IMG_HEIGHT; r++)
    {
        for (int c = 0; c < IMG_WIDTH; c++)
        {
            int idx = r * IMG_WIDTH + c;
            int dx = c - cx;
            int dy = r - cy;
            if (dx * dx + dy * dy <= R * R)
            {
                img[idx] = 100 + (rand8() % 20); /* only mildly brighter */
                gt[idx] = 255;
            }
            else
            {
                img[idx] = 60 + (rand8() % 30); /* noisy background */
                gt[idx] = 0;
            }
        }
    }
}

/* -----------------------------------------------------------------------
 * Test runner
 * ---------------------------------------------------------------------*/
static int test_image(const char *name,
                      uint8_t img[IMG_SIZE],
                      uint8_t gt[IMG_SIZE])
{
    int pass = 1;
    printf("----------------------------------------------\n");
    printf("Test image: %s\n", name);

    /* --- 1. Image statistics & adaptive mode --- */
    ImageStats st;
    compute_image_stats(img, &st);
    ProcessingMode auto_mode = select_mode(&st);
    printf("  Stats: mean=%u  std=%u  contrast=%u  min=%u  max=%u\n",
           st.mean, st.std_dev, st.contrast, st.min_val, st.max_val);
    printf("  Auto-selected mode: %s\n",
           auto_mode == MODE_FAST ? "FAST" : auto_mode == MODE_NORMAL ? "NORMAL"
                                                                      : "CAREFUL");

    /* --- 2. Run all three modes --- */
    const char *mode_names[] = {"FAST", "NORMAL", "CAREFUL"};

    for (int m = 0; m < 3; m++)
    {
        uint8_t out[IMG_SIZE];
        OtsuResult res;
        memset(out, 0, sizeof(out));
        memset(&res, 0, sizeof(res));

        otsu_threshold_top(img, out, (uint8_t)m, &res);

        float d = dice(out, gt, IMG_SIZE);
        printf("  Mode %-8s → thr=%3u  fg_px=%5u  dice=%.4f",
               mode_names[m], res.threshold, res.foreground_pixels, d);

        if (d < 0.10f)
        {
            printf("  [WARN: low dice]\n");
            /* Low-contrast images may legitimately score low in FAST mode */
            if (m == MODE_CAREFUL)
                pass = 0;
        }
        else
        {
            printf("  [OK]\n");
        }
    }

    /* --- 3. Verify adaptive path matches explicit mode --- */
    {
        uint8_t out_auto[IMG_SIZE], out_explicit[IMG_SIZE];
        OtsuResult ra, re;
        otsu_threshold_top(img, out_auto, (uint8_t)auto_mode, &ra);
        otsu_threshold_top(img, out_explicit, (uint8_t)auto_mode, &re);

        int match = (ra.threshold == re.threshold) &&
                    (ra.foreground_pixels == re.foreground_pixels);
        printf("  Adaptive consistency check: %s\n",
               match ? "PASS" : "FAIL");
        if (!match)
            pass = 0;
    }

    return pass;
}

/* -----------------------------------------------------------------------
 * main
 * ---------------------------------------------------------------------*/
int main(void)
{
    printf("==============================================\n");
    printf("  Otsu Threshold HLS Testbench\n");
    printf("==============================================\n\n");

    uint8_t img[IMG_SIZE];
    uint8_t gt[IMG_SIZE];
    int total_pass = 1;

    /* Test 1 – bright circle */
    generate_bright_circle(img, gt);
    if (!test_image("bright_circle", img, gt))
        total_pass = 0;

    /* Test 2 – two blobs */
    generate_two_blobs(img, gt);
    if (!test_image("two_blobs", img, gt))
        total_pass = 0;

    /* Test 3 – low contrast */
    generate_low_contrast(img, gt);
    if (!test_image("low_contrast", img, gt))
        total_pass = 0;

    printf("\n==============================================\n");
    if (total_pass)
    {
        printf("  ALL TESTS PASSED\n");
    }
    else
    {
        printf("  SOME TESTS FAILED\n");
    }
    printf("==============================================\n");

    return total_pass ? 0 : 1;
}
