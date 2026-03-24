# Build Status & Recovery Guide

**Date:** 2026-03-24
**Status:** Ready for rebuild on Windows with Xilinx tools

## Current Repository State

### ✅ Completed Components

1. **HLS IP Core** - Successfully synthesized and exported
   - Location: `03_vivado_hardware/ip_repo/`
   - Files present: `component.xml`, `custom_hls_otsu_threshold_top_1_0.zip`
   - Status: Ready for Vivado integration

2. **Source Code** - All components present and up-to-date
   - HLS accelerator: `02_hls_accelerator/otsu_threshold.cpp/h`
   - Vivado build script: `03_vivado_hardware/build.tcl`
   - MicroBlaze firmware: `04_vitis_software/src/`
   - Constraints: `03_vivado_hardware/constraints/artix7.xdc`

3. **Build Infrastructure** - Scripts ready
   - `build_all.ps1` - One-click PowerShell build script
   - `03_vivado_hardware/build.tcl` - Vivado non-project mode script
   - `04_vitis_software/Makefile` - Firmware build script

### ⚠️ Previous Build Attempts

**Context:** Previous sessions attempted builds in a GitHub Actions environment without Xilinx tools installed, resulting in "Error during execution" messages.

**Issues encountered:**
- Build attempts in Linux environment without Vivado/Vitis tools
- Timing violations in one Vivado build attempt (build_log.txt)
- Incomplete synthesis runs (build_log5.txt)

**Files cleaned up:**
- `.hls.failed` marker (HLS IP already exists)
- `build_err.txt` (batch file not found errors from Windows scripts in Linux)

### 📋 What Was Being Built

This project implements a **hardware-accelerated brain tumor segmentation system** on FPGA:

1. **Phase 1 (Done):** HLS synthesis of Otsu threshold accelerator
   - Generates custom IP core for Vivado
   - Already complete - IP exists in `ip_repo/`

2. **Phase 2 (Pending):** Vivado hardware build
   - Creates MicroBlaze SoC with HLS accelerator
   - Generates bitstream for Nexys A7-100T FPGA
   - Output: `.bit` file and `.xsa` hardware specification

3. **Phase 3 (Pending):** MicroBlaze firmware compilation
   - Compiles C code for embedded processor
   - Links with generated `.xsa` file
   - Output: `.elf` executable

4. **Phase 4 (Pending):** FPGA programming
   - Load bitstream to FPGA
   - Run firmware and verify via UART

## How to Continue Building

### Option 1: Windows Environment (Recommended)

This project is designed for Windows with Xilinx tools installed.

**Prerequisites:**
- Windows 10/11
- Xilinx Vivado/Vitis 2025.1 installed at `D:\2025.1\`
- Nexys A7-100T FPGA board (optional, for testing)

**Build Steps:**

```powershell
# Clone repository (if not already done)
git clone https://github.com/akulasahasra75/FPGA--Brain-Tumor-Segmentation
cd FPGA--Brain-Tumor-Segmentation

# One-click build (everything)
powershell -ExecutionPolicy Bypass -File build_all.ps1

# Or step-by-step:

# Step 1: HLS synthesis (optional - IP already exists)
cd 02_hls_accelerator
D:\2025.1\Vitis\bin\vitis-run.bat --mode hls --tcl run_hls.tcl

# Step 2: Vivado build (~20-40 minutes)
cd ..\03_vivado_hardware
D:\2025.1\Vivado\bin\vivado.bat -mode batch -source build.tcl

# Step 3: Firmware compilation
cd ..\04_vitis_software
make

# Step 4: Program FPGA
cd ..
powershell -File program_fpga.ps1
```

### Option 2: Linux Environment

**Prerequisites:**
- Ubuntu 20.04/22.04
- Xilinx Vivado/Vitis 2025.1 installed
- Set environment variables:
  ```bash
  source /tools/Xilinx/Vivado/2025.1/settings64.sh
  source /tools/Xilinx/Vitis/2025.1/settings64.sh
  ```

**Build Steps:**

```bash
# Step 1: Vivado build
cd 03_vivado_hardware
vivado -mode batch -source build.tcl

# Step 2: Firmware compilation
cd ../04_vitis_software
make

# Step 3: Program FPGA (via Vivado Hardware Manager)
cd ..
vivado -mode tcl -source lab_program.tcl
```

### Option 3: Vitis Unified IDE

1. Launch Vitis 2025.1
2. Create new platform project from `03_vivado_hardware/vivado_project/brain_tumor_soc.xsa`
3. Import application from `04_vitis_software/src/`
4. Build platform and application
5. Program and run

## Expected Build Outputs

After successful build:

```
03_vivado_hardware/vivado_project/
├── brain_tumor_soc.runs/
│   └── impl_1/
│       ├── microblaze_soc_wrapper.bit    ← FPGA bitstream
│       └── microblaze_soc_wrapper.dcp    ← Design checkpoint
└── brain_tumor_soc.xsa                   ← Hardware specification

04_vitis_software/build/
└── brain_tumor_seg.elf                   ← MicroBlaze firmware
```

## Known Issues & Solutions

### Issue 1: Timing Violations

**Symptom:** Vivado implementation fails with timing violations

**Solution:**
- Check `03_vivado_hardware/build.tcl` line 112 - MicroBlaze endianness is set to 0 (little-endian)
- If timing still fails, reduce clock to 50 MHz in `build.tcl`:
  ```tcl
  create_bd_port -dir I -type clk -freq_hz 50000000 clk_100mhz
  ```

### Issue 2: HLS IP Not Found

**Symptom:** Vivado can't find HLS Otsu IP

**Solution:**
- Verify `03_vivado_hardware/ip_repo/component.xml` exists
- Re-run HLS synthesis if needed:
  ```bash
  cd 02_hls_accelerator
  vitis-run --mode hls --tcl run_hls.tcl
  ```

### Issue 3: MicroBlaze Compilation Fails

**Symptom:** `mb-gcc` not found or linker errors

**Solution:**
- Ensure Vitis environment is sourced
- Check paths in `04_vitis_software/Makefile`
- Verify `lscript.ld` matches your memory map

## Documentation

For detailed information:
- **[User Manual](06_documentation/user_manual.md)** - Complete build guide
- **[Project Report](06_documentation/project_report.md)** - Technical details
- **[README.md](README.md)** - Project overview

## Next Steps

1. **If you have Windows + Xilinx tools:**
   - Run `build_all.ps1` to complete the build
   - Expected time: 40-60 minutes
   - Output: `C:\bts\brain_tumor_final.bit`

2. **If you don't have Xilinx tools:**
   - Install Vivado/Vitis 2025.1 (free with AMD account)
   - Or use university lab computers with Xilinx tools

3. **To verify without hardware:**
   - Run Python verification: `cd 01_python_verification && python run_all_tests.py`
   - Check HLS C-simulation results in `02_hls_accelerator/otsu_hls/`

## Support

For build issues:
- Check build logs in `03_vivado_hardware/build_log*.txt`
- Review Vivado reports in `vivado_project/brain_tumor_soc.runs/`
- See troubleshooting section in [User Manual](06_documentation/user_manual.md)

---

**Summary:** The repository is in good shape. HLS IP is ready. The build just needs to be run on a system with Xilinx Vivado/Vitis tools installed.
