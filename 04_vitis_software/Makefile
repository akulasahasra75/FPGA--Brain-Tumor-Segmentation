################################################################################
# Makefile for Brain Tumor Segmentation – MicroBlaze Application
#
# This Makefile is designed for use with the Vitis / Xilinx SDK toolchain.
# It compiles the bare-metal MicroBlaze application.
#
# Usage:
#   make              – build the ELF
#   make clean        – remove build artefacts
#   make desktop      – build with gcc for desktop testing (no HW access)
#
# For actual FPGA deployment, use Vitis IDE or xsct to build and program.
################################################################################

# ---- Toolchain (Xilinx MicroBlaze) ----
MB_CC       = mb-gcc
MB_OBJCOPY  = mb-objcopy
MB_SIZE     = mb-size

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
       $(SRC_DIR)/uart_debug.c

HDRS = $(SRC_DIR)/platform_config.h \
       $(SRC_DIR)/image_loader.h \
       $(SRC_DIR)/watershed.h \
       $(SRC_DIR)/adaptive_controller.h \
       $(SRC_DIR)/energy_analyzer.h \
       $(SRC_DIR)/uart_debug.h \
       $(SRC_DIR)/test_images.h

# ---- MicroBlaze flags ----
MB_CFLAGS  = -Wall -O2 -mno-xl-soft-mul
MB_LDFLAGS = -Wl,-T -Wl,lscript.ld

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
