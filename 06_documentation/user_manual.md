# Brain Tumor Segmentation on FPGA – User Manual

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Repository Structure](#2-repository-structure)
3. [Phase 1 – Python Verification](#3-phase-1--python-verification)
4. [Phase 2 – HLS Synthesis](#4-phase-2--hls-synthesis)
5. [Phase 3 – Vivado Build](#5-phase-3--vivado-build)
6. [Phase 4 – Vitis Software](#6-phase-4--vitis-software)
7. [Phase 5 – Test Images](#7-phase-5--test-images)
8. [Running on Hardware](#8-running-on-hardware)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. Prerequisites

### Hardware

- **Digilent Nexys A7-100T** board (Xilinx Artix-7 xc7a100tcsg324-1)
- Micro-USB cable (for programming + UART)

### Software

| Tool           | Version | Purpose                  |
| -------------- | ------- | ------------------------ |
| Python         | 3.8+    | Algorithm verification   |
| NumPy          | ≥ 1.24  | Array operations         |
| OpenCV         | ≥ 4.7   | Image I/O and processing |
| Vitis HLS      | 2025.1  | HLS synthesis            |
| Vivado         | 2025.1  | FPGA design & bitstream  |
| Vitis IDE      | 2025.1  | MicroBlaze firmware      |
| g++ (optional) | Any     | Desktop HLS testing      |

### Installation

```bash
# Python dependencies
cd 01_python_verification
pip install -r requirements.txt
```

For Vitis/Vivado, follow the [Xilinx Unified Installer](https://www.xilinx.com/support/download.html) instructions.

---

## 2. Repository Structure

```
FPGA--Brain-Tumor-Segmentation/
├── 01_python_verification/   Phase 1: Algorithm validation
├── 02_hls_accelerator/       Phase 2: HLS IP core
├── 03_vivado_hardware/       Phase 3: Vivado SoC design
├── 04_vitis_software/        Phase 4: MicroBlaze firmware
├── 05_test_images/           Phase 5: Image conversion
├── 06_documentation/         Phase 6: Reports & docs
├── docs/prd.md               Project requirements
├── .gitignore
├── LICENSE
└── README.md
```

---

## 3. Phase 1 – Python Verification

### Run the full pipeline

```bash
cd 01_python_verification
python run_all_tests.py
```

This will:

1. Generate 3 synthetic MRI test images (`generate_test_images.py`)
2. Run Otsu + watershed segmentation (`otsu_watershed.py`)
3. Compare results against expected masks (`verify_results.py`)

### Expected output

```
=== Generating test images ===
  Created brain_01.png
  Created brain_02.png
  Created brain_03.png

=== Running segmentation ===
  Processing brain_01.png ... done
  Processing brain_02.png ... done
  Processing brain_03.png ... done

=== Verification ===
  brain_01: Dice=0.98, IoU=0.96 ✓
  brain_02: Dice=0.98, IoU=0.97 ✓
  brain_03: Dice=0.19, IoU=0.10 (no tumor expected)
```

### Output files

- `test_images/results/brain_XX_seg.png` – binary segmentation masks
- `test_images/results/brain_XX_overlay.png` – overlay visualisations

---

## 4. Phase 2 – HLS Synthesis

### Option A: Desktop test (no FPGA tools needed)

```bash
cd 02_hls_accelerator
g++ -o test_otsu test_otsu.cpp otsu_threshold.cpp image_stats.cpp -std=c++11
./test_otsu
```

All 9 tests (3 images × 3 modes) should pass.

### Option B: Full HLS synthesis

```bash
cd 02_hls_accelerator

# If using Vitis 2025.1 with vitis-run:
& "D:\2025.1\Vitis\bin\vitis-run.bat" --tcl --input_file run_hls.tcl

# Or if vitis_hls is in PATH:
vitis_hls -f run_hls.tcl
```

### Expected results

| Step                 | Status             |
| -------------------- | ------------------ |
| C Simulation (csim)  | PASS               |
| C Synthesis (csynth) | PASS (~38 seconds) |
| IP Export            | PASS (~18 seconds) |

### Output

- IP core: `otsu_hls/solution1/impl/ip/custom_hls_otsu_threshold_top_1_0.zip`
- Copy this zip to `03_vivado_hardware/ip_repo/`

---

## 5. Phase 3 – Vivado Build

### Step 1: Prepare IP

```bash
# Copy HLS IP to the ip_repo directory
cp 02_hls_accelerator/otsu_hls/solution1/impl/ip/*.zip 03_vivado_hardware/ip_repo/
```

Unzip the IP in `ip_repo/` so Vivado can find the `component.xml`.

### Step 2: Run build script

```bash
cd 03_vivado_hardware
vivado -mode batch -source build.tcl
```

This automated script will:

1. Create a Vivado project
2. Set up MicroBlaze block design with all peripherals
3. Import the HLS Otsu IP
4. Connect AXI bus, memory, UART, GPIO, Timer
5. Run synthesis, implementation, and bitstream generation
6. Export the hardware platform (`.xsa`)

### Expected output

```
INFO: Synthesis complete.
INFO: Implementation complete.
INFO: Bitstream generated.
INFO: Hardware platform exported: ./vivado_project/brain_tumor_soc.xsa
```

### Step 3: Verify in Vivado GUI (optional)

```bash
vivado vivado_project/brain_tumor_soc.xpr
```

Check the block design and resource utilisation reports.

---

## 6. Phase 4 – Vitis Software

### Option A: Desktop syntax check

```bash
cd 04_vitis_software
gcc -Wall -O2 -DDESKTOP_SIM -fsyntax-only src/*.c
```

Zero warnings expected.

### Option B: Build with Vitis IDE

1. Open Vitis IDE
2. Create a new **Application Project**
3. Import the `.xsa` from Phase 3
4. Select **MicroBlaze** as the processor
5. Choose **Empty Application** template
6. Import all `src/*.c` and `src/*.h` files
7. Build the project

### Option C: Build with Makefile (requires mb-gcc in PATH)

```bash
cd 04_vitis_software
make
```

### Output

- ELF file: `build/brain_tumor_seg.elf`

---

## 7. Phase 5 – Test Images

### Convert Phase 1 images

```bash
cd 05_test_images
python convert_to_bin.py --from-phase1
```

### Convert custom images

```bash
python convert_to_bin.py --input my_mri_scan.png
```

### Output

- `bin/*.bin` – raw 256×256 uint8 binary files (65536 bytes each)
- `c_headers/*.h` – C header files with `static const uint8_t` arrays

To use full-size images in the firmware, include the generated headers in `04_vitis_software/src/` and reference them from `main.c`.

---

## 8. Running on Hardware

### Step 1: Connect Nexys A7-100T

1. Connect the Nexys A7-100T via USB to your computer
2. Ensure the power switch is ON
3. Set boot mode jumper to JTAG

### Step 2: Program the FPGA

In Vivado Hardware Manager or via command line:

```tcl
open_hw_manager
connect_hw_server
open_hw_target
set_property PROGRAM.FILE {vivado_project/brain_tumor_soc.runs/impl_1/microblaze_soc_wrapper.bit} [current_hw_device]
program_hw_device
```

### Step 3: Run the software

In Vitis or via XSCT:

```tcl
connect -url tcp:127.0.0.1:3121
target 2
dow build/brain_tumor_seg.elf
run
```

### Step 4: Open serial terminal

Use any serial terminal (PuTTY, Tera Term, or VS Code Serial Monitor):

- **Port:** COMx (check Device Manager)
- **Baud:** 115200
- **Data:** 8-N-1

### Expected serial output

```
========================================
 Brain Tumor Segmentation – FPGA SoC
 Nexys A7-100T / Artix-7 / MicroBlaze
========================================

--- Adaptive Mode Selection ---
  Mean:     42
  Std Dev:  78
  Contrast: 245
  Selected: FAST
-------------------------------
  Threshold:      127
  FG pixels:      3845
  Mode used:      0

=== Watershed Results ===
Regions found: 1
Total foreground pixels: 3845

--- Region 1
  Area:      3845
  Centroid X:128
  Centroid Y:128
  ...

=== Energy & Performance Report ===
  HW cycles:      50000
  SW cycles:      2000000
  Speedup (x10):  400
  Energy savings (%): 99
===================================
```

### LED behaviour

| LED   | State    | Meaning                               |
| ----- | -------- | ------------------------------------- |
| LD0   | Blinking | System alive (heartbeat)              |
| LD1   | ON       | Currently processing                  |
| LD2-3 | Binary   | Mode (00=FAST, 01=NORMAL, 10=CAREFUL) |
| LD4   | ON       | Processing complete                   |

---

## 9. Troubleshooting

### Python phase

| Problem                       | Solution                                |
| ----------------------------- | --------------------------------------- |
| `ModuleNotFoundError: cv2`    | `pip install opencv-python`             |
| Dice score = 0 for all images | Check that `test_images/` has PNG files |
| Low Dice on brain_03          | Expected – brain_03 has no tumor        |

### HLS phase

| Problem               | Solution                                                |
| --------------------- | ------------------------------------------------------- |
| `vitis_hls` not found | Use `vitis-run.bat --tcl` instead (Vitis 2025.1)        |
| Cosim timeout         | Comment out cosim in `run_hls.tcl` (csim is sufficient) |
| Synthesis fails       | Check target part matches `xc7a100tcsg324-1`            |

### Vivado phase

| Problem            | Solution                                         |
| ------------------ | ------------------------------------------------ |
| HLS IP not found   | Unzip IP in `ip_repo/`, run `update_ip_catalog`  |
| Timing not met     | Reduce clock frequency or optimise critical path |
| Board not detected | Install Digilent board files for Vivado          |

### Vitis / Runtime

| Problem               | Solution                                                      |
| --------------------- | ------------------------------------------------------------- |
| No serial output      | Check baud rate = 115200, correct COM port                    |
| LEDs not working      | Verify XDC constraints match Nexys A7 schematic               |
| Program fails to load | Check Hardware Manager connection, re-program bitstream first |
