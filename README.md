# FPGA Brain Tumor Segmentation

> **Digital System Design Lab** – FPGA-accelerated brain tumor segmentation using Otsu's thresholding with adaptive processing-mode selection.

## Overview

This project implements a complete **brain tumor segmentation pipeline on an FPGA** (Artix-7, Nexys A7-100T board). A grayscale MRI image is segmented using Otsu's thresholding (hardware-accelerated via Vitis HLS) followed by connected-component watershed analysis on a MicroBlaze soft-processor.

### Novelty – Adaptive Processing Mode Selection

The system analyses image statistics (mean, standard deviation, contrast) at runtime and automatically selects one of three processing modes:

| Condition               | Mode        | Behaviour                                   |
| ----------------------- | ----------- | ------------------------------------------- |
| High contrast & std dev | **FAST**    | Minimal post-processing, max throughput     |
| Medium contrast         | **NORMAL**  | Standard Otsu + light morphological cleanup |
| Low contrast / noisy    | **CAREFUL** | Adaptive threshold + full cleanup           |

No manual parameter tuning is required.

## Target

| Parameter | Value                       |
| --------- | --------------------------- |
| Board     | Digilent Nexys A7-100T      |
| FPGA      | Artix-7 xc7a100tcsg324-1    |
| Clock     | 100 MHz                     |
| Processor | MicroBlaze (area-optimised) |
| Tools     | Vitis / Vivado 2025.1       |

## Project Structure

```
├── 01_python_verification/   Python algorithm validation
├── 02_hls_accelerator/       Vitis HLS Otsu IP core
├── 03_vivado_hardware/       Vivado SoC (MicroBlaze + HLS IP)
├── 04_vitis_software/        MicroBlaze bare-metal firmware
├── 05_test_images/           Image converter (PNG → bin / C headers)
├── 06_documentation/         Project report, user manual, results
└── docs/prd.md               Product requirements document
```

## Quick Start

### Phase 1 – Python Verification

```bash
cd 01_python_verification
pip install -r requirements.txt
python run_all_tests.py
```

### Phase 2 – HLS Synthesis

```bash
cd 02_hls_accelerator
# Desktop test:
g++ -o test_otsu test_otsu.cpp otsu_threshold.cpp image_stats.cpp -std=c++11
./test_otsu

# HLS synthesis (Vitis 2025.1):
vitis-run --tcl --input_file run_hls.tcl
```

### Phase 3 – Vivado Build

```bash
cd 03_vivado_hardware
# Copy HLS IP to ip_repo/ first
vivado -mode batch -source build.tcl
```

### Phase 4 – Vitis Software

```bash
cd 04_vitis_software
# Syntax check:
gcc -Wall -O2 -DDESKTOP_SIM -fsyntax-only src/*.c
# Or build with Vitis IDE using the .xsa from Phase 3
```

### Phase 5 – Test Images

```bash
cd 05_test_images
python convert_to_bin.py --from-phase1
```

## Results

| Metric    | SW-only (MicroBlaze) | HW-accelerated | Improvement  |
| --------- | -------------------- | -------------- | ------------ |
| Otsu time | ~20 ms               | ~0.5 ms        | ~40×         |
| Power     | ~200 mW              | ~50 mW         | 4× lower     |
| Energy    | ~4,000 µJ            | ~25 µJ         | >99% savings |

| Test Image              | Dice Score | Mode Selected |
| ----------------------- | ---------- | ------------- |
| brain_01 (bright tumor) | 0.98       | FAST          |
| brain_02 (subtle tumor) | 0.98       | NORMAL        |
| brain_03 (no tumor)     | 0.19       | CAREFUL       |

## Documentation

- [Project Report](06_documentation/project_report.md)
- [User Manual](06_documentation/user_manual.md)
- [Results Summary](06_documentation/results.txt)
- [Presentation Outline](06_documentation/presentation_outline.md)

## License

See [LICENSE](LICENSE).
