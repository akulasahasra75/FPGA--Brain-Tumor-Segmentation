# 📚 Documentation Index

Welcome to the FPGA Brain Tumor Segmentation project documentation!

## 🚀 Quick Start

**New to the project?** Start here:

1. Read [`WORKFLOW.md`](WORKFLOW.md) - Complete A-Z beginner's guide
2. Follow the 6-step process
3. Program your FPGA and see results!

**Need quick reference?** Check [`SUMMARY.md`](SUMMARY.md)

---

## 📖 Documentation Files

### For Users

| File                           | Description                                      | When to Read                 |
| ------------------------------ | ------------------------------------------------ | ---------------------------- |
| **[WORKFLOW.md](WORKFLOW.md)** | Complete step-by-step guide from start to finish | First time using the project |
| **[SUMMARY.md](SUMMARY.md)**   | Quick reference and troubleshooting              | When you need a reminder     |
| **[prd.md](prd.md)**           | Product Requirements Document                    | Understanding project goals  |
| **[nexys.md](nexys.md)**       | Nexys board details and pin assignments          | Hardware debugging           |

### In Other Folders

| Location                  | File        | Description                                             |
| ------------------------- | ----------- | ------------------------------------------------------- |
| `../`                     | `README.md` | Main project page (overview, architecture, performance) |
| `01_python_verification/` | `README.md` | Python setup and algorithm verification                 |
| `02_hls_accelerator/`     | `README.md` | HLS synthesis and IP core generation                    |
| `03_vivado_hardware/`     | `README.md` | FPGA hardware platform build                            |
| `04_vitis_software/`      | `README.md` | MicroBlaze firmware and Vitis 2025.1 notes              |
| `05_test_images/`         | `README.md` | Test image formats and structure                        |
| `06_documentation/`       | `README.md` | Documentation archive index                             |

---

## 🎯 Documentation by Purpose

### "I want to build the project"

→ **Start:** [`WORKFLOW.md`](WORKFLOW.md)
→ **Reference:** [`SUMMARY.md`](SUMMARY.md)

### "I want to understand the hardware"

→ **Architecture:** `../README.md` (System Architecture section)
→ **Board details:** [`nexys.md`](nexys.md)
→ **Vivado build:** `../03_vivado_hardware/README.md`

### "I want to understand the algorithm"

→ **Overview:** `../README.md` (How It Works section)
→ **Python code:** `../01_python_verification/README.md`
→ **HLS implementation:** `../02_hls_accelerator/README.md`

### "I'm having problems"

→ **Troubleshooting:** [`WORKFLOW.md`](WORKFLOW.md) → Troubleshooting section
→ **Vitis 2025.1 issue:** `../04_vitis_software/README.md`

### "I want to know the project requirements"

→ **Product specs:** [`prd.md`](prd.md)
→ **Performance goals:** `../README.md` (Performance Results section)

---

## 🗂️ Complete Project Structure

```
FPGA--Brain-Tumor-Segmentation/
│
├── 📄 README.md                    # Main project documentation
├── 🔧 BUILD_ALL.bat                # Master build script
├── 📡 program_fpga.tcl             # FPGA programming
│
├── 📂 01_python_verification/
│   └── README.md                   # Python setup & usage
│
├── 📂 02_hls_accelerator/
│   └── README.md                   # HLS synthesis guide
│
├── 📂 03_vivado_hardware/
│   └── README.md                   # Hardware build guide
│
├── 📂 04_vitis_software/
│   └── README.md                   # Software build (+ Vitis 2025.1 fix)
│
├── 📂 05_test_images/
│   └── README.md                   # Image formats
│
├── 📂 06_documentation/
│   └── README.md                   # Doc archive
│
└── 📂 docs/                        # Core documentation (you are here!)
    ├── 📘 WORKFLOW.md              # ⭐ Complete A-Z guide
    ├── 📗 SUMMARY.md               # Quick reference
    ├── 📕 prd.md                   # Product requirements
    ├── 📙 nexys.md                 # Board documentation
    └── 📑 README.md                # This index
```

---

## 📞 Getting Help

1. **Check the guides** in this folder first
2. **Search the README files** in each project folder
3. **Open an issue** on GitHub if still stuck

---

## ✨ Documentation Quality

All documentation is:

- ✅ **Beginner-friendly** - Explained in simple terms (even a kid can understand!)
- ✅ **Complete** - Covers the entire workflow A-Z
- ✅ **Practical** - Includes what to expect, how to program FPGA, troubleshooting
- ✅ **Well-organized** - One README per folder, clear structure
- ✅ **Up-to-date** - Matches the current codebase

---

**Last Updated**: April 4, 2026  
**Maintained By**: Project Team  
**Repository**: https://github.com/akulasahasra75/FPGA--Brain-Tumor-Segmentation
