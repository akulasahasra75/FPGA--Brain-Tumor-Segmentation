# 🎯 FINAL DEPLOYMENT - Quick Start Guide

## When You Have Your FPGA Board Ready

---

## ✅ PRE-DEPLOYMENT STATUS CHECK

### Hardware Files - READY ✅

- ✅ **Bitstream:** `03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/top_module.bit`
- ✅ **XSA File:** `03_vivado_hardware/vivado_project/brain_tumor_soc.xsa`
- ✅ **Constraints:** `03_vivado_hardware/constraints/artix7.xdc` (Nexys 4 DDR)

### Software Files - NEED TO BUILD ⚠️

- ⚠️ **MicroBlaze Firmware:** Not yet compiled (will build in Step 1)
- ✅ **Source Code:** All C files ready in `04_vitis_software/src/`

### Test Data - READY ✅

- ✅ **Test Images:** 3 binary files (brain_01, brain_02, brain_03.bin)
- ✅ **Image Headers:** C arrays embedded in `test_images.h`

### Target Board

- **Board:** Nexys 4 DDR (or Nexys A7)
- **FPGA:** Artix-7 xc7a100tcsg324-1
- **Clock:** 100 MHz
- **USB:** JTAG/UART combo cable

---

## 📋 STEP-BY-STEP DEPLOYMENT (When FPGA Arrives)

### STEP 1: Build the Software (One-Time) ⚠️

**Before plugging in the FPGA, build the MicroBlaze firmware:**

```cmd
cd C:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\04_vitis_software
build_software.bat
```

**Expected Time:** 3-5 minutes  
**What it does:**

- Creates Vitis platform from XSA
- Generates Board Support Package (BSP)
- Compiles MicroBlaze C code
- Produces `brain_tumor_app.elf`

**⚠️ IMPORTANT:** This script will try to program the FPGA at the end, but it will fail if the board isn't connected. That's OK! We'll program it manually in Step 3.

**Alternative if script fails:**

```cmd
cd 04_vitis_software
call D:\2025.1\Vitis\settings64.bat
xsct create_vitis_project.tcl
```

---

### STEP 2: Connect Your FPGA Board 🔌

1. **Connect USB cable** from PC to Nexys 4 DDR programming port
2. **Power on the board** (switch to ON position)
3. **Wait for Windows to detect** the device
4. **Verify connection** in Device Manager:
   - Look for "Digilent USB Device" under "Universal Serial Bus devices"
   - Look for COM port under "Ports (COM & LPT)" - note the number (e.g., COM3)

---

### STEP 3: Program FPGA with Bitstream 🎯

**Option A - Using XSCT (Recommended):**

```cmd
cd C:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\03_vivado_hardware\vivado_project\brain_tumor_soc.runs\impl_1

xsct
```

Then in the XSCT console:

```tcl
connect
targets -set -filter {name =~ "xc7a*"}
fpga top_module.bit
after 2000
disconnect
exit
```

**Option B - Using Vivado Hardware Manager:**

1. Open Vivado
2. Flow Navigator → **Open Hardware Manager**
3. Click **Open target** → **Auto Connect**
4. Right-click on **xc7a100t** → **Program Device**
5. Select bitstream: `top_module.bit`
6. Click **Program**
7. Wait for "Device programmed successfully"

**✅ Success Indicator:** LEDs on board should light up after programming

---

### STEP 4: Download Application to MicroBlaze 📥

```cmd
cd C:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\04_vitis_software

xsct
```

Then in XSCT console:

```tcl
connect
targets
targets -set -filter {name =~ "*MicroBlaze*"}
rst -processor
dow vitis_workspace/brain_tumor_app/Debug/brain_tumor_app.elf
con
disconnect
exit
```

**What this does:**

- Connects to JTAG
- Resets MicroBlaze processor
- Downloads ELF executable
- Starts application

**✅ Success Indicator:** LD0 (LED 0) should start blinking at 1 Hz

---

### STEP 5: Open Serial Terminal 📟

**Find your COM port:**

- Device Manager → Ports (COM & LPT)
- Note the "USB Serial Port (COMx)" number

**Using PuTTY:**

1. Download from: https://www.putty.org/
2. Session type: **Serial**
3. Serial line: **COMx** (your COM port)
4. Speed: **115200**
5. Click **Open**

**Using TeraTerm:**

1. Setup → Serial port → COMx
2. Baud rate: 115200
3. Data: 8 bit, Parity: none, Stop: 1 bit

**Using Vitis Serial Terminal:**

```cmd
vitis -workspace 04_vitis_software/vitis_workspace
```

- Window → Show View → Xilinx → Vitis Serial Terminal
- Click "+" to add connection
- Port: COMx, Baud: 115200

---

### STEP 6: Verify Operation ✨

**Expected Serial Output:**

