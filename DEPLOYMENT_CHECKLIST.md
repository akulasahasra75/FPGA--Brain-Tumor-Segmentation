# FPGA Brain Tumor Segmentation - Pre-Deployment Checklist

## Target Hardware
- **Board:** Nexys 4 DDR
- **FPGA:** Artix-7 xc7a100tcsg324-1
- **Clock:** 100 MHz

## Current Status

### ✅ COMPLETED
- [x] Python verification (Dice > 0.98 for tumor images)
- [x] Test images generated (brain_01, brain_02, brain_03)
- [x] 128×128 binary/header conversion complete
- [x] XDC constraints updated for Nexys 4 DDR
- [x] Board part updated in build.tcl
- [x] All software source files ready

### ⏳ PENDING (Requires Vivado/Vitis Tools)
- [ ] HLS synthesis (run: `vitis_hls -f run_hls.tcl`)
- [ ] Vivado build (run: `vivado -mode batch -source build.tcl`)
- [ ] Vitis application build
- [ ] Hardware deployment

## Files Ready for Build

### Phase 1: Python Verification
```
01_python_verification/
├── generate_test_images.py    ✅ Working
├── otsu_watershed.py          ✅ Working
├── verify_results.py          ✅ Working
└── test_images/               ✅ Generated
```

### Phase 2: HLS Accelerator
```
02_hls_accelerator/
├── otsu_threshold.cpp         ✅ Ready
├── otsu_threshold.h           ✅ Ready (128×128)
├── image_stats.cpp            ✅ Ready
├── test_otsu.cpp              ✅ Ready
└── run_hls.tcl                ✅ Ready
```

### Phase 3: Vivado Hardware
```
03_vivado_hardware/
├── build.tcl                  ✅ Updated for Nexys 4 DDR
├── constraints/artix7.xdc     ✅ Updated pins
└── ip_repo/                   ⏳ Needs HLS IP
```

### Phase 4: Vitis Software
```
04_vitis_software/
├── src/main.c                 ✅ Ready
├── src/platform_config.h      ✅ Ready (128×128, Nexys 4 DDR)
├── src/watershed.c            ✅ Ready
├── src/adaptive_controller.c  ✅ Ready
└── Makefile                   ✅ Ready
```

### Phase 5: Test Images
```
05_test_images/
├── bin/brain_01.bin           ✅ 16,384 bytes
├── bin/brain_02.bin           ✅ 16,384 bytes
├── bin/brain_03.bin           ✅ 16,384 bytes
├── c_headers/brain_01.h       ✅ 128×128 array
├── c_headers/brain_02.h       ✅ 128×128 array
└── c_headers/brain_03.h       ✅ 128×128 array
```

## Build Commands

### On Windows with Vivado installed:
```batch
REM Run from project root
BUILD_ALL.bat
```

### Manual steps:
```batch
REM Step 2: HLS Synthesis
cd 02_hls_accelerator
vitis_hls -f run_hls.tcl

REM Copy IP to Vivado
copy otsu_hls\solution1\impl\export.zip ..\03_vivado_hardware\ip_repo\

REM Step 3: Vivado Build
cd ..\03_vivado_hardware
vivado -mode batch -source build.tcl

REM Step 4: Vitis (use GUI)
REM - Create platform from brain_tumor_soc.xsa
REM - Create application with src/ files
REM - Build and run
```

## Hardware Deployment

1. **Connect Nexys 4 DDR** via USB cable
2. **Open Vivado Hardware Manager**
3. **Program bitstream:**
   - File: `03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/microblaze_soc_wrapper.bit`
4. **Open Vitis, download ELF**
5. **Open serial terminal:**
   - Port: COM port shown in Device Manager
   - Baud: 115200
   - Data: 8-N-1

## Expected Serial Output
```
========================================
 Brain Tumor Segmentation – FPGA SoC
 Nexys 4 DDR / Artix-7 / MicroBlaze
========================================

----------------------------------------
Processing: Bright Circle (High Contrast)
  Loading image to BRAM...
  Stats: mean=XX, std=XX, contrast=XXX
  Mode: FAST (high contrast detected)
  Starting HLS accelerator...
  Threshold:      XXX
  FG pixels:      XXXX
  Mode used:      0
  ...
```

## LED Indicators
| LED | Function |
|-----|----------|
| LD0 | Heartbeat (1 Hz blink) |
| LD1 | Processing (ON during HLS) |
| LD2 | Mode bit 0 |
| LD3 | Mode bit 1 |
| LD4 | Done (ON when complete) |

## Troubleshooting

### HLS synthesis fails
- Ensure Vitis HLS 2023.2 or later installed
- Check `02_hls_accelerator/run_hls.tcl` for correct part number

### Vivado build fails
- Check timing report for violations
- Ensure HLS IP is extracted in `ip_repo/`
- Try reducing clock to 80 MHz if timing fails

### No serial output
- Check COM port number in Device Manager
- Verify baud rate is 115200
- Ensure bitstream was programmed successfully

### Wrong LED behavior
- Reset board (CPU_RESETN button)
- Re-program bitstream
- Check UART for error messages
