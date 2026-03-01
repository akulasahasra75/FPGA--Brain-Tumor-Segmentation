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
    /* Set image pointers */
    REG_WRITE(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_IMG_IN_LO, IMG_INPUT_BASE);
    REG_WRITE(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_IMG_IN_HI, 0);
    REG_WRITE(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_IMG_OUT_LO, IMG_OUTPUT_BASE);
    REG_WRITE(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_IMG_OUT_HI, 0);

    /* Set processing mode */
    REG_WRITE(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_MODE, mode);

    /* Start accelerator (ap_start = bit 0) */
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
    return (uint8_t)REG_READ(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_RESULT_MODE);
}

/* ---- Process one image end-to-end ---- */
static void process_image(const char *name,
                          const uint8_t *img_data,
                          uint32_t img_size)
{
    uint8_t output_mask[IMG_SIZE];
    uint8_t sw_mask[IMG_SIZE];

    uart_print_separator();
    uart_print("Processing: ");
    uart_print(name);
    uart_print("\r\n");

    /* Turn on processing LED */
    led_set(LED_HEARTBEAT | LED_PROCESSING);

    /* ---- Step 1: Load image ---- */
    uart_print("  Loading image to BRAM...\r\n");
    image_load_to_bram(img_data);

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

    /* ---- Step 4: Read output mask ---- */
    image_read_from_bram(output_mask);

    /* ---- Step 5: SW watershed post-processing ---- */
    uart_print("  Running watershed segmentation...\r\n");
    WatershedResult ws;
    watershed_segment(output_mask, &ws);
    watershed_print_summary(&ws);

    /* ---- Step 6: SW baseline for comparison ---- */
    uart_print("  Running SW baseline for comparison...\r\n");
    uint32_t sw_cycles = energy_sw_baseline(img_data, sw_mask);

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
     */

    /* For bring-up: pad 16×16 thumbnails into 256×256 buffers */
    uint8_t full_img[IMG_SIZE];

    /* --- Test 1: Bright circle (high contrast → FAST) --- */
    memset(full_img, 10, IMG_SIZE);
    for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
            /* Place thumbnail in centre of 256×256 image */
            int fy = 120 + y;
            int fx = 120 + x;
            full_img[fy * IMG_WIDTH + fx] = test_bright_circle_16x16[y * 16 + x];
        }
    }
    process_image("Bright Circle (High Contrast)", full_img, IMG_SIZE);

    /* --- Test 2: Low contrast (→ CAREFUL) --- */
    memset(full_img, 120, IMG_SIZE);
    for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
            int fy = 120 + y;
            int fx = 120 + x;
            full_img[fy * IMG_WIDTH + fx] = test_low_contrast_16x16[y * 16 + x];
        }
    }
    process_image("Low Contrast (Noisy)", full_img, IMG_SIZE);

    /* --- Test 3: Medium contrast (→ NORMAL) --- */
    memset(full_img, 50, IMG_SIZE);
    for (int y = 0; y < 16; y++) {
        for (int x = 0; x < 16; x++) {
            int fy = 120 + y;
            int fx = 120 + x;
            full_img[fy * IMG_WIDTH + fx] = test_medium_contrast_16x16[y * 16 + x];
        }
    }
    process_image("Medium Contrast", full_img, IMG_SIZE);

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
