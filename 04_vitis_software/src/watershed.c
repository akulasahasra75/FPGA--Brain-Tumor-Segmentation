/******************************************************************************
 * watershed.c
 * -------------
 * Connected-component labelling for binary tumor masks.
 *
 * Uses a simple scanline flood-fill (no recursion, constant stack) so it
 * runs safely on MicroBlaze with limited stack space.
 *****************************************************************************/
#include "watershed.h"
#include "uart_debug.h"
#include <string.h>

/* ---- Tiny queue for BFS (statically allocated) ---- */
#define QUEUE_CAP  IMG_SIZE
static uint32_t queue_buf[QUEUE_CAP];
static uint32_t q_head, q_tail;

static void q_reset(void)       { q_head = q_tail = 0; }
static int  q_empty(void)       { return q_head == q_tail; }
static void q_push(uint32_t v)  { queue_buf[q_tail++ % QUEUE_CAP] = v; }
static uint32_t q_pop(void)     { return queue_buf[q_head++ % QUEUE_CAP]; }

/* ------------------------------------------------------------------ */
void watershed_segment(const uint8_t *mask, WatershedResult *result)
{
    /* Clear output */
    memset(result, 0, sizeof(*result));
    memset(result->label_map, 0, IMG_SIZE);

    uint8_t current_label = 0;

    for (uint32_t idx = 0; idx < IMG_SIZE; idx++) {
        /* Skip background or already labelled */
        if (mask[idx] == 0 || result->label_map[idx] != 0)
            continue;

        if (current_label >= MAX_REGIONS)
            break;

        current_label++;
        RegionInfo *r = &result->regions[current_label - 1];
        r->label    = current_label;
        r->area     = 0;
        r->bbox_x0  = IMG_WIDTH;
        r->bbox_y0  = IMG_HEIGHT;
        r->bbox_x1  = 0;
        r->bbox_y1  = 0;
        uint32_t sum_x = 0, sum_y = 0;

        /* BFS flood fill */
        q_reset();
        q_push(idx);
        result->label_map[idx] = current_label;

        while (!q_empty()) {
            uint32_t p = q_pop();
            uint16_t px = (uint16_t)(p % IMG_WIDTH);
            uint16_t py = (uint16_t)(p / IMG_WIDTH);

            r->area++;
            sum_x += px;
            sum_y += py;

            if (px < r->bbox_x0) r->bbox_x0 = px;
            if (py < r->bbox_y0) r->bbox_y0 = py;
            if (px > r->bbox_x1) r->bbox_x1 = px;
            if (py > r->bbox_y1) r->bbox_y1 = py;

            /* 4-connected neighbours */
            int16_t dx[] = {-1, 1, 0, 0};
            int16_t dy[] = {0, 0, -1, 1};
            for (int d = 0; d < 4; d++) {
                int16_t nx = (int16_t)px + dx[d];
                int16_t ny = (int16_t)py + dy[d];
                if (nx < 0 || nx >= IMG_WIDTH || ny < 0 || ny >= IMG_HEIGHT)
                    continue;
                uint32_t ni = (uint32_t)ny * IMG_WIDTH + (uint32_t)nx;
                if (mask[ni] != 0 && result->label_map[ni] == 0) {
                    result->label_map[ni] = current_label;
                    q_push(ni);
                }
            }
        }

        /* Compute centroid */
        if (r->area > 0) {
            r->centroid_x = (uint16_t)(sum_x / r->area);
            r->centroid_y = (uint16_t)(sum_y / r->area);
        }

        result->total_foreground += r->area;
    }

    result->num_regions = current_label;
}

/* ------------------------------------------------------------------ */
void watershed_print_summary(const WatershedResult *result)
{
    uart_print("=== Watershed Results ===\r\n");

    uart_print_uint("Regions found: ", result->num_regions);
    uart_print_uint("Total foreground pixels: ", result->total_foreground);

    for (uint8_t i = 0; i < result->num_regions; i++) {
        const RegionInfo *r = &result->regions[i];
        uart_print("\r\n--- Region ");
        uart_print_uint("", r->label);
        uart_print_uint("  Area:      ", r->area);
        uart_print_uint("  Centroid X:", r->centroid_x);
        uart_print_uint("  Centroid Y:", r->centroid_y);
        uart_print_uint("  BBox X0:   ", r->bbox_x0);
        uart_print_uint("  BBox Y0:   ", r->bbox_y0);
        uart_print_uint("  BBox X1:   ", r->bbox_x1);
        uart_print_uint("  BBox Y1:   ", r->bbox_y1);
    }
    uart_print("=========================\r\n");
}
