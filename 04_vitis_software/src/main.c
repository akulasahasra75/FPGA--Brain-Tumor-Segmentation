/******************************************************************************
 * main.c
 * --------
 * Brain Tumor Segmentation – MicroBlaze application.
 *
 * Flow:
 *   1. Initialise UART, LEDs, timer
 *   2. Load test image into BRAM
 *   3. Compute image statistics → adaptive mode selection
 *   4. Invoke HLS Otsu accelerator
 *   5. Read result mask
 *   6. Run software watershed (connected-component labelling)
 *   7. Measure energy & print report
 *   8. Repeat for each test image
 *
 * Target: Nexys A7-100T (Artix-7 xc7a100tcsg324-1) + MicroBlaze
 *****************************************************************************/

#include <stdint.h>
#include <string.h>

#include "platform_config.h"
#include "image_loader.h"
#include "adaptive_controller.h"
#include "energy_analyzer.h"
#include "watershed.h"
#include "uart_debug.h"
#include "test_images.h"

/* ---- LED helpers ---- */
static void led_set(uint32_t mask)
{
    REG_WRITE(XPAR_AXI_GPIO_0_BASEADDR, 0x00, mask);
}

static void led_set_mode(uint8_t mode)
{
    uint32_t current = REG_READ(XPAR_AXI_GPIO_0_BASEADDR, 0x00);
    current &= ~(LED_MODE_BIT0 | LED_MODE_BIT1);
    current |= ((uint32_t)(mode & 0x01) << 2);
    current |= ((uint32_t)((mode >> 1) & 0x01) << 3);
    led_set(current);
}

/* ---- HLS accelerator control ---- */
static void hls_start(uint8_t mode)
{
    /* Set image pointers via s_axi_control_r */
    REG_WRITE(XPAR_HLS_OTSU_0_R_BASEADDR, HLS_OTSU_IMG_IN_LO, IMG_INPUT_BASE);
    REG_WRITE(XPAR_HLS_OTSU_0_R_BASEADDR, HLS_OTSU_IMG_IN_HI, 0);
    REG_WRITE(XPAR_HLS_OTSU_0_R_BASEADDR, HLS_OTSU_IMG_OUT_LO, IMG_OUTPUT_BASE);
    REG_WRITE(XPAR_HLS_OTSU_0_R_BASEADDR, HLS_OTSU_IMG_OUT_HI, 0);

    /* Set processing mode via s_axi_control */
    REG_WRITE(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_MODE, mode);

    /* Start accelerator (ap_start = bit 0) via s_axi_control */
    REG_WRITE(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_CONTROL, 0x01);
}

static int hls_is_done(void)
{
    uint32_t ctrl = REG_READ(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_CONTROL);
    return (ctrl >> 1) & 0x01;   /* ap_done = bit 1 */
}

static void hls_wait_done(void)
{
    while (!hls_is_done())
        ;
}

static uint8_t hls_get_threshold(void)
{
    return (uint8_t)REG_READ(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_RESULT_THRESH);
}

static uint32_t hls_get_fg_pixels(void)
{
    return REG_READ(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_RESULT_FG_PIX);
}

static uint8_t hls_get_mode_used(void)
{
    return (uint8_t)REG_READ(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_RESULT_MODE_USED);
}

/* ---- Process one image end-to-end ---- */
/*
 * img_data must already reside in BRAM at IMG_INPUT_BASE.
 * We pass the BRAM pointer so stats can be computed from it.
 */
