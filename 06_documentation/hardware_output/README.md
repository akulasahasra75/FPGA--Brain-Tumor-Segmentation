# Hardware Output Files

**⚠️ WARNING: The bitstream in this directory is from March 2, 2026 and is OUTDATED!**

The HLS IP was regenerated on April 1, 2026 with fixes for Vitis 2025.1 compatibility.
**You MUST regenerate the bitstream before deploying to hardware.**

## Regenerating the Bitstream

Due to system memory constraints (8GB RAM), the build must run single-threaded:

```batch
cd c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation
.\BUILD_NOW.bat
```

This will take **45-90 minutes**. Close all other applications to free memory.

---

This directory contains the generated FPGA bitstream and hardware description files for the Brain Tumor Segmentation system.

## Files

| File                  | Description                              | Size    |
| --------------------- | ---------------------------------------- | ------- |
| `brain_tumor_soc.bit` | FPGA bitstream for Nexys 4 DDR           | ~2.6 MB |
| `brain_tumor_soc.mmi` | Memory Map Information for ELF download  | ~10 KB  |
| `microblaze_soc.hwh`  | Hardware Handoff file (IP configuration) | ~440 KB |
| `xsa.json`            | XSA metadata                             | ~3 KB   |
| `drivers/`            | IP driver source files                   | -       |

## Target Hardware

- **Board**: Digilent Nexys 4 DDR
- **FPGA**: Xilinx Artix-7 (xc7a100t-csg324-1)
- **Clock**: 100 MHz
- **Built with**: Vivado 2025.1

## Programming the FPGA

### Option 1: Use the batch script

```cmd
cd <project_root>
PROGRAM_FPGA.bat
```

### Option 2: Vivado Hardware Manager (GUI)

1. Open Vivado
2. Open Hardware Manager
3. Open Target → Auto Connect
4. Right-click device → Program Device
5. Select `brain_tumor_soc.bit`
6. Click Program

### Option 3: Vivado TCL Console

```tcl
open_hw_manager
connect_hw_server
open_hw_target
set_property PROGRAM.FILE {brain_tumor_soc.bit} [get_hw_devices xc7a100t_0]
program_hw_devices [get_hw_devices xc7a100t_0]
```

## After Programming

1. Open a serial terminal (PuTTY, TeraTerm, etc.)
2. Connect to the Nexys 4 DDR COM port
3. Settings: **115200 baud, 8N1, no flow control**
4. You should see the application banner:
   ```
   ============================================
     Brain Tumor Segmentation System
     Target: Nexys 4 DDR
   ============================================
   ```

## System Components

The bitstream contains:

- MicroBlaze soft processor (area-optimized)
- 64 KB Local Memory (BRAM)
- AXI UART Lite @ 115200 baud
- AXI GPIO (5 LEDs)
- HLS Otsu Threshold Accelerator IP
- AXI Interconnect

## LED Indicators

| LED | Function                              |
| --- | ------------------------------------- |
| LD0 | Heartbeat (toggles during operation)  |
| LD1 | Processing (ON when HLS IP active)    |
| LD2 | Mode bit 0                            |
| LD3 | Mode bit 1                            |
| LD4 | Done (ON after successful completion) |
