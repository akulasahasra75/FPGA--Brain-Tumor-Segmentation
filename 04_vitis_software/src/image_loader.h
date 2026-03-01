/******************************************************************************
 * image_loader.h
 * ---------------
 * Functions to load test images into BRAM and retrieve output masks.
 *****************************************************************************/
#ifndef IMAGE_LOADER_H
#define IMAGE_LOADER_H

#include <stdint.h>
#include "platform_config.h"

/**
 * Copy a grayscale image (row-major, 8-bit) into the input BRAM buffer.
 *
 * @param src   Pointer to image data (IMG_SIZE bytes)
 */
void image_load_to_bram(const uint8_t *src);

/**
 * Read the output mask from the output BRAM buffer.
 *
 * @param dst   Destination buffer (IMG_SIZE bytes)
 */
void image_read_from_bram(uint8_t *dst);

/**
 * Clear both input and output BRAM buffers (fill with 0).
 */
void image_clear_buffers(void);

#endif /* IMAGE_LOADER_H */