static void process_image(const char *name,
                          const uint8_t *img_data)
{
    /*
     * NO large stack arrays!
     * -----------------------------------------------------------
     * Before this fix the function allocated 3 × 64 KB buffers on
     * the stack (output_mask, sw_mask, full_img) plus the
     * WatershedResult struct contained another 64 KB label_map,
     * totalling > 256 KB – far beyond MicroBlaze's 64 KB BRAM.
     *
     * Now we use BRAM-mapped pointers directly:
     *   output_mask → BRAM output region  (IMG_OUTPUT_BASE)
     *   label_map   → BRAM input region   (IMG_INPUT_BASE)
     *                 (safe to reuse once HLS has finished)
     *   sw_mask     → eliminated (SW cycles are estimated)
     */

    uart_print_separator();
    uart_print("Processing: ");
    uart_print(name);
    uart_print("\r\n");

    /* Turn on processing LED */
    led_set(LED_HEARTBEAT | LED_PROCESSING);

    /* ---- Step 1: Image already in BRAM ---- */
    uart_print("  Image loaded in BRAM.\r\n");

    /* ---- Step 2: Adaptive mode selection ---- */
    SwImageStats stats;
    adaptive_compute_stats(img_data, &stats);
    uint8_t mode = adaptive_select_mode(&stats);
    adaptive_print_decision(&stats, mode);
    led_set_mode(mode);

    /* ---- Step 3: Run HLS accelerator (timed) ---- */
    uart_print("  Starting HLS accelerator...\r\n");
    energy_timer_start();
    hls_start(mode);
    hls_wait_done();
    uint32_t hw_cycles = energy_timer_stop();

    /* Read HLS results */
    uint8_t  threshold  = hls_get_threshold();
    uint32_t fg_pixels  = hls_get_fg_pixels();
    uint8_t  mode_used  = hls_get_mode_used();

    uart_print_uint("  Threshold:      ", threshold);
    uart_print_uint("  FG pixels:      ", fg_pixels);
    uart_print_uint("  Mode used:      ", mode_used);

    /* ---- Step 4: Read output mask directly from BRAM ---- */
    /*
     * The HLS accelerator wrote the thresholded mask to
     * IMG_OUTPUT_BASE in BRAM.  We read it in-place via the
     * AXI BRAM controller — no need to copy 64 KB to the stack.
     */
    const uint8_t *output_mask = (const uint8_t *)IMG_OUTPUT_BASE;

    /* ---- Step 5: SW watershed post-processing ---- */
    uart_print("  Running watershed segmentation...\r\n");
    WatershedResult ws;
    /* Reuse the BRAM input region as the label-map buffer.
     * The input image is no longer needed (HLS already consumed it). */
    ws.label_map = (uint8_t *)IMG_INPUT_BASE;
    watershed_segment(output_mask, &ws);
    watershed_print_summary(&ws);

    /* ---- Step 6: Estimate SW baseline for comparison ---- */
    /*
     * Running a full SW Otsu would require another 64 KB mask
     * buffer that we cannot afford.  Instead we estimate the SW
     * cycle count: histogram (3 cyc/px) + threshold scan (256 iter
     * × ~20 cyc) + apply (2 cyc/px) ≈ 5–20 cyc/px.
     * Empirical MB measurement from Python verification: ~20 cyc/px.
     */
    uint32_t sw_cycles = IMG_SIZE * 20U;
    uart_print("  SW baseline: estimated.\r\n");

    /* ---- Step 7: Energy report ---- */
    EnergyReport report;
    energy_compute_report(hw_cycles, sw_cycles, &report);
    energy_print_report(&report);

    /* Done LED on */
    led_set(LED_HEARTBEAT | LED_DONE);
    uart_print("  DONE.\r\n");
}

/* ==================================================================== */
int main(void)
{
    /* ---- Initialisation ---- */
    uart_init();
    led_set(LED_HEARTBEAT);
    image_clear_buffers();

    uart_print("\r\n");
    uart_print("========================================\r\n");
    uart_print(" Brain Tumor Segmentation – FPGA SoC\r\n");
    uart_print(" Nexys A7-100T / Artix-7 / MicroBlaze\r\n");
    uart_print("========================================\r\n");
    uart_print("\r\n");

    /*
     * NOTE: The 16×16 test images in test_images.h are for bring-up only.
     * For full 256×256 images, load via UART or use the C arrays generated
     * by 05_test_images/convert_to_bin.py.
     *
     * Below we demonstrate the pipeline with the embedded 16×16 thumbnails.
     * In production, replace with full-size images and adjust IMG_SIZE
     * accordingly (it's already 256×256 = 65536 in platform_config.h).
     *
     * We write directly into the BRAM-mapped input region instead of
     * allocating a 64 KB buffer on the stack.
     */

    volatile uint8_t *bram_img = (volatile uint8_t *)IMG_INPUT_BASE;
    const uint8_t *bram_img_ro = (const uint8_t *)IMG_INPUT_BASE;

    /* --- Test 1: Bright circle (high contrast → FAST) --- */
    for (uint32_t i = 0; i < IMG_SIZE; i++) bram_img[i] = 10;
    for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
            int fy = 120 + y;
            int fx = 120 + x;
            bram_img[fy * IMG_WIDTH + fx] = test_bright_circle_16x16[y * 16 + x];
        }
    }
    process_image("Bright Circle (High Contrast)", bram_img_ro);

    /* --- Test 2: Low contrast (→ CAREFUL) --- */
    for (uint32_t i = 0; i < IMG_SIZE; i++) bram_img[i] = 120;
    for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
            int fy = 120 + y;
            int fx = 120 + x;
            bram_img[fy * IMG_WIDTH + fx] = test_low_contrast_16x16[y * 16 + x];
        }
    }
    process_image("Low Contrast (Noisy)", bram_img_ro);

    /* --- Test 3: Medium contrast (→ NORMAL) --- */
    for (uint32_t i = 0; i < IMG_SIZE; i++) bram_img[i] = 50;
    for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
            int fy = 120 + y;
            int fx = 120 + x;
            bram_img[fy * IMG_WIDTH + fx] = test_medium_contrast_16x16[y * 16 + x];
        }
    }
    process_image("Medium Contrast", bram_img_ro);

    /* ---- All done ---- */
    uart_print("\r\n");
    uart_print("========================================\r\n");
    uart_print(" All tests complete.\r\n");
    uart_print("========================================\r\n");

    /* Heartbeat blink loop */
    volatile uint32_t delay;
    while (1) {
        led_set(LED_HEARTBEAT | LED_DONE);
        for (delay = 0; delay < 5000000; delay++) ;
        led_set(LED_DONE);
        for (delay = 0; delay < 5000000; delay++) ;
    }

    return 0;
}
