<div align="center">

# 🧠 FPGA Brain Tumor Segmentation

**Hardware-accelerated medical image segmentation with adaptive intelligence**

[![Board](https://img.shields.io/badge/Board-Nexys%20A7--100T-blue)](#target-platform)
[![FPGA](https://img.shields.io/badge/FPGA-Artix--7%20xc7a100t-purple)](#target-platform)
[![Tools](https://img.shields.io/badge/Tools-Vitis%20%2F%20Vivado%202025.1-orange)](#target-platform)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![HLS](https://img.shields.io/badge/HLS-9%2F9%20tests%20passed-brightgreen)](#hls-synthesis-results)

_Digital System Design Lab — Otsu's thresholding on FPGA with runtime-adaptive processing-mode selection_

---

**5.9× faster** · **95.8% less energy** · **0.98 Dice score** · **Zero manual tuning**

</div>

---

## The Problem

Brain tumor segmentation from MRI scans is a critical step in medical diagnosis. Clinicians need fast, accurate delineation of tumor boundaries — but traditional software running on general-purpose processors is **power-hungry** and **too slow** for real-time edge deployment. Meanwhile, every MRI image is different: some have sharp, high-contrast tumors, while others are noisy and ambiguous. Fixed-parameter systems can't adapt to this.

## The Solution

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

## Results at a Glance

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
| LUT        | 30,969 |    63,400 |     48%     |
| Flip-Flop  | 33,247 |   126,800 |     26%     |
| BRAM (18K) |    168 |       270 |     62%     |
| DSP        |    163 |       240 |     67%     |

---

## Architecture

### System Block Diagram

```
┌──────────────────────────────────────────────────────────┐
│                  Nexys A7-100T  (Artix-7)                │
│                                                          │
│  ┌────────────┐       ┌─────────────┐                    │
│  │ MicroBlaze │◄─AXI─►│  HLS Otsu   │                    │
│  │   (CPU)    │       │ Accelerator │                    │
│  └─────┬──────┘       └──────┬──────┘                    │
│        │                     │                           │
│  ┌─────┴──────┐       ┌──────┴──────┐                    │
│  │  64 KB     │       │  64 KB      │                    │
│  │  BRAM      │       │  Image BRAM │                    │
│  └────────────┘       └─────────────┘                    │
│        │                                                 │
│  ┌─────┴────────────────────────────────┐                │
│  │          AXI Interconnect            │                │
│  └──┬──────────┬──────────┬─────────────┘                │
│     │          │          │                              │
│  ┌──┴───┐  ┌──┴───┐  ┌──┴──────┐  ┌──────┐             │
│  │ UART │  │ GPIO │  │  Timer  │  │ LEDs │             │
│  │115200│  │5-bit │  │ (perf)  │  │ ×5   │             │
│  └──────┘  └──────┘  └─────────┘  └──────┘             │
└──────────────────────────────────────────────────────────┘
```

### Processing Pipeline

```
       ┌─────────────────────────────────────────────────────────────────┐
       │                    HLS Accelerator (FPGA)                       │
       │                                                                 │
Input ─┤  Histogram ──► Otsu Threshold ──► Morphology (mode-dependent)  ├──► Binary mask
       │  (256-bin)     (inter-class var)   (erode / dilate)            │
       └─────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                        ┌───────────────────────┐
                        │  Watershed (MicroBlaze │
                        │  BFS connected-comp.)  │
                        └───────────┬───────────┘
                                    │
                                    ▼
                          Labelled tumour regions
                        (area, centroid, bounding box)
```

---

## Target Platform

| Parameter     | Value                                                    |
| :------------ | :------------------------------------------------------- |
| **Board**     | Digilent Nexys A7-100T                                   |
| **FPGA**      | Xilinx Artix-7 xc7a100tcsg324-1                          |
| **Clock**     | 100 MHz                                                  |
| **Processor** | MicroBlaze (area-optimised, barrel shifter, HW multiply) |
| **Memory**    | 64 KB instruction/data BRAM + 64 KB image BRAM           |
| **Tools**     | Vitis HLS / Vivado / Vitis IDE 2025.1                    |

---

## Project Structure

```
FPGA--Brain-Tumor-Segmentation/
│
├── 01_python_verification/     # Phase 1 — Algorithm validation in Python
│   ├── generate_test_images.py #   Synthetic 256×256 MRI generator
│   ├── otsu_watershed.py       #   Otsu + watershed reference implementation
│   ├── verify_results.py       #   Dice / IoU accuracy metrics
│   └── run_all_tests.py        #   End-to-end test runner
│
├── 02_hls_accelerator/         # Phase 2 — Vitis HLS IP core
│   ├── otsu_threshold.cpp/h    #   HLS Otsu (pipelined, integer-only)
│   ├── image_stats.cpp/h       #   Adaptive mode selection logic
│   ├── test_otsu.cpp           #   C-simulation testbench (9 tests)
│   └── run_hls.tcl             #   Synthesis → export automation
│
├── 03_vivado_hardware/         # Phase 3 — Vivado SoC integration
│   ├── srcs/verilog/           #   top_module · axi_interface · bram_controller
│   ├── constraints/artix7.xdc  #   Nexys A7 pin assignments
│   ├── ip_repo/                #   HLS IP drop-in folder
│   └── build.tcl               #   Automated bitstream generation
│
├── 04_vitis_software/          # Phase 4 — MicroBlaze bare-metal firmware
│   └── src/
│       ├── main.c              #   Control loop: load → mode → HLS → watershed
│       ├── watershed.c/h       #   BFS connected-component labelling
│       ├── adaptive_controller.c/h  #  Runtime mode selection (novelty)
│       ├── energy_analyzer.c/h #   Timer-based HW vs SW comparison
│       ├── image_loader.c/h    #   BRAM transfer helpers
│       └── uart_debug.c/h      #   Polled UART output
│
├── 05_test_images/             # Phase 5 — Image conversion utilities
│   ├── convert_to_bin.py       #   PNG → .bin + .h converter
│   ├── bin/                    #   Raw 65,536-byte images
│   └── c_headers/              #   C arrays for MicroBlaze embedding
│
├── 06_documentation/           # Reports, slides, results
│   ├── project_report.md
│   ├── user_manual.md
│   ├── results.txt
│   ├── presentation.pptx
│   └── presentation_outline.md
│
└── docs/prd.md                 # Product requirements document
```

---

## Getting Started

### Prerequisites

| Tool             | Version | Purpose                 |
| :--------------- | :------ | :---------------------- |
| Python           | 3.8+    | Algorithm verification  |
| NumPy            | ≥ 1.24  | Array operations        |
| OpenCV (cv2)     | ≥ 4.7   | Image I/O & processing  |
| Vitis HLS        | 2025.1  | C++ → RTL synthesis     |
| Vivado           | 2025.1  | FPGA design & bitstream |
| Vitis IDE        | 2025.1  | MicroBlaze firmware     |
| g++ _(optional)_ | Any     | Desktop HLS testbench   |

### Phase 1 — Python Verification

Validate that the algorithm produces correct results before touching hardware.

```bash
cd 01_python_verification
pip install -r requirements.txt
python run_all_tests.py          # Generates images, segments, computes Dice/IoU
```

Expected output: Dice ≥ 0.98 for brain_01 and brain_02; low score for brain_03 (correct — no tumor).

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

Output: `.bit` bitstream + `.xsa` hardware specification for Vitis.

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

---

## HLS Synthesis Results

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

## LED Status Indicators

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

## Documentation

| Document                                                 | Description                                                     |
| :------------------------------------------------------- | :-------------------------------------------------------------- |
| [Project Report](06_documentation/project_report.md)     | Full technical write-up (architecture, implementation, results) |
| [User Manual](06_documentation/user_manual.md)           | Step-by-step build and deployment guide                         |
| [Results Summary](06_documentation/results.txt)          | Raw performance and accuracy data                               |
| [Presentation](06_documentation/presentation_outline.md) | Slide deck outline                                              |
| [PRD](docs/prd.md)                                       | Product requirements and project flow                           |

---

## References

1. N. Otsu, "A Threshold Selection Method from Gray-Level Histograms," _IEEE Trans. Systems, Man, and Cybernetics_, vol. 9, no. 1, pp. 62–66, 1979.
2. Xilinx, _Vitis HLS User Guide (UG1399)_, v2025.1.
3. Xilinx, _MicroBlaze Processor Reference Guide (UG984)_.
4. Digilent, _Nexys A7 Reference Manual_.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

<div align="center">
<sub>Built with Vitis HLS, Vivado, and a lot of pragma directives.</sub>
</div>
