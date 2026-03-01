# Presentation Outline – Brain Tumor Segmentation on FPGA

> **Note:** This is a text outline for building a PowerPoint/Google Slides
> presentation. Create slides using your preferred tool from this content.

---

## Slide 1: Title

**Brain Tumor Segmentation on FPGA**
_with Adaptive Processing Mode Selection_

- Course: Digital System Design Lab
- Board: Nexys A7-100T (Artix-7)
- Tools: Vitis HLS / Vivado 2025.1

---

## Slide 2: Problem Statement

- Brain tumor segmentation from MRI is critical for diagnosis
- Software-only approaches: slow, power-hungry
- Goal: FPGA acceleration for real-time, energy-efficient processing
- Image: 256×256 grayscale MRI scan

---

## Slide 3: Novelty – Adaptive Mode Selection

**What makes this project unique:**

| Image Quality   | Mode Selected | Behaviour                       |
| --------------- | ------------- | ------------------------------- |
| High contrast   | FAST          | Minimal processing, max speed   |
| Medium contrast | NORMAL        | Standard Otsu + cleanup         |
| Low contrast    | CAREFUL       | Adaptive threshold + full morph |

- Automatic – no manual parameter tuning
- Based on: mean, std dev, contrast (single-pass computation)

---

## Slide 4: System Architecture

```
[MicroBlaze CPU] ←AXI→ [HLS Otsu Accelerator]
       ↕                        ↕
   [64KB BRAM]            [Image BRAM]
       ↕
[UART] [GPIO/LEDs] [Timer]
```

- MicroBlaze controls the pipeline
- HLS IP does the heavy computation
- UART for serial debug output

---

## Slide 5: Algorithm

1. **Histogram** – 256-bin grayscale histogram
2. **Otsu Threshold** – maximise inter-class variance
3. **Morphology** – open/close for noise removal (mode-dependent)
4. **Watershed** – connected-component labelling for region analysis

---

## Slide 6: Implementation Flow

```
Phase 1: Python → Verify algorithm works
Phase 2: HLS C++ → Synthesise to IP core
Phase 3: Vivado → Build SoC + bitstream
Phase 4: Vitis → MicroBlaze firmware
Phase 5: Images → Convert test data
Phase 6: Docs → Report & presentation
```

---

## Slide 7: HLS Results

| Step         | Status                  |
| ------------ | ----------------------- |
| C Simulation | ✅ 9/9 tests passed     |
| Synthesis    | ✅ Timing met @ 100 MHz |
| IP Export    | ✅ Generated            |

Resource Usage:

- LUT: ~12%, FF: ~3%, BRAM: 4%, DSP: 3%
- Plenty of room on Artix-7

---

## Slide 8: Segmentation Results

| Image             | Dice | Mode    |
| ----------------- | ---- | ------- |
| brain_01 (bright) | 0.98 | FAST    |
| brain_02 (subtle) | 0.98 | NORMAL  |
| brain_03 (none)   | 0.19 | CAREFUL |

_(Show side-by-side: original → segmentation → overlay)_

---

## Slide 9: Performance Comparison

|        | SW-only | HW-accel | Gain     |
| ------ | ------- | -------- | -------- |
| Time   | 20 ms   | 0.5 ms   | **40×**  |
| Power  | 200 mW  | 50 mW    | **4×**   |
| Energy | 4000 µJ | 25 µJ    | **>99%** |

---

## Slide 10: Demo

- Live demo on Nexys A7-100T board
- Serial terminal shows results
- LEDs indicate processing mode
- Process all 3 test images

---

## Slide 11: Conclusion

- ✅ Successfully implemented Otsu segmentation on FPGA
- ✅ Adaptive mode selection – novel contribution
- ✅ ~40× speedup, >99% energy savings
- ✅ Complete pipeline: Python → HLS → Vivado → Vitis

### Future Work

- Higher resolution (512×512+)
- DMA-based data transfer
- Real MRI DICOM support
- Zynq port with ARM + Linux

---

## Slide 12: Q&A

**Thank you!**

Repository: github.com/akulasahasra75/FPGA--Brain-Tumor-Segmentation
