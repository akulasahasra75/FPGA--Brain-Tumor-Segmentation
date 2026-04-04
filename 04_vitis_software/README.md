# 04_vitis_software

## Purpose

MicroBlaze firmware that controls the Otsu hardware accelerator and communicates via UART.

## Files

- **`build_software.bat`** - Main build script (auto-detects Vitis version)
- **`create_vitis_project.tcl`** - TCL script for Vitis 2024.1 (requires xsct tool)
- **`create_vitis_project.py`** - Python helper for Vitis 2025.1 with instructions
- **`Makefile`** - Generated makefile template
- **`src/main.c`** - Main MicroBlaze application
- **`src/platform_config.h`** - Hardware platform configuration
- **`src/adaptive_controller.c/h`** - Adaptive processing mode controller
- **`src/energy_analyzer.c/h`** - Energy consumption analysis
- **`src/image_loader.c/h`** - Image loading utilities
- **`src/uart_debug.c/h`** - UART debugging utilities
- **`src/watershed.c/h`** - Watershed segmentation
- **`src/test_images.h`** - Embedded test image data

## Prerequisites

- XSA file from: `../03_vivado_hardware/vivado_project/brain_tumor_soc.xsa`
- Vitis 2024.1 or earlier (includes `xsct` tool for automation)

## Usage

### Option 1: Vitis 2024.1 (Automated) ✅ RECOMMENDED

```batch
build_software.bat
```

Script will automatically build and deploy firmware.

### Option 2: Vitis 2025.1 (Manual - GUI)

```batch
build_software.bat
```

Follow on-screen instructions to use Vitis IDE.

**Note:** Vitis 2025.1 removed the `xsct` command-line tool, so automated builds require Vitis 2024.1 or earlier.

## What the Firmware Does

1. Initializes UART for serial communication (115200 baud)
2. Loads test image from embedded memory
3. Configures Otsu IP accelerator
4. Triggers hardware processing
5. Reads back segmented result
6. Outputs statistics and result via UART

## Vitis Version Compatibility

| Version           | Status         | Workflow               |
| ----------------- | -------------- | ---------------------- |
| 2024.1 or earlier | ✅ Recommended | Automated (xsct + TCL) |
| 2025.1            | ⚠️ Manual Only | Use IDE (GUI)          |

## Troubleshooting

- **"xsct is not recognized"**: Install Vitis 2024.1 or use the GUI
- **"XSA not found"**: Run `03_vivado_hardware/build.tcl` first
