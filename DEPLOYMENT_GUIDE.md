# FPGA Brain Tumor Segmentation - Deployment Guide

## Current Status ✅

| Component     | Status     | Location                                                                       |
| ------------- | ---------- | ------------------------------------------------------------------------------ |
| **Bitstream** | ✅ Ready   | `03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/top_module.bit` |
| **XSA File**  | ✅ Ready   | `03_vivado_hardware/vivado_project/brain_tumor_soc.xsa`                        |
| **Software**  | ⏳ Pending | Build using instructions below                                                 |

---

## Step 1: Build Vitis Software ⏳ CURRENT STEP

### Quick Method (Automated):

```cmd
cd C:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\04_vitis_software
build_software.bat
```

### Manual Method (If script fails):

1. **Open Command Prompt** (Run as Administrator recommended)

2. **Setup Vitis Environment:**

   ```cmd
   call D:\2025.1\Vitis\settings64.bat
   ```

3. **Navigate to Software Directory:**

   ```cmd
   cd C:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\04_vitis_software
   ```

4. **Run Vitis Project Creation:**
   ```cmd
   xsct create_vitis_project.tcl
   ```

### What This Does:

- ✅ Creates hardware platform from XSA file
- ✅ Generates Board Support Package (BSP)
- ✅ Imports all C source files (main.c, watershed.c, adaptive_controller.c, etc.)
- ✅ Compiles MicroBlaze firmware
- ✅ Generates ELF executable
- ✅ Programs FPGA with bitstream
- ✅ Downloads and runs application on MicroBlaze

### Build Time:

⏱️ Approximately 3-5 minutes

### Expected Output:

```
INFO: ELF built: vitis_workspace/brain_tumor_app/Debug/brain_tumor_app.elf
INFO: Application running on MicroBlaze!
```

### Output Files:

- **ELF:** `vitis_workspace/brain_tumor_app/Debug/brain_tumor_app.elf`
- **Platform:** `vitis_workspace/brain_tumor_platform/`
- **BSP:** `vitis_workspace/brain_tumor_platform/zynqmp_fsbl/`

---

## Step 2: Verify Hardware Connection 🔌

### Requirements:

1. **Nexys 4 DDR Board** (Artix-7 xc7a100tcsg324-1)
2. **USB Cable** - Connect to programming port
3. **Power** - Board powered on

### Check Connection:

```cmd
xsct
% connect
% targets
% disconnect
% exit
```

You should see:

- FPGA device: `xc7a100t`
- MicroBlaze processor (after bitstream is loaded)

---

## Step 3: Program FPGA (If not done automatically) 🎯

### Option A: Using Vivado Hardware Manager

1. **Open Vivado:**

   ```cmd
   vivado
   ```

2. **Open Hardware Manager:**
   - Flow Navigator → PROGRAM AND DEBUG → Open Hardware Manager
   - Click "Open Target" → "Auto Connect"

3. **Program Device:**
   - Right-click on xc7a100t → "Program Device"
   - Bitstream file: `03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/top_module.bit`
   - Click "Program"

4. **Wait for "Programming Successful" message** (15-30 seconds)

### Option B: Using XSCT (Command Line)

```cmd
xsct
% connect
% targets -set -filter {name =~ "xc7a*"}
% fpga "C:/Users/anees/Documents/Projects/FPGA--Brain-Tumor-Segmentation/03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/top_module.bit"
% disconnect
% exit
```

---

## Step 4: Download Application to MicroBlaze 📥

**Note:** The `create_vitis_project.tcl` script does this automatically. Only needed if running manually.

### Using XSCT:

```cmd
xsct
% connect
% targets
% targets -set -filter {name =~ "*MicroBlaze*"}
% rst -processor
% dow "C:/Users/anees/Documents/Projects/FPGA--Brain-Tumor-Segmentation/04_vitis_software/vitis_workspace/brain_tumor_app/Debug/brain_tumor_app.elf"
% con
% disconnect
% exit
```

### Using Vitis IDE:

1. Open Vitis: `vitis -workspace 04_vitis_software/vitis_workspace`
2. Right-click `brain_tumor_app` → "Run As" → "Launch on Hardware"

---

## Step 5: Monitor Serial Output 📟

### Setup Serial Terminal:

1. **Find COM Port:**
   - Device Manager → Ports (COM & LPT)
   - Look for "USB Serial Port (COMx)"

2. **Configure Terminal:**
   - **Baud Rate:** 115200
   - **Data Bits:** 8
   - **Parity:** None
   - **Stop Bits:** 1
   - **Flow Control:** None

3. **Terminal Options:**
   - **PuTTY:** Session → Serial → COMx, 115200
   - **TeraTerm:** Setup → Serial Port → COMx, 115200
   - **Minicom (WSL):** `minicom -D /dev/ttyUSBx -b 115200`

### Expected Serial Output:

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
  → Confidence: 0.96

Processing image 2/3...
  [similar output]

Processing image 3/3...
  [similar output]

