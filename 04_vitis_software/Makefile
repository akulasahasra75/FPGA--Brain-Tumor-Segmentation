################################################################################
# Makefile for Brain Tumor Segmentation – MicroBlaze Application
#
# Compiles directly with mb-gcc — no Vitis/SDK BSP needed!
# The code is fully self-contained with bare-metal register access.
#
# Usage:
#   make              – build the ELF (requires mb-gcc on PATH or set MB_PREFIX)
#   make clean        – remove build artefacts
#   make desktop      – build with gcc for desktop testing (no HW access)
#
# Environment:
#   MB_PREFIX  – path to MicroBlaze toolchain bin/ (default: auto-detect D:\2025.1)
################################################################################

# ---- Toolchain (Xilinx MicroBlaze) ----
MB_PREFIX  ?= D:/2025.1/gnu/microblaze/nt/bin
MB_CC       = $(MB_PREFIX)/mb-gcc
MB_OBJCOPY  = $(MB_PREFIX)/mb-objcopy
MB_SIZE     = $(MB_PREFIX)/mb-size

# ---- Toolchain (Desktop testing) ----
CC          = gcc

# ---- Project ----
TARGET      = brain_tumor_seg
SRC_DIR     = src
BUILD_DIR   = build

# ---- Sources ----
SRCS = $(SRC_DIR)/main.c \
       $(SRC_DIR)/image_loader.c \
       $(SRC_DIR)/watershed.c \
       $(SRC_DIR)/adaptive_controller.c \
       $(SRC_DIR)/energy_analyzer.c \
       $(SRC_DIR)/uart_debug.c \
       $(SRC_DIR)/mb_stubs.c

HDRS = $(SRC_DIR)/platform_config.h \
       $(SRC_DIR)/image_loader.h \
       $(SRC_DIR)/watershed.h \
       $(SRC_DIR)/adaptive_controller.h \
       $(SRC_DIR)/energy_analyzer.h \
       $(SRC_DIR)/uart_debug.h \
       $(SRC_DIR)/test_images.h

# ---- MicroBlaze flags ----
MB_CFLAGS  = -mcpu=v11.0 -Wall -Os -ffunction-sections -fdata-sections
MB_LDFLAGS = -nodefaultlibs -Wl,--gc-sections -T lscript.ld -lgcc -lc -lgcc

# ---- Desktop flags ----
DESKTOP_CFLAGS  = -Wall -O2 -DDESKTOP_SIM -g
DESKTOP_LDFLAGS =

# ---- Objects ----
MB_OBJS      = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRCS))
DESKTOP_OBJS = $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/desktop_%.o,$(SRCS))

# ==============================================================================
# MicroBlaze build
# ==============================================================================
.PHONY: all clean desktop

all: $(BUILD_DIR)/$(TARGET).elf
	$(MB_SIZE) $<

$(BUILD_DIR)/$(TARGET).elf: $(MB_OBJS)
	$(MB_CC) $(MB_CFLAGS) $(MB_LDFLAGS) -o $@ $^

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c $(HDRS) | $(BUILD_DIR)
	$(MB_CC) $(MB_CFLAGS) -c -o $@ $<

# ==============================================================================
# Desktop simulation build (for testing logic without hardware)
# ==============================================================================
desktop: $(BUILD_DIR)/$(TARGET)_desktop
	@echo "Desktop build complete: $<"

$(BUILD_DIR)/$(TARGET)_desktop: $(DESKTOP_OBJS)
	$(CC) $(DESKTOP_CFLAGS) $(DESKTOP_LDFLAGS) -o $@ $^

$(BUILD_DIR)/desktop_%.o: $(SRC_DIR)/%.c $(HDRS) | $(BUILD_DIR)
	$(CC) $(DESKTOP_CFLAGS) -c -o $@ $<

# ==============================================================================
# Housekeeping
# ==============================================================================
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

clean:
	rm -rf $(BUILD_DIR)