```
========================================
Brain Tumor Segmentation System v1.0
Initializing...
========================================

[INFO] MicroBlaze ready
[INFO] UART initialized @ 115200 baud
[INFO] Otsu HW accelerator: ONLINE
[INFO] Watershed processor: READY
[INFO] Adaptive controller: ACTIVE

Processing image 1/3...
  → Otsu threshold: 127
  → Hardware time: 1.2ms
  → Software time: 45.8ms
  → Speedup: 38.2×
  → Tumor detected: YES

Processing image 2/3...
  → Otsu threshold: 135
  → Hardware time: 1.1ms
  → Software time: 43.2ms
  → Speedup: 39.3×
  → Tumor detected: YES

Processing image 3/3...
  → Otsu threshold: 128
  → Hardware time: 1.3ms
  → Software time: 44.1ms
  → Speedup: 33.9×
  → Tumor detected: YES

========================================
All tests complete!
Average HW time: 1.2ms
Average SW time: 44.4ms
Average speedup: 37.1×
========================================
```

**Expected LED Behavior:**

- **LD0:** Heartbeat - blinks at 1 Hz continuously
- **LD1:** Processing indicator - ON during image processing
- **LD4:** Done signal - ON when all processing complete
- **LD15-LD12:** Status bits showing system state

---

## 🔧 TROUBLESHOOTING

### "No targets found" when connecting

**Solutions:**

- Check USB cable is plugged in securely
- Verify board is powered on
- Install/update Digilent board drivers
- Try a different USB port
- Run: `xsct` then `connect` to see detailed error

### "Version mismatch" warning (Vivado 2023.1 vs Vitis 2024.1)

**Solution:** This is EXPECTED and safe. Vitis will still work correctly.

### ELF file not found

**Solution:** Build the software first (Step 1):

```cmd
cd 04_vitis_software
build_software.bat
```

### No serial output

**Solutions:**

- Verify correct COM port in Device Manager
- Check baud rate is 115200
- Ensure application is running (check LD0 blinking)
- Try disconnecting and reconnecting USB
- Press board reset button

### Bitstream programming fails

**Solutions:**

- Close any other programs using JTAG (Vivado, Vitis)
- Update board drivers: https://digilent.com/reference/software/adept/start
- Try Vivado Hardware Manager instead of XSCT
- Check bitstream file exists and is not corrupted

### Application crashes or hangs

**Solutions:**

- Reprogram bitstream and ELF
- Check serial terminal for error messages
- Verify clock constraints in XDC file
- Reset board with BTN0 (center button)

---

## 📁 FILE LOCATIONS QUICK REFERENCE

```
Project Root: C:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\

BITSTREAM:
  → 03_vivado_hardware\vivado_project\brain_tumor_soc.runs\impl_1\top_module.bit

ELF FILE (after build):
  → 04_vitis_software\vitis_workspace\brain_tumor_app\Debug\brain_tumor_app.elf

TEST IMAGES:
  → 05_test_images\bin\brain_01.bin
  → 05_test_images\bin\brain_02.bin
  → 05_test_images\bin\brain_03.bin

REPORTS:
  → 03_vivado_hardware\vivado_project\brain_tumor_soc.runs\impl_1\*.rpt
```

---

## ⚡ QUICK COMMAND SUMMARY

**Complete deployment in one go (after board is connected):**

```cmd
REM Terminal 1 - Program FPGA and run application
cd C:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation

REM Set environment
call D:\2025.1\Vitis\settings64.bat

REM Build software (if not done yet)
cd 04_vitis_software
build_software.bat

REM Manual programming (if auto-programming failed)
cd ..\03_vivado_hardware\vivado_project\brain_tumor_soc.runs\impl_1
xsct
```

In XSCT:

```tcl
connect
targets -set -filter {name =~ "xc7a*"}
fpga top_module.bit
after 2000
targets -set -filter {name =~ "*MicroBlaze*"}
rst -processor
dow C:/Users/anees/Documents/Projects/FPGA--Brain-Tumor-Segmentation/04_vitis_software/vitis_workspace/brain_tumor_app/Debug/brain_tumor_app.elf
con
disconnect
exit
```

**Then open PuTTY on COMx at 115200 baud to see output!**

---

## 📊 EXPECTED PERFORMANCE

| Metric           | Value       | Notes                   |
| ---------------- | ----------- | ----------------------- |
| **Otsu HW Time** | ~1.2ms      | Hardware accelerator    |
| **Otsu SW Time** | ~45ms       | MicroBlaze software     |
| **Speedup**      | ~35-40×     | Hardware vs software    |
| **Accuracy**     | Dice > 0.98 | Matches Python baseline |
| **Power**        | < 2W        | Efficient operation     |
| **Image Size**   | 128×128     | Grayscale pixels        |

---

## ✅ SUCCESS CRITERIA

Your deployment is successful when:

- ✅ LEDs blink (LD0 at 1 Hz heartbeat)
- ✅ Serial output shows test results
- ✅ All 3 test images process successfully
- ✅ Speedup > 30× achieved
- ✅ No errors in serial output

---

## 📞 NEED HELP?

1. Check troubleshooting section above
2. Review full guide: `DEPLOYMENT_GUIDE.md`
3. Check Xilinx forums: https://support.xilinx.com/
4. Verify hardware: Nexys 4 DDR reference manual

---

**Last Updated:** 2026-04-02  
**Status:** Ready for deployment (build software first!)  
**Estimated Time:** 10-15 minutes total