========================================
All tests complete!
Average HW time: 1.3ms
Average SW time: 42.1ms
Average speedup: 32.4×
========================================
```

---

## Step 6: Verify LED Indicators 💡

### LED Behavior (on Nexys 4 DDR board):

| LED           | Function          | Expected                    |
| ------------- | ----------------- | --------------------------- |
| **LD0**       | Heartbeat         | Blinks at 1 Hz continuously |
| **LD1**       | Processing Active | ON during image processing  |
| **LD4**       | Done Signal       | ON when processing complete |
| **LD15-LD12** | Status            | Shows system state          |

### Troubleshooting LEDs:

- **No LEDs:** Bitstream not programmed or power issue
- **All LEDs ON:** Check constraints file (artix7.xdc)
- **No heartbeat:** Application not running or stuck

---

## Step 7: Performance Verification ⚡

### Expected Performance Metrics:

| Metric             | Hardware | Software | Speedup   |
| ------------------ | -------- | -------- | --------- |
| **Otsu Threshold** | ~1.2ms   | ~40ms    | ~33×      |
| **Full Pipeline**  | ~5ms     | ~180ms   | ~36×      |
| **Power**          | <2W      | N/A      | Efficient |

### Verification Steps:

1. **Check timing from serial output**
2. **Compare with software-only implementation:**
   ```cmd
   cd 01_python_verification
   python otsu_watershed.py
   ```
3. **Validate Dice coefficient > 0.98** (accuracy maintained)

---

## Troubleshooting 🔧

### Common Issues:

#### 1. **"xsct: command not found"**

**Solution:** Source Vitis environment:

```cmd
call D:\2025.1\Vitis\settings64.bat
```

#### 2. **"No hardware targets found"**

**Solutions:**

- Check USB cable connection
- Install/update board drivers
- Try different USB port
- Check Device Manager for hardware

#### 3. **"Version mismatch warning" (Vivado 2023.1 vs Vitis 2024.1)**

**Solution:** This is expected and safe. Vitis will handle it automatically.

#### 4. **Build errors in Vitis**

**Common fixes:**

- Clean build: `make clean && make all`
- Regenerate platform: Delete `vitis_workspace` and rerun `xsct create_vitis_project.tcl`
- Check XSA file exists

#### 5. **No serial output**

**Solutions:**

- Verify COM port in Device Manager
- Check baud rate is 115200
- Ensure application is running (check LEDs)
- Try different terminal program

#### 6. **Bitstream programming fails**

**Solutions:**

- Check JTAG cable connection
- Update Vivado cable drivers
- Try Vivado Hardware Manager instead of XSCT
- Verify board is powered on

---

## File Locations Reference 📁

```
FPGA--Brain-Tumor-Segmentation/
├── 03_vivado_hardware/
│   └── vivado_project/
│       ├── brain_tumor_soc.xsa                    ← Hardware export
│       └── brain_tumor_soc.runs/impl_1/
│           └── top_module.bit                      ← FPGA bitstream
│
├── 04_vitis_software/
│   ├── create_vitis_project.tcl                    ← Main build script
│   ├── build_software.bat                          ← Automated build
│   └── vitis_workspace/                            ← Generated
│       └── brain_tumor_app/Debug/
│           └── brain_tumor_app.elf                 ← MicroBlaze firmware
│
├── 05_test_images/
│   └── bin/                                        ← Test images
│       ├── brain_01.bin
│       ├── brain_02.bin
│       └── brain_03.bin
│
└── 06_documentation/
    └── hardware_output/
        └── brain_tumor_soc.bit                     ← Backup bitstream
```

---

## Next Steps After Successful Deployment ✨

1. **Characterize Performance:**
   - Run multiple test images
   - Measure power consumption
   - Analyze timing reports

2. **Optimize (Optional):**
   - Adjust clock frequency
   - Tune HLS pragmas for better performance
   - Reduce resource usage if needed

3. **Document Results:**
   - Update `06_documentation/results.txt`
   - Capture serial output screenshots
   - Record performance metrics

4. **Create Demo:**
   - Prepare video demonstration
   - Document workflow
   - Showcase speedup metrics

---

## Quick Reference Commands 📝

### Build Software:

```cmd
cd 04_vitis_software
build_software.bat
```

### Program FPGA:

```cmd
xsct
% connect
% targets -set -filter {name =~ "xc7a*"}
% fpga "../03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/top_module.bit"
% disconnect
% exit
```

### Run Application:

```cmd
xsct
% connect
% targets -set -filter {name =~ "*MicroBlaze*"}
% rst -processor
% dow "vitis_workspace/brain_tumor_app/Debug/brain_tumor_app.elf"
% con
% disconnect
% exit
```

---

## Support Resources 🆘

- **Xilinx Documentation:** https://docs.xilinx.com/
- **Vitis Tutorials:** https://github.com/Xilinx/Vitis-Tutorials
- **Project Issues:** Check `06_documentation/` for known issues
- **Hardware Manual:** Nexys 4 DDR Reference Manual

---

**Last Updated:** 2026-04-01  
**Status:** Ready for deployment after software build completes
