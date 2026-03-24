/******************************************************************************
 * image_loader.c
 * ---------------
 * Memory-mapped image transfer to/from BRAM buffers.
 *****************************************************************************/
#include "image_loader.h"
#include <string.h>

/* ------------------------------------------------------------------ */
void image_load_to_bram(const uint8_t *src)
{
    volatile uint8_t *dst = (volatile uint8_t *)IMG_INPUT_BASE;
    for (uint32_t i = 0; i < IMG_SIZE; i++) {
        dst[i] = src[i];
    }
}

/* ------------------------------------------------------------------ */
void image_read_from_bram(uint8_t *dst)
{
    volatile const uint8_t *src = (volatile const uint8_t *)IMG_OUTPUT_BASE;
    for (uint32_t i = 0; i < IMG_SIZE; i++) {
        dst[i] = src[i];
    }
}

/* ------------------------------------------------------------------ */
void image_clear_buffers(void)
{
    volatile uint8_t *inp = (volatile uint8_t *)IMG_INPUT_BASE;
    volatile uint8_t *out = (volatile uint8_t *)IMG_OUTPUT_BASE;
    for (uint32_t i = 0; i < IMG_SIZE; i++) {
        inp[i] = 0;
        out[i] = 0;
    }
}
