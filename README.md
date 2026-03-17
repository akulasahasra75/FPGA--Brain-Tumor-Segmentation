<div align="center">

# 🧠 FPGA Brain Tumor Segmentation

**Hardware-accelerated medical image segmentation with runtime-adaptive intelligence**

[![Board](https://img.shields.io/badge/Board-Nexys%20A7--100T-blue?style=for-the-badge)](#-target-platform)
[![FPGA](https://img.shields.io/badge/FPGA-Artix--7%20xc7a100t-purple?style=for-the-badge)](#-target-platform)
[![Tools](https://img.shields.io/badge/Xilinx-Vitis%20%2F%20Vivado%202025.1-orange?style=for-the-badge)](#-target-platform)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![HLS](https://img.shields.io/badge/HLS-9%2F9%20tests%20passed-brightgreen?style=for-the-badge)](#-hls-synthesis-results)
[![Python](https://img.shields.io/badge/Python-3.8+-3776AB?style=for-the-badge&logo=python&logoColor=white)](#prerequisites)
[![C++](https://img.shields.io/badge/C++-11-00599C?style=for-the-badge&logo=cplusplus&logoColor=white)](#phase-2--hls-synthesis)

<br/>

_Digital System Design Lab — Otsu's thresholding on FPGA with runtime-adaptive processing-mode selection_

<br/>

| 🚀 **5.9× faster** | ⚡ **95.8% less energy** | 🎯 **0.98 Dice score** | 🔧 **Zero manual tuning** |
| :-: | :-: | :-: | :-: |

</div>

---

## 📑 Table of Contents

- [Introduction](#-introduction)
- [Features](#-features)
- [Tech Stack](#-tech-stack)
- [Target Platform](#-target-platform)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Getting Started](#-getting-started)
  - [Prerequisites](#prerequisites)
  - [Phase 1 — Python Verification](#phase-1--python-verification)
  - [Phase 2 — HLS Synthesis](#phase-2--hls-synthesis)
  - [Phase 3 — Vivado Build](#phase-3--vivado-build)
  - [Phase 4 — Vitis Software](#phase-4--vitis-software)
  - [Phase 5 — Test Image Conversion](#phase-5--test-image-conversion)
- [Usage Examples](#-usage-examples)
- [Results](#-results)
- [HLS Synthesis Results](#-hls-synthesis-results)
- [Configuration](#%EF%B8%8F-configuration)
- [LED Status Indicators](#-led-status-indicators)
- [Screenshots & Demo](#-screenshots--demo)
- [Documentation](#-documentation)
- [Roadmap](#-roadmap)
- [Contributing](#-contributing)
- [References](#-references)
- [License](#-license)
- [Authors & Credits](#-authors--credits)

---

## 🧩 Introduction

Brain tumor segmentation from MRI scans is a critical step in medical diagnosis. Clinicians need fast, accurate delineation of tumor boundaries — but traditional software running on general-purpose processors is **power-hungry** and **too slow** for real-time edge deployment. Meanwhile, every MRI image is different: some have sharp, high-contrast tumors, while others are noisy and ambiguous. Fixed-parameter systems can't adapt to this variation.

This project implements a **complete brain tumor segmentation pipeline on an FPGA** (Artix-7). A 256×256 grayscale MRI image goes in; labelled tumor regions with area, centroid, and bounding box come out — all on a single chip, with no manual tuning.

```
MRI Image ──► Image Stats ──► Mode Select ──► Otsu Threshold ──► Morphology ──► Watershed ──► Tumour Regions
               (1 pass)      (automatic)       (HLS accel.)     (adaptive)      (CPU)        (labelled)
```

### What Makes It Unique — Adaptive Processing Mode Selection

Unlike fixed-configuration accelerators, the system **analyses each image at runtime** (mean, standard deviation, contrast) in a single pass and **automatically selects** the optimal processing strategy:

| Image Condition        |    Mode     | What Happens                                | Why                                     |
| :--------------------- | :---------: | :------------------------------------------ | :-------------------------------------- |
| Contrast ≥ 150, σ ≥ 50 |  **FAST**   | Minimal post-processing                     | Clear tumor — speed matters most        |
| Contrast ≥ 80, σ ≥ 25  | **NORMAL**  | Standard Otsu + light morphological cleanup | Balanced quality and speed              |
| Low contrast / noisy   | **CAREFUL** | Adaptive threshold + full morph cleanup     | Difficult image — accuracy matters most |

> **No knobs, no parameters, no manual intervention.** The hardware decides.

---

## ✨ Features

- **Hardware-Accelerated Otsu Thresholding** — Pipelined HLS IP core with `II=1` on critical loops; zero floating-point arithmetic
- **Runtime-Adaptive Mode Selection** — Automatic FAST / NORMAL / CAREFUL processing based on per-image statistics (mean, σ, contrast)
- **Full Segmentation Pipeline** — Histogram → Otsu → Morphology → Watershed (BFS connected-component labelling) → Labelled tumor regions
- **Quantitative Output** — Each detected region reports area (pixels), centroid (x, y), and bounding box
- **5.9× Speedup** over software-only MicroBlaze execution, with **95.8% energy savings**
- **0.98 Dice Score** on high-contrast MRI test images with correct rejection of tumor-free scans
- **LED Feedback** — 5 on-board LEDs display heartbeat, processing status, mode, and completion
- **UART Debug Console** — Real-time telemetry at 115200 baud (mode selected, threshold, timing, energy)
- **Fully Scripted Build** — TCL automation for HLS synthesis, Vivado bitstream, and FPGA programming
- **Python Verification Suite** — End-to-end golden-model testing with Dice/IoU metrics before touching hardware
- **Desktop Simulation** — Both C++ HLS testbench and `gcc -DDESKTOP_SIM` firmware syntax check work without FPGA tools

---

## 🛠 Tech Stack

| Layer              | Technology                                     | Purpose                                 |
| :----------------- | :--------------------------------------------- | :-------------------------------------- |
| **Algorithm**      | Python 3.8+, NumPy, OpenCV                     | Golden-model verification & test images |
| **HLS**            | Vitis HLS 2025.1, C++11                        | Otsu IP core synthesis (C++ → RTL)      |
| **Hardware**       | Vivado 2025.1, Verilog, XDC constraints        | SoC integration & bitstream generation  |
| **Firmware**       | Vitis IDE 2025.1, C (bare-metal)               | MicroBlaze application & watershed      |
| **Processor**      | Xilinx MicroBlaze soft-core (32-bit RISC)      | Control flow & post-processing          |
| **Communication**  | AXI4-Lite interconnect, UART (115200 baud)     | IP ↔ CPU bus, debug console             |
| **Board**          | Digilent Nexys A7-100T (Artix-7 xc7a100t)     | Target deployment platform              |

---

## 🎯 Target Platform

| Parameter     | Value                                                    |
| :------------ | :------------------------------------------------------- |
| **Board**     | Digilent Nexys A7-100T                                   |
| **FPGA**      | Xilinx Artix-7 xc7a100tcsg324-1                          |
| **Clock**     | 100 MHz                                                  |
| **Processor** | MicroBlaze (area-optimised, barrel shifter, HW multiply) |
| **Memory**    | 64 KB instruction/data BRAM + 64 KB image BRAM           |
| **Tools**     | Vitis HLS / Vivado / Vitis IDE 2025.1                    |

---

## 🏗 Architecture

### System Block Diagram

```
┌─────────────────────────────────────────────────────────┐
│                 Nexys A7-100T  (Artix-7)                │
│                                                         │
│          ┌────────────┐       ┌─────────────┐           │
│          │ MicroBlaze │◄─AXI─►│  HLS Otsu   │           │
│          │   (CPU)    │       │ Accelerator │           │
│          └─────┬──────┘       └──────┬──────┘           │
│                │                     │                  │
│          ┌─────┴──────┐       ┌──────┴──────┐           │
│          │  64 KB     │       │  64 KB      │           │
│          │  BRAM      │       │  Image BRAM │           │
│          └────────────┘       └─────────────┘           │
│                │                                        │
│          ┌─────┴───────────────────────────────┐        │
│          │         AXI Interconnect            │        │
│          └──┬──────────┬──────────┬────────────┘        │
│             │          │          │                     │
│          ┌──┴───┐   ┌──┴───┐   ┌──┴──────┐  ┌──────┐    │
│          │ UART │   │ GPIO │   │  Timer  │  │ LEDs │    │
│          │115200│   │5-bit │   │ (perf)  │  │ ×5   │    │
│          └──────┘   └──────┘   └─────────┘  └──────┘    │
└─────────────────────────────────────────────────────────┘
```

### Processing Pipeline

```
       ┌────────────────────────────────────────────────────────────────┐
       │                    HLS Accelerator (FPGA)                      │
       │                                                                │
Input ─┤  Histogram ──► Otsu Threshold ──► Morphology (mode-dependent)  ├──► Binary mask
       │  (256-bin)     (inter-class var)   (erode / dilate)            │
       └────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        ┌──────────────────────┐
                        │ Watershed (MicroBlaze│
                        │ BFS connected-comp.) │
                        └──────────┬───────────┘
                                   │
                                   ▼
                         Labelled tumour regions
                       (area, centroid, bounding box)
```

### HLS IP Register Interface

The `otsu_threshold_top` IP core is controlled via AXI4-Lite registers:

| Offset | Register        | R/W | Description                                           |
| :----: | :-------------- | :-: | :---------------------------------------------------- |
| `0x00` | `AP_CTRL`       | R/W | Control register (`ap_start`, `ap_done`, `ap_idle`)   |
| `0x10` | `image_in`      |  W  | Base address of 256×256 input image in BRAM            |
| `0x18` | `image_out`     |  W  | Base address for binary output mask                   |
| `0x20` | `processing_mode` | W | Mode override: `0` = FAST, `1` = NORMAL, `2` = CAREFUL |
| `0x28` | `threshold`     |  R  | Computed Otsu threshold value (0–255)                 |
| `0x30` | `num_regions`   |  R  | Number of detected foreground regions                 |

<sub>Register offsets derived from HLS-generated driver header (`xotsu_threshold_top_hw.h`).</sub>

---

## 📁 Project Structure

```
FPGA--Brain-Tumor-Segmentation/
│
├── 01_python_verification/        # Phase 1 — Algorithm validation in Python
│   ├── requirements.txt           #   Python dependencies (numpy, opencv-python)
│   ├── generate_test_images.py    #   Synthetic 256×256 MRI generator (3 images)
│   ├── otsu_watershed.py          #   Otsu + watershed reference implementation
│   ├── verify_results.py          #   Dice / IoU accuracy metrics
│   └── run_all_tests.py           #   End-to-end orchestrator
│
├── 02_hls_accelerator/            # Phase 2 — Vitis HLS IP core
│   ├── otsu_threshold.cpp/h       #   HLS Otsu (pipelined, integer-only, 3 modes)
│   ├── image_stats.cpp/h          #   Adaptive mode selection logic
│   ├── test_otsu.cpp              #   C-simulation testbench (9 test vectors)
│   └── run_hls.tcl                #   Synthesis → C-sim → IP export automation
│
├── 03_vivado_hardware/            # Phase 3 — Vivado SoC integration
│   ├── srcs/verilog/              #   top_module · axi_interface · bram_controller
│   ├── constraints/artix7.xdc    #   Nexys A7 pin assignments & timing
│   ├── ip_repo/                   #   HLS IP drop-in (VHDL/Verilog + drivers)
│   ├── build.tcl                  #   Automated synthesis & bitstream generation
│   └── program_fpga.tcl           #   Bitstream programming script
│
├── 04_vitis_software/             # Phase 4 — MicroBlaze bare-metal firmware
│   ├── Makefile                   #   Build automation
│   ├── create_vitis_project.tcl   #   Vitis workspace setup
│   └── src/
│       ├── main.c                 #   Control loop: load → stats → HLS → watershed
│       ├── watershed.c/h          #   BFS connected-component labelling
│       ├── adaptive_controller.c/h #  Runtime mode selection (novelty)
│       ├── energy_analyzer.c/h    #   Timer-based HW vs SW energy comparison
│       ├── image_loader.c/h       #   BRAM transfer helpers
│       ├── uart_debug.c/h         #   Polled UART output (115200 baud)
│       ├── platform_config.h      #   Hardware base addresses & constants
│       └── test_images.h          #   Embedded C arrays (auto-generated)
│
├── 05_test_images/                # Phase 5 — Image conversion utilities
│   ├── convert_to_bin.py          #   PNG → .bin + .h converter
│   ├── input/                     #   Source PNG images
│   ├── bin/                       #   Raw 65,536-byte binary images
│   └── c_headers/                 #   C arrays for MicroBlaze embedding
│
├── 06_documentation/              # Reports, slides, results
│   ├── project_report.md          #   Full technical write-up
│   ├── user_manual.md             #   Step-by-step deployment guide
│   ├── results.txt                #   Raw performance & accuracy data
│   ├── presentation.pptx          #   Slide deck
│   ├── presentation_outline.md    #   Slide structure
│   └── generate_pptx.py           #   Auto-generate slides from outline
│
├── docs/prd.md                    # Product requirements document
├── LICENSE                        # MIT License
└── README.md                      # ← You are here
```

---

## 🚀 Getting Started

### Prerequisites

| Tool             | Version | Purpose                        | Required? |
| :--------------- | :------ | :----------------------------- | :-------: |
| Python           | 3.8+    | Algorithm verification         |    Yes    |
| NumPy            | ≥ 1.24  | Array operations               |    Yes    |
| OpenCV (cv2)     | ≥ 4.7   | Image I/O & processing         |    Yes    |
| Vitis HLS        | 2025.1  | C++ → RTL synthesis            | Phase 2+  |
| Vivado           | 2025.1  | FPGA design & bitstream        | Phase 3+  |
| Vitis IDE        | 2025.1  | MicroBlaze firmware            | Phase 4+  |
| g++              | Any     | Desktop HLS testbench          |  Optional |
| gcc              | Any     | Desktop firmware syntax check  |  Optional |

> **💡 Tip:** You can run Phases 1–2 (Python verification + desktop C-simulation) without any FPGA hardware or Xilinx tools installed.

### Phase 1 — Python Verification

Validate that the algorithm produces correct results before touching hardware.

```bash
cd 01_python_verification
pip install -r requirements.txt
python run_all_tests.py          # Generates images, segments, computes Dice/IoU
```

**Expected output:**

```
brain_01 (high-contrast tumor):  Dice = 0.98, IoU = 0.96  ✓
brain_02 (medium-contrast tumor): Dice = 0.98, IoU = 0.97  ✓
brain_03 (no tumor present):      Dice = 0.19, IoU = 0.10  ✓ (correct rejection)
```

### Phase 2 — HLS Synthesis

Build the Otsu accelerator IP core.

```bash
cd 02_hls_accelerator

# Option A: Desktop C-simulation (fast, no FPGA tools needed)
g++ -o test_otsu test_otsu.cpp otsu_threshold.cpp image_stats.cpp -std=c++11
./test_otsu                      # 9/9 tests should pass

# Option B: Full HLS synthesis → IP export (requires Vitis 2025.1)
vitis-run --tcl --input_file run_hls.tcl
```

### Phase 3 — Vivado Build

Assemble the SoC and generate a bitstream.

```bash
cd 03_vivado_hardware

# 1. Copy the exported HLS IP (.zip) into ip_repo/
# 2. Run the automated build:
vivado -mode batch -source build.tcl
```

**Output:** `.bit` bitstream + `.xsa` hardware specification for Vitis.

### Phase 4 — Vitis Software

Compile the MicroBlaze firmware.

```bash
cd 04_vitis_software

# Desktop syntax check (no FPGA tools needed):
gcc -Wall -O2 -DDESKTOP_SIM -fsyntax-only src/*.c

# Full build: import the .xsa into Vitis IDE and build as a bare-metal application.
```

### Phase 5 — Test Image Conversion

Convert Phase 1 PNG images to binary and C-header formats.

```bash
cd 05_test_images
python convert_to_bin.py --from-phase1
```

**Output:** Binary files in `bin/` and C header arrays in `c_headers/` ready for MicroBlaze embedding.

---

## 💻 Usage Examples

### Running the Full Pipeline on Hardware

Once the bitstream is programmed and firmware is loaded:

```
1. Power on Nexys A7-100T → LD0 (heartbeat) starts blinking
2. System automatically processes embedded test images
3. UART console (115200 baud) prints real-time telemetry:
```

**Sample UART output:**

```
=== FPGA Brain Tumor Segmentation ===
Image: brain_01 (256x256)
  Stats: mean=127, stddev=62, contrast=185
  Mode selected: FAST
  Otsu threshold: 142
  HLS execution: 3.28 ms (328,254 cycles)
  Regions found: 1
    Region 0: area=8432 px, centroid=(131, 118), bbox=[98,82 → 164,154]
  Energy: 169 µJ (vs 4,000 µJ SW-only → 95.8% savings)
  LED state: LD4=ON (done)
```

### Desktop-Only Quick Start (No FPGA Required)

```bash
# Clone and verify the algorithm
git clone https://github.com/akulasahasra75/FPGA--Brain-Tumor-Segmentation.git
cd FPGA--Brain-Tumor-Segmentation

# Phase 1: Python golden model
cd 01_python_verification
pip install -r requirements.txt
python run_all_tests.py

# Phase 2: C++ simulation
cd ../02_hls_accelerator
g++ -o test_otsu test_otsu.cpp otsu_threshold.cpp image_stats.cpp -std=c++11
./test_otsu
```

### Adding Your Own MRI Image

```bash
# 1. Place your 256×256 grayscale PNG in 05_test_images/input/
cp my_scan.png 05_test_images/input/

# 2. Convert to binary + C header
cd 05_test_images
python convert_to_bin.py --input input/my_scan.png

# 3. Include the generated header in firmware
#    → c_headers/my_scan.h is auto-generated
#    → Add #include "my_scan.h" in 04_vitis_software/src/test_images.h
```

---

## 📊 Results

### Performance: HW-Accelerated vs Software-Only

| Metric              | SW-only (MicroBlaze) |         HW-accelerated         |      Improvement       |
| :------------------ | :------------------: | :----------------------------: | :--------------------: |
| Otsu execution time |        ~20 ms        | ~3.4 ms (best) / ~5.6 ms (avg) | **5.9×** / 3.6× faster |
| Dynamic power       |       ~200 mW        |             ~50 mW             |      **4× lower**      |
| Energy per image    |      ~4,000 µJ       | ~169 µJ (best) / ~281 µJ (avg) |   **95.8% savings**    |
| Processing mode     |        Fixed         |      Adaptive (automatic)      |    No tuning needed    |

<sub>HW latency from Vitis HLS csynth report (328,254 – 788,308 cycles @ 100 MHz). Power figures are estimates pending post-implementation Vivado power analysis.</sub>

### Segmentation Accuracy

| Test Image                               | Dice Score | IoU  | Mode Selected | Verdict              |
| :--------------------------------------- | :--------: | :--: | :-----------: | :------------------- |
| brain_01 — bright, high-contrast tumor   |    0.98    | 0.96 |     FAST      | ✅ Excellent         |
| brain_02 — subtle, medium-contrast tumor |    0.98    | 0.97 |    NORMAL     | ✅ Excellent         |
| brain_03 — no tumor present              |    0.19    | 0.10 |    CAREFUL    | ✅ Correct rejection |

### FPGA Resource Utilisation (HLS IP Core)

| Resource   |   Used | Available | Utilisation |
| :--------- | -----: | --------: | :---------: |
| LUT        | 30,969 |    63,400 |   **48%**   |
| Flip-Flop  | 33,247 |   126,800 |   **26%**   |
| BRAM (18K) |    168 |       270 |   **62%**   |
| DSP        |    163 |       240 |   **67%**   |

---

## 🧪 HLS Synthesis Results

All **9 test vectors** (3 images × 3 modes) pass C-simulation:

| Step         |  Status   | Duration |
| :----------- | :-------: | -------: |
| C Simulation | ✅ PASSED |     ~5 s |
| C Synthesis  | ✅ PASSED |    ~38 s |
| IP Export    | ✅ PASSED |    ~18 s |

**Key HLS optimisations:**

- `#pragma HLS PIPELINE II=1` on histogram accumulation and threshold loops
- Array partitioning on the 256-bin histogram for parallel access
- Overflow-safe Otsu computation using integer-divided means (no 64-bit overflow)
- Newton's method integer square root — **zero floating-point usage**

---

## ⚙️ Configuration

### Hardware Base Addresses (`platform_config.h`)

| Peripheral       | Base Address   | Description                    |
| :--------------- | :------------- | :----------------------------- |
| UART             | `0x40600000`   | Debug console (115200 baud)    |
| GPIO (LEDs)      | `0x40000000`   | 5-bit LED output               |
| AXI Timer        | `0x41C00000`   | Performance counter            |
| HLS Otsu IP      | `0x44A00000`   | Accelerator control registers  |
| Image BRAM       | `0xC0000000`   | 64 KB image buffer             |

<sub>Addresses are defined in the Vivado block design and exported via the `.xsa` file. The values above are representative — actual addresses depend on your Vivado build.</sub>

### Processing Mode Thresholds (`adaptive_controller.c`)

| Parameter           | Value | Description                          |
| :------------------ | ----: | :----------------------------------- |
| `FAST_CONTRAST_MIN` |   150 | Minimum contrast for FAST mode       |
| `FAST_STDDEV_MIN`   |    50 | Minimum σ for FAST mode              |
| `NORM_CONTRAST_MIN` |    80 | Minimum contrast for NORMAL mode     |
| `NORM_STDDEV_MIN`   |    25 | Minimum σ for NORMAL mode            |
| `MORPH_KERNEL_SIZE` |     3 | Structuring element size (3×3)       |

### Image Parameters

| Parameter          | Value        | Defined In               |
| :----------------- | :----------- | :----------------------- |
| Image width        | 256 px       | `otsu_threshold.h`       |
| Image height       | 256 px       | `otsu_threshold.h`       |
| Pixel depth        | 8-bit (0–255)| `otsu_threshold.h`       |
| Histogram bins     | 256          | `otsu_threshold.h`       |
| Total image size   | 65,536 bytes | Derived (256 × 256 × 1) |

---

## 💡 LED Status Indicators

On-board LEDs provide real-time processing feedback:

| LED | Signal     | Meaning                               |
| :-: | :--------- | :------------------------------------ |
| LD0 | Heartbeat  | Blinks continuously — system is alive |
| LD1 | Processing | ON during HLS execution               |
| LD2 | Mode\[0\]  | Processing mode bit 0                 |
| LD3 | Mode\[1\]  | Processing mode bit 1                 |
| LD4 | Done       | ON after segmentation is complete     |

Mode encoding: **FAST** = `00` · **NORMAL** = `01` · **CAREFUL** = `10`

---

## 🖼 Screenshots & Demo

> **📸 Placeholder** — Add screenshots or terminal recordings here as the project progresses.

<table>
  <tr>
    <td align="center"><strong>Input MRI</strong></td>
    <td align="center"><strong>Otsu Binary Mask</strong></td>
    <td align="center"><strong>Watershed Labels</strong></td>
  </tr>
  <tr>
    <td align="center"><em>brain_01.png</em></td>
    <td align="center"><em>otsu_output.png</em></td>
    <td align="center"><em>watershed_labels.png</em></td>
  </tr>
</table>

<!-- Uncomment and replace with actual paths once images are available:
<table>
  <tr>
    <td><img src="05_test_images/input/brain_01.png" width="200"/></td>
    <td><img src="06_documentation/screenshots/otsu_output.png" width="200"/></td>
    <td><img src="06_documentation/screenshots/watershed_labels.png" width="200"/></td>
  </tr>
</table>
-->

**Expected UART console output:**

```
=== FPGA Brain Tumor Segmentation v1.0 ===
Processing 3 test images...

[1/3] brain_01: mode=FAST  threshold=142  time=3.28ms  regions=1  ✓
[2/3] brain_02: mode=NORMAL threshold=118  time=5.61ms  regions=1  ✓
[3/3] brain_03: mode=CAREFUL threshold=87  time=7.88ms  regions=0  ✓

Summary: 3/3 images processed. HW avg speedup: 3.6×
```

---

## 📚 Documentation

| Document                                                 | Description                                                     |
| :------------------------------------------------------- | :-------------------------------------------------------------- |
| [Project Report](06_documentation/project_report.md)     | Full technical write-up (architecture, implementation, results) |
| [User Manual](06_documentation/user_manual.md)           | Step-by-step build and deployment guide                         |
| [Results Summary](06_documentation/results.txt)          | Raw performance and accuracy data                               |
| [Presentation](06_documentation/presentation_outline.md) | Slide deck outline                                              |
| [PRD](docs/prd.md)                                       | Product requirements and project flow                           |

---

## 🗺 Roadmap

- [x] Phase 1 — Python algorithm verification (Otsu + watershed)
- [x] Phase 2 — HLS C++ IP core with 3 adaptive modes
- [x] Phase 3 — Vivado SoC integration (MicroBlaze + HLS IP)
- [x] Phase 4 — MicroBlaze firmware with UART telemetry
- [x] Phase 5 — Test image pipeline (PNG → binary → C headers)
- [x] Phase 6 — Documentation and presentation
- [ ] Post-implementation Vivado power analysis (replace estimated power figures)
- [ ] Real MRI dataset validation (BraTS challenge images)
- [ ] DMA-based image transfer (eliminate CPU-mediated BRAM copies)
- [ ] Multi-threshold support (hierarchical Otsu for multi-class segmentation)
- [ ] On-board display output (VGA/HDMI overlay of segmentation results)
- [ ] Larger image support (512×512) via tiled processing or external DDR memory

---

## 🤝 Contributing

Contributions are welcome! Whether it's a bug fix, new feature, or documentation improvement — all PRs are appreciated.

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/my-improvement`)
3. **Commit** your changes (`git commit -m "Add: description of change"`)
4. **Push** to your branch (`git push origin feature/my-improvement`)
5. **Open** a Pull Request

### Guidelines

- Follow the existing project structure (phases `01_` through `06_`)
- Ensure HLS C-simulation passes (`9/9 tests`) before submitting HLS changes
- Run `python run_all_tests.py` to validate Python changes
- Update documentation if your change affects usage or architecture

---

## 📖 References

1. N. Otsu, "A Threshold Selection Method from Gray-Level Histograms," _IEEE Trans. Systems, Man, and Cybernetics_, vol. 9, no. 1, pp. 62–66, 1979.
2. Xilinx, _Vitis HLS User Guide (UG1399)_, v2025.1.
3. Xilinx, _MicroBlaze Processor Reference Guide (UG984)_.
4. Digilent, _Nexys A7 Reference Manual_.

---

## 📄 License

This project is licensed under the [MIT License](LICENSE).

```
MIT License — Copyright (c) 2026 akulasahasra75
```

---

## 👥 Authors & Credits

| Name                    | GitHub                                                         | Email                          |
| :---------------------- | :------------------------------------------------------------- | :----------------------------- |
| **Arushi Pundir**       | [@arushipundir126](https://github.com/arushipundir126)         | arushipundir097@gmail.com      |
| **Aneesh Venkatesha Rao** | [@AneeshVRao](https://github.com/AneeshVRao)                | aneeshvrao2017@gmail.com       |
| **Akula Sahasra**       | [@akulasahasra75](https://github.com/akulasahasra75)           | akulasahasra0705@gmail.com     |

> Digital System Design Lab Project — FPGA-based Brain Tumor Segmentation with Adaptive Processing

---

<div align="center">

**⭐ If you found this project useful, consider giving it a star!**

<sub>Built with Vitis HLS, Vivado, and a lot of pragma directives.</sub>

</div>
