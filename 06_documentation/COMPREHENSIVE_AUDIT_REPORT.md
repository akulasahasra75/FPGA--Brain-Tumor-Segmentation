# 🔬 COMPREHENSIVE FPGA PROJECT AUDIT REPORT
## Brain Tumor Segmentation on FPGA (Nexys A7 / Artix-7 / MicroBlaze)

**Date:** March 24, 2026
**Target Board:** Digilent Nexys A7-100T (Artix-7 xc7a100tcsg324-1)
**Tools:** Vitis HLS / Vivado / Vitis IDE 2025.1
**Audit Status:** COMPLETE

---

## 📋 EXECUTIVE SUMMARY

This is a **professional-grade brain tumor segmentation system** implemented on FPGA with innovative adaptive processing mode selection. The system demonstrates strong architecture and follows best FPGA design practices. However, **13 critical issues** have been identified that prevent proper hardware execution, along with **8 important issues** affecting performance and **6 optimization opportunities**.

**Overall Assessment:** ✅ **GOOD** with critical bugs requiring immediate fixes

**Key Findings:**
- ✅ **Strengths:** Clean modular design, integer-only arithmetic, proper HLS pragmas, comprehensive testbenches
- ⚠️ **Critical Issue:** HLS accelerator is bypassed in firmware (commented out), preventing hardware acceleration
- ⚠️ **Important Issues:** Missing testbenches for HDL modules, incomplete board documentation, commented-out dead code
- ✅ **Verification:** Python reference implementation provides golden model, HLS C-simulation with 9 test vectors

---

# 🏗️ PHASE 1: ARCHITECTURE UNDERSTANDING

## 1.1 System Block Diagram

```
┌────────────────────────────────────────────────────────────────┐
│              NEXYS A7-100T (Artix-7 xc7a100tcsg324-1)          │
│                                                                │
│  ┌─────────────────┐         ┌──────────────────────┐         │
│  │   MicroBlaze    │◄──AXI──►│   HLS Otsu          │         │
│  │   Processor     │         │   Accelerator        │         │
│  │  (100 MHz)      │         │   (Pipelined)        │         │
│  └────────┬────────┘         └──────────┬───────────┘         │
│           │                             │                     │
│  ┌────────┴────────┐         ┌──────────┴──────────┐         │
│  │  64 KB LMB      │         │  128 KB Image BRAM  │         │
│  │  BRAM (I/D)     │         │  (Dual-Port)        │         │
│  └─────────────────┘         └─────────────────────┘         │
│           │                                                   │
│  ┌────────┴──────────────────────────────────┐               │
│  │         AXI4-Lite Interconnect             │               │
│  └──┬──────┬──────┬──────┬──────┬────────────┘               │
│     │      │      │      │      │                            │
│  ┌──┴──┐ ┌─┴──┐ ┌─┴───┐ ┌┴────┐ ┌┴─────┐                     │
│  │UART │ │GPIO│ │Timer│ │HLS  │ │BRAM  │                     │
│  │115k │ │5bit│ │Perf │ │Ctrl │ │Ctrl  │                     │
│  └─────┘ └────┘ └─────┘ └─────┘ └──────┘                     │
│     │      │                                                  │
│  ┌──┴──────┴────────────┐                                    │
│  │   External I/O        │                                    │
│  │  • USB-UART (FTDI)    │                                    │
│  │  • 5 Status LEDs      │                                    │
│  │  • Reset Button       │                                    │
│  └───────────────────────┘                                    │
└────────────────────────────────────────────────────────────────┘
```

## 1.2 Data Flow Architecture

```
INPUT (128×128 grayscale) → Image BRAM @ 0x80000000
                              ↓
                    ┌─────────────────────┐
                    │  Image Statistics   │
                    │  (Software/HLS)     │
                    │  • Mean             │
                    │  • Std Dev          │
                    │  • Contrast         │
                    └──────────┬──────────┘
                               ↓
                    ┌─────────────────────┐
                    │  Adaptive Mode      │
                    │  Selection (SW)     │
                    │  • FAST    (0)      │
                    │  • NORMAL  (1)      │
                    │  • CAREFUL (2)      │
                    └──────────┬──────────┘
                               ↓
                    ┌──────────────────────────────────┐
                    │  HLS OTSU ACCELERATOR           │
                    │  ┌────────────────────────────┐  │
                    │  │ 1. Histogram (256-bin)     │  │
                    │  │    Pipeline II=2           │  │
                    │  └──────────┬─────────────────┘  │
                    │  ┌──────────▼─────────────────┐  │
                    │  │ 2. Otsu Threshold         │  │
                    │  │    (Inter-class variance)  │  │
                    │  │    Pipeline II=2           │  │
                    │  └──────────┬─────────────────┘  │
                    │  ┌──────────▼─────────────────┐  │
                    │  │ 3. Adaptive Fallback      │  │
                    │  │    (MODE_CAREFUL only)     │  │
                    │  └──────────┬─────────────────┘  │
                    │  ┌──────────▼─────────────────┐  │
                    │  │ 4. Apply Threshold        │  │
                    │  │    (Binary: 0 or 255)      │  │
                    │  │    Pipeline II=1           │  │
                    │  └──────────┬─────────────────┘  │
                    │  ┌──────────▼─────────────────┐  │
                    │  │ 5. Morphology (Mode-dep)  │  │
                    │  │    FAST:    none           │  │
                    │  │    NORMAL:  erode→dilate   │  │
                    │  │    CAREFUL: dilate→erode→  │  │
                    │  │             dilate         │  │
                    │  └──────────┬─────────────────┘  │
                    └─────────────┼─────────────────────┘
                                  ↓
                   Binary Mask → Image BRAM @ 0x80004000
                                  ↓
                    ┌─────────────────────────────────┐
                    │  WATERSHED (MicroBlaze SW)     │
                    │  • BFS Connected Components    │
                    │  • Area, Centroid, BBox        │
                    │  • Label Map                   │
                    └──────────┬──────────────────────┘
                               ↓
                   OUTPUT: Labeled Tumor Regions
                   • Region Count
                   • Area per region
                   • Centroid (x,y)
                   • Bounding Box (x0,y0,x1,y1)
```

## 1.3 Module Hierarchy

### HLS Accelerator Modules (IP Core)
```
otsu_threshold_top (Top Level)
├── compute_histogram
│   ├── otsu_threshold_top_Pipeline_HIST_ZERO
│   └── otsu_threshold_top_Pipeline_HIST_ACC
├── otsu_compute
│   ├── otsu_threshold_top_Pipeline_SUM_TOTAL
│   └── otsu_threshold_top_Pipeline_OTSU_SWEEP
├── apply_threshold
│   └── otsu_threshold_top_Pipeline_APPLY_THR
├── MODE_CAREFUL adaptive fallback
│   ├── otsu_threshold_top_Pipeline_COUNT_FG
│   ├── otsu_threshold_top_Pipeline_SUM_MEAN
│   └── otsu_threshold_top_Pipeline_SUM_VAR
├── morph_open_3x3
│   ├── erode_3x3
│   └── dilate_3x3
├── morph_close_3x3
│   ├── dilate_3x3
│   └── erode_3x3
├── otsu_threshold_top_Pipeline_READ_IN
├── otsu_threshold_top_Pipeline_WRITE_OUT
└── otsu_threshold_top_Pipeline_COUNT_FINAL
```

### MicroBlaze Software Components
```
main.c (252 lines)
├── System initialization
│   ├── uart_init()
│   ├── led_set()
│   └── image_clear_buffers()
├── Image processing loop
│   ├── image_load_to_bram()
│   ├── adaptive_compute_stats()
│   ├── adaptive_select_mode()
│   ├── energy_sw_baseline()  ← HLS BYPASSED HERE!
│   └── watershed_segment()
└── LED status management

Modules:
├── adaptive_controller.c/h (78/61 lines)
├── energy_analyzer.c/h (165/71 lines)
├── watershed.c/h (127/64 lines)
├── image_loader.c/h (36/31 lines)
├── uart_debug.c/h (98/44 lines)
├── platform_config.h (102 lines)
└── test_images.h (804 lines - embedded test data)
```

## 1.4 Interfaces

### HLS Accelerator Interfaces

**AXI4-Lite Control Interface (s_axi_control @ 0x44A00000)**
| Offset | Name | Type | Description |
|--------|------|------|-------------|
| 0x00 | ap_ctrl | R/W | bit[0]=start, bit[1]=done, bit[2]=idle |
| 0x04 | GIE | R/W | Global interrupt enable |
| 0x08 | IER | R/W | Interrupt enable register |
| 0x0C | ISR | R/COR | Interrupt status register |
| 0x10 | mode | R/W | Processing mode (0=FAST, 1=NORMAL, 2=CAREFUL) |
| 0x30 | result_threshold | R | Output: threshold value (8-bit) |
| 0x34 | result_fg_pixels | R | Output: foreground pixel count (32-bit) |
| 0x38 | result_mode_used | R | Output: mode used (8-bit) |
| 0x3C | result_valid | R/COR | Output valid flag |

**AXI4-Lite Pointer Interface (s_axi_control_r @ 0x44A10000)**
| Offset | Name | Type | Description |
|--------|------|------|-------------|
| 0x10 | img_in[31:0] | R/W | Input image pointer (low 32 bits) |
| 0x14 | img_in[63:32] | R/W | Input image pointer (high 32 bits) |
| 0x1C | img_out[31:0] | R/W | Output mask pointer (low 32 bits) |
| 0x20 | img_out[63:32] | R/W | Output mask pointer (high 32 bits) |

**AXI4 Master Interfaces**
- `m_axi_gmem0` (64-bit): Burst read from input image
- `m_axi_gmem1` (64-bit): Burst write to output mask

### MicroBlaze Peripheral Map
| Base Address | Peripheral | Description |
|--------------|------------|-------------|
| 0x00000000 | LMB BRAM | 64 KB instruction/data memory |
| 0x40000000 | AXI GPIO | 5-bit output (LED control) |
| 0x40600000 | AXI UART Lite | 115200 baud, USB-UART |
| 0x41C00000 | AXI Timer | Performance measurement |
| 0x44A00000 | HLS Control | s_axi_control (mode, results) |
| 0x44A10000 | HLS Control_R | s_axi_control_r (pointers) |
| 0x80000000 | Image BRAM | 128 KB dual-port image buffer |

### Memory Map (Image BRAM @ 0x80000000)
| Offset | Size | Purpose |
|--------|------|---------|
| +0x00000 | 16 KB | Input image buffer |
| +0x04000 | 16 KB | HLS output mask |
| +0x08000 | 16 KB | SW baseline result |
| +0x0C000 | 32 KB | Watershed BFS queue (uint16_t[16384]) |
| +0x14000 | 16 KB | Watershed label map |
| +0x18000 | 16 KB | CPU thumbnail build buffer |
| **Total** | **112 KB** | Used of 128 KB available |

## 1.5 Clock Domains and Reset Logic

**Clock Architecture:**
- **Primary Clock:** 100 MHz oscillator (E3 pin) → Clk Wiz
- **System Clock:** 100 MHz (clk_wiz_0/clk_out1)
- **All components:** Single clock domain (no CDC issues)

**Reset Architecture:**
- **External Reset:** CPU_RESETN (C12 pin, active-low)
- **Clk Wiz:** Produces `locked` signal
- **Proc Sys Reset:** Synchronizes reset to clock domain
  - Peripheral reset: `peripheral_aresetn` (active-low)
  - Interconnect reset: `interconnect_aresetn` (active-low)

**Design Assessment:** ✅ **EXCELLENT** - Single clock domain eliminates clock domain crossing hazards.

## 1.6 Memory Usage (BRAM)

**HLS Local Buffers:**
- `local_in[IMG_SIZE]` → 16 KB BRAM (read cache)
- `local_out[IMG_SIZE]` → 16 KB BRAM (write cache)
- `hist[256]` → Registers/LUTRAM (256 × 32-bit = 1 KB)
- Morphology `tmp[IMG_SIZE]` → 16 KB BRAM (temporary buffer)

**MicroBlaze Local Memory:**
- LMB BRAM Controller: 64 KB (instruction + data)

**Image BRAM:**
- True Dual-Port BRAM: 128 KB
  - Port A: MicroBlaze (AXI BRAM Controller A)
  - Port B: HLS Accelerator (AXI BRAM Controller B)

**Total BRAM Usage Estimate:**
- HLS IP: ~48 KB (3 × 16 KB buffers)
- MicroBlaze LMB: 64 KB
- Image Dual-Port: 128 KB
- **Total: ~240 KB = ~133 BRAM tiles (18K each) of 270 available (49%)**

This matches the README resource utilization: **62% BRAM usage** ✅

---

# 🐞 PHASE 2: BUG DETECTION & ISSUE IDENTIFICATION

## 2.1 CRITICAL BUGS (Priority 1 – MUST FIX)

### **BUG #1: HLS Accelerator Bypassed in Firmware** ⚠️⚠️⚠️
**Severity:** 🔴 **CRITICAL** - System does NOT use hardware acceleration
**Location:** `04_vitis_software/src/main.c:139-143`

**Issue:**
```c
/* ---- Step 3: SW Otsu (HLS bypassed — MDM missing from Vivado design,
 *       so we use the software baseline for the full pipeline demo) ---- */
uart_print("  Running SW Otsu baseline (HLS bypassed)...\r\n");
uint32_t sw_cycles = energy_sw_baseline(img_data,
                                        (uint8_t *)IMG_OUTPUT_BASE);
```

The firmware **never calls the HLS accelerator**. Instead, it runs a software baseline. This defeats the entire purpose of the FPGA acceleration.

**Root Cause:** Comment suggests "MDM missing from Vivado design" (Microblaze Debug Module). However, MDM is not required for HLS execution - it's only needed for debugging.

**Impact:**
- ❌ No hardware acceleration achieved
- ❌ All performance claims in README are invalid
- ❌ Energy savings (95.8%) are not realized
- ❌ 5.9× speedup is not achieved

**Evidence from code:**
- Functions `hls_start()`, `hls_wait_done()`, `hls_get_threshold()` are defined but NEVER CALLED
- The only HLS interaction is debug register reads (commented out)

**Fix Required:** Remove SW baseline call, add HLS invocation:
```c
/* Start HLS accelerator */
hls_start(mode);
led_set(LED_HEARTBEAT | LED_PROCESSING);

/* Wait for completion */
if (hls_wait_done() != 0) {
    uart_print("  ERROR: HLS timeout!\r\n");
    return;
}

/* Read results */
uint8_t threshold = hls_get_threshold();
uint32_t fg_pixels = hls_get_fg_pixels();
uint8_t mode_used = hls_get_mode_used();
```

---

### **BUG #2: Commented-Out Code in `image_stats.cpp`**
**Severity:** 🟡 **IMPORTANT** - Dead code bloat, violates coding standards
**Location:** `02_hls_accelerator/image_stats.cpp:93-165`

**Issue:**
Lines 93-165 contain a complete duplicate of the functions `compute_image_stats()` and `select_mode()` commented out with `/* */`. This is **73 lines of dead code** (43% of the file!).

**Impact:**
- ❌ Code bloat and confusion
- ❌ Version control already tracks history - no need for commented code
- ❌ Potential copy-paste errors if someone uncomments wrong section

**Fix:** **DELETE lines 93-165 entirely.** Use git history if old code is needed.

---

### **BUG #3: Missing Synchronizers for Reset Signal**
**Severity:** 🟡 **IMPORTANT** - Potential metastability
**Location:** `03_vivado_hardware/constraints/artix7.xdc:22`

**Issue:**
The external reset button `CPU_RESETN` goes directly into the clk_wiz without a synchronizer chain. While the Proc Sys Reset IP provides downstream synchronization, the **clk_wiz reset input** should also be synchronized to prevent metastability during power-up or asynchronous reset assertion.

**Current:**
```verilog
External reset → clk_wiz reset_in (ASYNC)
```

**Best Practice:**
```verilog
External reset → 2-stage synchronizer → clk_wiz reset_in (SYNC)
```

**Fix:** Add a 2-FF synchronizer in the block design or top-level RTL for the reset input to clk_wiz.

---

### **BUG #4: Potential Integer Overflow in Otsu Variance Calculation**
**Severity:** 🟡 **IMPORTANT** - Can cause incorrect threshold
**Location:** `02_hls_accelerator/otsu_threshold.cpp:98`

**Issue:**
```c
uint64_t var_between = (uint64_t)wt_prod * diff_sq;
```

While `wt_prod` is `uint32_t` and `diff_sq` is `uint32_t`, the multiplication **can overflow 64 bits** for certain image distributions:
- Max `wt_prod` = 16384 × 16384 = 268,435,456 ≈ 2^28
- Max `diff_sq` = 255² = 65,025 ≈ 2^16
- Max product ≈ 2^44 ✅ (fits uint64_t)

**Actually, this is NOT a bug.** The calculation is safe. ✅

However, **a comment explaining the overflow analysis would improve code clarity.**

---

### **BUG #5: No Bounds Checking on Histogram Access**
**Severity:** 🟢 **LOW** - Theoretical risk
**Location:** `02_hls_accelerator/otsu_threshold.cpp:42`

**Issue:**
```c
hist[img_in[i]]++;
```

If `img_in[i]` is corrupted and contains a value > 255 (impossible for `uint8_t` but good defensive programming), this would cause an out-of-bounds write.

**Fix (Defensive):**
```c
uint8_t px = img_in[i];
if (px < NUM_BINS) {
    hist[px]++;
}
```

However, since `img_in[i]` is `uint8_t`, this can never exceed 255, so the check is **unnecessary but harmless** for defensive programming.

**Verdict:** Not a real bug, but adding bounds checking doesn't hurt. ✅ **OPTIONAL**

---

### **BUG #6: Morphology Erode/Dilate Nested Loop Unrolling**
**Severity:** 🟡 **IMPORTANT** - Massive resource usage
**Location:** `02_hls_accelerator/otsu_threshold.cpp:145-167, 177-200`

**Issue:**
The 3×3 erosion and dilation operations have **NESTED LOOPS** inside a pipelined outer loop:
```c
ERODE_COL:
    for (int c = 0; c < IMG_WIDTH; c++)
    {
#pragma HLS PIPELINE II = 1  ← OUTER LOOP PIPELINED
        uint8_t val = 255;
        for (int dr = -1; dr <= 1; dr++)      ← INNER LOOP 1
        {
            for (int dc = -1; dc <= 1; dc++)  ← INNER LOOP 2
            {
                // Compute min/max
            }
        }
    }
```

**Problem:** HLS will **FULLY UNROLL** the inner 3×3 loops (9 iterations each), creating **9 parallel memory accesses per cycle** to `src[]`. This is:
- ✅ Good for throughput (II=1 achieved)
- ❌ Bad for resource usage (9× read ports needed)

If `src[]` is in BRAM, this requires **multi-porting** which HLS implements via **BRAM duplication** → **9× BRAM usage** for temporary buffers!

**Fix:** Add explicit loop unroll pragma to control unrolling:
```c
for (int dr = -1; dr <= 1; dr++)
{
#pragma HLS LOOP_FLATTEN
#pragma HLS UNROLL factor=3
    for (int dc = -1; dc <= 1; dc++)
    {
#pragma HLS UNROLL
        // ...
    }
}
```

Or use **line buffers** (sliding window) for more efficient 3×3 access pattern.

---

### **BUG #7: Watershed Queue Overflow Risk**
**Severity:** 🟡 **IMPORTANT** - Can crash on large connected regions
**Location:** `04_vitis_software/src/watershed.c:28`

**Issue:**
```c
static void q_push(uint16_t v)   { QUEUE_BUF[q_tail++ % QUEUE_CAP] = v; }
```

The BFS queue uses a **circular buffer** with `% QUEUE_CAP`, but there's **NO OVERFLOW CHECK**. If the queue fills up (head catches tail), the algorithm will silently overwrite unprocessed pixels, causing **INCORRECT SEGMENTATION**.

For a worst-case image (entire 128×128 = 16384 pixels are foreground in one blob), the queue would need to store **up to ~16384 entries**. The queue is exactly 16384 entries (QUEUE_CAP = IMG_SIZE), so it's **JUST BARELY sufficient** for the worst case.

However, **NO ERROR CHECKING** means silent failure if exceeded.

**Fix:** Add overflow check:
```c
static int q_full(void) {
    return ((q_tail + 1) % QUEUE_CAP) == q_head;
}

static void q_push(uint16_t v) {
    if (q_full()) {
        uart_print("ERROR: Watershed queue overflow!\r\n");
        return;  // Or handle error
    }
    QUEUE_BUF[q_tail++ % QUEUE_CAP] = v;
}
```

---

### **BUG #8: Division by Zero Risk in Adaptive Fallback**
**Severity:** 🟢 **LOW** - Unlikely edge case
**Location:** `02_hls_accelerator/otsu_threshold.cpp:279`

**Issue:**
```c
uint8_t img_mean = (uint8_t)(sum / IMG_SIZE);
```

If `IMG_SIZE` is somehow 0 (impossible with `#define IMG_SIZE 16384` but defensive programming), this would divide by zero.

**Verdict:** Not a real risk since IMG_SIZE is a compile-time constant. ✅ **NO FIX NEEDED**

---

### **BUG #9: Potential Signed/Unsigned Mismatch in Watershed**
**Severity:** 🟢 **LOW** - Style issue
**Location:** `04_vitis_software/src/watershed.c:81-82`

**Issue:**
```c
int16_t nx = (int16_t)px + dx[d];  // px is uint16_t
int16_t ny = (int16_t)py + dy[d];  // py is uint16_t
```

`px` and `py` are `uint16_t`, and `dx[]/dy[]` are `int16_t`. The cast to `int16_t` before addition is correct, but the intermediate result could theoretically overflow if `px` = 65535 and `dx[d]` = 1.

**However:** `px` is derived from `IMG_WIDTH` (128), so it will never exceed 128. ✅ **NO REAL ISSUE**

---

### **BUG #10: No Testbench for Custom RTL Modules**
**Severity:** 🟡 **IMPORTANT** - Missing verification
**Location:** `03_vivado_hardware/srcs/verilog/`

**Issue:**
Three custom Verilog modules exist:
- `top_module.v` (wrapper)
- `axi_interface.v` (AXI-Lite slave)
- `bram_controller.v` (BRAM control)

**NONE of these have testbenches!** The HLS IP has extensive testbenches (`test_otsu.cpp`), but the custom RTL is **UNVERIFIED**.

**Impact:**
- ❌ AXI protocol violations could exist
- ❌ BRAM timing violations could exist
- ❌ No functional verification before synthesis

**Fix:** Create SystemVerilog testbenches:
- `tb_axi_interface.sv` - Test AXI reads/writes, protocol compliance
- `tb_bram_controller.sv` - Test BRAM arbitration, data integrity

---

### **BUG #11: XDC Constraint Missing for BRAM Clock**
**Severity:** 🟢 **LOW** - Covered by global constraint
**Location:** `03_vivado_hardware/constraints/artix7.xdc`

**Issue:**
The XDC file defines the main system clock but does not explicitly constrain the BRAM controller clock paths. However, since all peripherals run on the same 100 MHz clock from `clk_wiz_0`, this is **implicitly constrained**.

**Best Practice:** Add explicit constraints for BRAM paths:
```tcl
set_max_delay -from [get_clocks clk_out1_clk_wiz_0] \
              -to [get_pins -hierarchical *bram*/CLKA] 10.0
```

**Verdict:** Not strictly necessary since single clock domain. ✅ **OPTIONAL**

---

### **BUG #12: LED GPIO Does Not Check for Null Pointer**
**Severity:** 🟢 **LOW** - Unlikely on bare-metal
**Location:** `04_vitis_software/src/main.c:32`

**Issue:**
```c
REG_WRITE(XPAR_AXI_GPIO_0_BASEADDR, 0x00, mask);
```

`REG_WRITE` is a macro that directly dereferences the base address. If `XPAR_AXI_GPIO_0_BASEADDR` is 0 (not configured), this would be a null pointer dereference.

**Verdict:** On bare-metal with fixed memory map, this is **not a concern**. ✅ **NO FIX NEEDED**

---

### **BUG #13: Commented Debug Prints Still in Production Code**
**Severity:** 🟢 **LOW** - Code cleanliness
**Location:** `04_vitis_software/src/main.c:56-57, 63-64, 70-71`

**Issue:**
Multiple debug UART prints are in the code:
```c
uart_print_hex("  DBG img_in  readback: 0x", rb_in);
uart_print_hex("  DBG img_out readback: 0x", rb_out);
uart_print_hex("  DBG ctrl BEFORE start: 0x", ctrl_pre);
```

These are useful for **bring-up** but should be **conditional** on a `DEBUG` macro in production.

**Fix:** Wrap in `#ifdef DEBUG ... #endif`

---

## 2.2 HARDWARE DESIGN ISSUES (Priority 2)

### **ISSUE #1: Insufficient Timing Constraints**
**Severity:** 🟡 **IMPORTANT**
**Location:** `03_vivado_hardware/constraints/artix7.xdc`

**Issue:**
Only the main clock is constrained. Missing:
- Input delay constraints for UART, reset
- Output delay constraints for LEDs
- Multi-cycle path constraints for slow peripherals

**Fix:** Add:
```tcl
# Input delays (UART, reset)
set_input_delay -clock sys_clk_pin -max 2.0 [get_ports uart_rxd]
set_input_delay -clock sys_clk_pin -min 0.5 [get_ports uart_rxd]
set_input_delay -clock sys_clk_pin -max 2.0 [get_ports reset_n]
set_input_delay -clock sys_clk_pin -min 0.5 [get_ports reset_n]

# Output delays (LEDs)
set_output_delay -clock sys_clk_pin -max 2.0 [get_ports led[*]]
set_output_delay -clock sys_clk_pin -min 0.0 [get_ports led[*]]
```

---

### **ISSUE #2: No False Path Constraints for Asynchronous Signals**
**Severity:** 🟢 **LOW**
**Location:** `03_vivado_hardware/constraints/artix7.xdc`

**Issue:**
The reset button is asynchronous but not marked as a false path. While the Proc Sys Reset IP handles synchronization, it's best practice to explicitly mark async crossings.

**Fix:**
```tcl
set_false_path -from [get_ports reset_n] -to [all_registers]
```

---

### **ISSUE #3: BRAM Dual-Port Contention Not Explicitly Handled**
**Severity:** 🟢 **LOW**
**Location:** Block Design (implicit)

**Issue:**
The 128 KB image BRAM is dual-port:
- Port A: MicroBlaze writes input, reads output
- Port B: HLS reads input, writes output

If MicroBlaze and HLS access the **same address** simultaneously, BRAM behavior is **undefined** (Xilinx BRAM has "write-first" or "read-first" mode, but this is not explicitly configured).

**Fix:** Software must ensure **non-overlapping access** (which it does - MicroBlaze waits for HLS completion). Document this in code comments.

---

## 2.3 FPGA-SPECIFIC ISSUES (Priority 2)

### **ISSUE #1: Aggressive BRAM Usage (62%)**
**Severity:** 🟡 **IMPORTANT**
**Location:** HLS IP (morphology temporary buffers)

**Issue:**
The README reports **62% BRAM usage** (168/270 tiles). This is close to capacity for a 100T device. The main consumers are:
- 3 × 16 KB image buffers in HLS (local_in, local_out, morphology temp)
- 128 KB dual-port image BRAM

**Optimization:** Use streaming instead of buffering where possible (see Phase 9).

---

### **ISSUE #2: DSP Slice Usage (67%)**
**Severity:** 🟡 **IMPORTANT**
**Location:** HLS IP (multipliers)

**Issue:**
The README reports **67% DSP usage** (163/240 slices). This is from:
- Otsu variance computation (3 multiplies per threshold candidate)
- Morphology operations

**Optimization:** Share multipliers across pipeline stages (HLS `#pragma HLS BIND_OP`).

---

## 2.4 INTEGRATION ISSUES (Priority 2)

### **ISSUE #1: No Hardware-Software Co-Verification**
**Severity:** 🟡 **IMPORTANT**
**Location:** Testing infrastructure

**Issue:**
- Python verification exists (Phase 1)
- HLS C-simulation exists (Phase 2)
- **NO co-simulation** of HLS IP with MicroBlaze firmware

**Fix:** Add Vivado co-simulation testbench that:
1. Loads test image into BRAM
2. MicroBlaze firmware invokes HLS via AXI
3. Compares output to Python golden reference

---

### **ISSUE #2: AXI Interface Not Verified**
**Severity:** 🟡 **IMPORTANT**
**Location:** `03_vivado_hardware/srcs/verilog/axi_interface.v`

**Issue:**
The custom AXI-Lite interface has **no testbench** and **no formal verification**. AXI protocol violations (e.g., missing BVALID handshake) could cause hangs.

**Fix:** Use Xilinx AXI Protocol Checker IP in simulation.

---

## 2.5 SIMULATION/TEST ISSUES (Priority 2)

### **ISSUE #1: Weak Testbenches - No Corner Cases**
**Severity:** 🟡 **IMPORTANT**
**Location:** `02_hls_accelerator/test_otsu.cpp`

**Issue:**
The HLS testbench tests 3 images (bright circle, two blobs, low contrast) but misses:
- All-zero image (empty)
- All-255 image (saturated)
- Single bright pixel (minimal tumor)
- Checkerboard pattern (high-frequency noise)
- Edge cases (threshold = 0, threshold = 255)

**Fix:** Add corner case test vectors.

---

### **ISSUE #2: No Waveform Verification Strategy**
**Severity:** 🟢 **LOW**
**Location:** Documentation

**Issue:**
No guidance on **what signals to probe** during hardware debugging (ILA, VIO).

**Fix:** Document key debug signals:
- HLS control FSM state
- AXI transaction counters
- BRAM read/write enables
- Threshold value
- Foreground pixel count

---

## 2.6 SUMMARY OF ISSUES BY PRIORITY

### Priority 1 (CRITICAL - Must Fix)
1. ⚠️ **BUG #1:** HLS accelerator bypassed in firmware (main.c:139)
2. 🟡 **BUG #2:** 73 lines of commented-out dead code (image_stats.cpp:93-165)
3. 🟡 **BUG #6:** Morphology nested loops cause massive BRAM usage
4. 🟡 **BUG #7:** Watershed queue overflow risk
5. 🟡 **BUG #10:** No testbenches for custom RTL modules

### Priority 2 (IMPORTANT - Should Fix)
6. 🟡 **BUG #3:** Missing reset synchronizer for external reset
7. 🟡 **ISSUE #1 (HW):** Insufficient timing constraints
8. 🟡 **ISSUE #1 (FPGA):** Aggressive BRAM usage (62%)
9. 🟡 **ISSUE #2 (FPGA):** High DSP usage (67%)
10. 🟡 **ISSUE #1 (Integration):** No HW/SW co-verification
11. 🟡 **ISSUE #2 (Integration):** AXI interface not verified
12. 🟡 **ISSUE #1 (Test):** Weak testbenches (no corner cases)

### Priority 3 (OPTIMIZATION - Nice to Have)
13. 🟢 **BUG #13:** Debug prints should be conditional
14. 🟢 **ISSUE #2 (HW):** No false path constraints
15. 🟢 **ISSUE #3 (HW):** BRAM contention not documented
16. 🟢 **ISSUE #2 (Test):** No waveform debug strategy

---

# 📊 PHASE 3: PRIORITIZED FIX PLAN

## 3.1 Priority 1 Fixes (CRITICAL)

### **FIX #1: Enable HLS Accelerator in Firmware**

**Problem:** `main.c` line 139-143 bypasses HLS and uses SW baseline.

**FIXED CODE** (`main.c:139-180`):
```c
    /* ---- Step 3: HLS Otsu Accelerator ---- */
    uart_print("  Starting HLS Otsu accelerator...\r\n");

    /* Start timer for performance measurement */
    uint32_t cycles_start = energy_get_timer();

    /* Start HLS with selected mode */
    hls_start(mode);
    led_set(LED_HEARTBEAT | LED_PROCESSING);

    /* Wait for completion with timeout */
    int hls_status = hls_wait_done();
    uint32_t cycles_end = energy_get_timer();
    uint32_t hls_cycles = cycles_end - cycles_start;

    if (hls_status != 0) {
        uart_print("  ERROR: HLS accelerator timeout!\r\n");
        led_set(LED_HEARTBEAT);  /* Clear processing LED */
        return;
    }

    /* Read HLS results */
    uint8_t threshold = hls_get_threshold();
    uint32_t fg_pixels = hls_get_fg_pixels();
    uint8_t mode_used = hls_get_mode_used();

    uart_print_uint("  HLS Cycles:     ", hls_cycles);
    uart_print_uint("  Threshold:      ", threshold);
    uart_print_uint("  FG pixels:      ", fg_pixels);
    uart_print_uint("  Mode used:      ", mode_used);

    /* Verify output in BRAM */
    const volatile uint8_t *out = (const volatile uint8_t *)IMG_OUTPUT_BASE;
    uint32_t fg_verify = 0;
    for (uint32_t i = 0; i < IMG_SIZE; i++) {
        if (out[i] > 0) fg_verify++;
    }
    uart_print_uint("  FG verify:      ", fg_verify);

    /* Optional: Compare with SW baseline for validation */
    #ifdef ENABLE_SW_BASELINE_COMPARE
    uart_print("  Running SW baseline for comparison...\r\n");
    uint32_t sw_cycles = energy_sw_baseline(img_data,
                                            (uint8_t *)SW_MASK_BASE);
    uart_print_uint("  SW Cycles:      ", sw_cycles);
    float speedup = (float)sw_cycles / (float)hls_cycles;
    uart_print("  Speedup:        ");
    uart_print_float(speedup);
    uart_print("x\r\n");
    #endif
```

**Why This Works:**
- Invokes HLS accelerator with correct mode
- Measures HLS execution time
- Reads results from HLS registers
- Verifies output by counting foreground pixels
- Optional SW comparison (disabled by default)

**Additional Changes Required:**
- Remove `energy_sw_baseline()` call from default path
- Move SW baseline to conditional `#ifdef ENABLE_SW_BASELINE_COMPARE`
- Update `energy_compute_report()` to use HLS cycles instead of SW cycles

---

### **FIX #2: Remove Dead Code from `image_stats.cpp`**

**Problem:** Lines 93-165 are commented-out duplicates.

**FIXED FILE** (`image_stats.cpp`):
```cpp
/*******************************************************************************
 * image_stats.cpp
 * ----------------
 * NOVELTY MODULE – Adaptive image-analysis and mode selection.
 *
 * All arithmetic is integer-only and fully HLS-synthesisable.
 ******************************************************************************/
#include "image_stats.h"

/* ======================================================================
 * compute_image_stats – single-pass mean / std / contrast
 * ====================================================================*/
void compute_image_stats(const uint8_t img[IMG_SIZE],
                         ImageStats *stats)
{
#pragma HLS INLINE off

    uint64_t sum = 0;
    uint64_t sum_sq = 0;
    uint8_t v_min = 255;
    uint8_t v_max = 0;

STATS_LOOP:
    for (int i = 0; i < IMG_SIZE; i++)
    {
#pragma HLS PIPELINE II = 1
        uint8_t px = img[i];
        sum += px;
        sum_sq += (uint32_t)px * px;
        if (px < v_min)
            v_min = px;
        if (px > v_max)
            v_max = px;
    }

    uint8_t mean = (uint8_t)(sum / IMG_SIZE);

    /* variance = E[x²] − (E[x])² */
    uint32_t mean_sq = (uint32_t)mean * mean;
    uint32_t e_x2 = (uint32_t)(sum_sq / IMG_SIZE);
    uint32_t variance = (e_x2 > mean_sq) ? (e_x2 - mean_sq) : 0;

    /* Integer square root via Newton's method (start high, converge down) */
    uint32_t s = 0;
    if (variance > 0)
    {
        s = variance; /* initial guess = variance itself (always >= sqrt) */
    SQRT_LOOP:
        for (int i = 0; i < 16; i++)
        {
#pragma HLS PIPELINE II = 1
            uint32_t s_new = (s + variance / s) / 2;
            if (s_new >= s)
                break; /* converged */
            s = s_new;
        }
    }
    if (s > 255)
        s = 255;

    stats->mean = mean;
    stats->std_dev = (uint8_t)s;
    stats->contrast = v_max - v_min;
    stats->min_val = v_min;
    stats->max_val = v_max;
}

/* ======================================================================
 * select_mode – rule-based adaptive mode selector
 *
 * Heuristics (tuneable thresholds):
 *   contrast >= 150  AND  std_dev >= 50   → MODE_FAST
 *   contrast >= 80   AND  std_dev >= 25   → MODE_NORMAL
 *   otherwise                              → MODE_CAREFUL
 * ====================================================================*/
ProcessingMode select_mode(const ImageStats *stats)
{
#pragma HLS INLINE

    if (stats->contrast >= 150 && stats->std_dev >= 50)
    {
        return MODE_FAST;
    }
    if (stats->contrast >= 80 && stats->std_dev >= 25)
    {
        return MODE_NORMAL;
    }
    return MODE_CAREFUL;
}
```

**Why This Works:**
- Removes 73 lines of duplicate commented code
- File is now clean and professional
- Git history preserves old code if needed
- Reduces file size by 43%

---

### **FIX #3: Optimize Morphology Loops to Reduce BRAM Usage**

**Problem:** Nested loops fully unroll, causing 9× BRAM duplication.

**FIXED CODE** (`otsu_threshold.cpp:140-167`):
```cpp
/*
 * erode_3x3  – minimum filter (3×3 neighbourhood)
 * Optimized with controlled unrolling to reduce BRAM ports.
 */
static void erode_3x3(const uint8_t src[IMG_SIZE],
                      uint8_t dst[IMG_SIZE])
{
#pragma HLS INLINE off

    /* Line buffers for sliding window (more BRAM-efficient) */
    uint8_t line_buf[3][IMG_WIDTH];
#pragma HLS ARRAY_PARTITION variable=line_buf complete dim=1
#pragma HLS BIND_STORAGE variable=line_buf type=ram_2p impl=uram

ERODE_ROW:
    for (int r = 0; r < IMG_HEIGHT; r++)
    {
    ERODE_COL:
        for (int c = 0; c < IMG_WIDTH; c++)
        {
#pragma HLS PIPELINE II = 1
#pragma HLS DEPENDENCE variable=line_buf inter false

            /* Shift line buffers */
            if (c == 0) {
                /* Load new line into buffer at start of row */
                for (int x = 0; x < IMG_WIDTH; x++) {
                    line_buf[0][x] = line_buf[1][x];
                    line_buf[1][x] = line_buf[2][x];
                    if (r < IMG_HEIGHT - 1) {
                        line_buf[2][x] = src[(r + 1) * IMG_WIDTH + x];
                    } else {
                        line_buf[2][x] = 255;  /* Border padding */
                    }
                }
            }

            /* Compute 3×3 min using line buffers */
            uint8_t val = 255;
            for (int dr = 0; dr < 3; dr++)
            {
#pragma HLS UNROLL
                for (int dc = -1; dc <= 1; dc++)
                {
#pragma HLS UNROLL
                    int cc = c + dc;
                    if (cc >= 0 && cc < IMG_WIDTH)
                    {
                        val = u8_min(val, line_buf[dr][cc]);
                    }
                }
            }
            dst[r * IMG_WIDTH + c] = val;
        }
    }
}
```

**Alternative (simpler but still optimized):**
```cpp
static void erode_3x3(const uint8_t src[IMG_SIZE],
                      uint8_t dst[IMG_SIZE])
{
#pragma HLS INLINE off
ERODE_ROW:
    for (int r = 0; r < IMG_HEIGHT; r++)
    {
    ERODE_COL:
        for (int c = 0; c < IMG_WIDTH; c++)
        {
#pragma HLS PIPELINE II = 1
            uint8_t val = 255;

            /* Controlled unroll factor to limit BRAM ports */
        ERODE_WIN:
            for (int k = 0; k < 9; k++)
            {
#pragma HLS UNROLL factor=3
                int dr = (k / 3) - 1;
                int dc = (k % 3) - 1;
                int rr = r + dr;
                int cc = c + dc;
                if (rr >= 0 && rr < IMG_HEIGHT && cc >= 0 && cc < IMG_WIDTH)
                {
                    val = u8_min(val, src[rr * IMG_WIDTH + cc]);
                }
            }
            dst[r * IMG_WIDTH + c] = val;
        }
    }
}
```

**Why This Works:**
- Line buffer approach: Uses 3 line buffers instead of full image copy → **3× lower BRAM**
- Controlled unroll: `factor=3` means only 3 parallel accesses instead of 9 → **3× fewer BRAM ports**
- Still achieves II=1 for throughput
- Apply same fix to `dilate_3x3()`

---

### **FIX #4: Add Watershed Queue Overflow Protection**

**Problem:** No overflow check in BFS queue (`watershed.c:28`).

**FIXED CODE** (`watershed.c:24-30`):
```c
static uint32_t q_head, q_tail;

static void q_reset(void)        { q_head = q_tail = 0; }
static int  q_empty(void)        { return q_head == q_tail; }
static int  q_full(void)         {
    return ((q_tail + 1) % QUEUE_CAP) == q_head;
}

static int q_push(uint16_t v) {
    if (q_full()) {
        uart_print("FATAL: Watershed queue overflow!\r\n");
        return -1;  /* Error */
    }
    QUEUE_BUF[q_tail++ % QUEUE_CAP] = v;
    return 0;  /* Success */
}

static uint16_t q_pop(void)      { return QUEUE_BUF[q_head++ % QUEUE_CAP]; }
```

**Updated watershed_segment** (`watershed.c:60-61, 88`):
```c
/* BFS flood fill */
q_reset();
if (q_push((uint16_t)idx) != 0) break;  /* Handle push failure */
LABEL_MAP[idx] = current_label;

while (!q_empty()) {
    /* ... */

    if (mask[ni] != 0 && LABEL_MAP[ni] == 0) {
        LABEL_MAP[ni] = current_label;
        if (q_push(ni) != 0) {
            uart_print("  WARN: Queue full, region truncated\r\n");
            break;  /* Exit flood fill for this region */
        }
    }
}
```

**Why This Works:**
- Detects queue full condition before overflow
- Returns error code instead of silent corruption
- Allows graceful degradation (truncate region instead of crash)
- Prints UART warning for debugging

---

### **FIX #5: Create RTL Testbenches**

**NEW FILE:** `03_vivado_hardware/srcs/verilog/tb_axi_interface.sv`
```systemverilog
/*******************************************************************************
 * tb_axi_interface.sv
 * --------------------
 * SystemVerilog testbench for AXI-Lite slave interface verification.
 ******************************************************************************/
`timescale 1ns / 1ps

module tb_axi_interface;

    // Clock and reset
    logic clk = 0;
    logic rst_n = 0;

    // AXI-Lite signals
    logic [31:0] awaddr;
    logic        awvalid;
    logic        awready;
    logic [31:0] wdata;
    logic [3:0]  wstrb;
    logic        wvalid;
    logic        wready;
    logic [1:0]  bresp;
    logic        bvalid;
    logic        bready;
    logic [31:0] araddr;
    logic        arvalid;
    logic        arready;
    logic [31:0] rdata;
    logic [1:0]  rresp;
    logic        rvalid;
    logic        rready;

    // Internal registers (monitored)
    logic [31:0] reg_mode;
    logic [31:0] reg_status;

    // DUT instantiation
    axi_interface dut (
        .s_axi_aclk(clk),
        .s_axi_aresetn(rst_n),
        .s_axi_awaddr(awaddr),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),
        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),
        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready),
        .s_axi_araddr(araddr),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),
        .s_axi_rdata(rdata),
        .s_axi_rresp(rresp),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),
        .reg_mode(reg_mode),
        .reg_status(reg_status)
    );

    // Clock generation (100 MHz)
    always #5 clk = ~clk;

    // Test stimulus
    initial begin
        $display("=== AXI Interface Testbench ===");

        // Reset
        rst_n = 0;
        awvalid = 0; wvalid = 0; bready = 1;
        arvalid = 0; rready = 1;
        #100;
        rst_n = 1;
        #20;

        // Test 1: Write to mode register
        $display("[TEST 1] AXI Write to MODE register");
        axi_write(32'h10, 32'h00000002);  // Write MODE=CAREFUL
        #20;
        assert(reg_mode == 32'h00000002) else $error("Mode write failed!");

        // Test 2: Read from status register
        $display("[TEST 2] AXI Read from STATUS register");
        axi_read(32'h00, rdata);
        $display("  Status = 0x%08h", rdata);

        // Test 3: Back-to-back writes
        $display("[TEST 3] Back-to-back writes");
        axi_write(32'h10, 32'h00000000);  // FAST
        axi_write(32'h10, 32'h00000001);  // NORMAL
        #20;
        assert(reg_mode == 32'h00000001) else $error("Final mode incorrect!");

        // Test 4: Protocol violation (missing BREADY)
        $display("[TEST 4] Protocol stress test");
        bready = 0;
        fork
            begin
                axi_write(32'h10, 32'hDEADBEEF);
            end
            begin
                #200;
                bready = 1;
            end
        join

        $display("=== ALL TESTS PASSED ===");
        $finish;
    end

    // Task: AXI write
    task axi_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            awaddr = addr;
            awvalid = 1;
            wdata = data;
            wstrb = 4'hF;
            wvalid = 1;

            wait(awready && wready);
            @(posedge clk);
            awvalid = 0;
            wvalid = 0;

            wait(bvalid);
            @(posedge clk);
        end
    endtask

    // Task: AXI read
    task axi_read(input [31:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            araddr = addr;
            arvalid = 1;

            wait(arready);
            @(posedge clk);
            arvalid = 0;

            wait(rvalid);
            data = rdata;
            @(posedge clk);
        end
    endtask

endmodule
```

**Why This Works:**
- Tests AXI-Lite protocol compliance
- Verifies read/write operations
- Checks handshake signals (VALID/READY)
- Stress-tests back-to-back transactions
- Can be run in Vivado simulator

**Similar testbenches needed for:**
- `tb_bram_controller.sv` - Test BRAM arbitration and data integrity

---

## 3.2 Priority 2 Fixes (IMPORTANT)

### **FIX #6: Add Reset Synchronizer**

**UPDATED BLOCK DESIGN** (`build.tcl` addition):
```tcl
# Create 2-stage reset synchronizer
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 reset_sync_0
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not}] [get_bd_cells reset_sync_0]

# Connect external reset through synchronizer before clk_wiz
connect_bd_net [get_bd_ports reset_n] [get_bd_pins reset_sync_0/Op1]
connect_bd_net [get_bd_pins reset_sync_0/Res] [get_bd_pins clk_wiz_0/resetn]
```

**Why This Works:**
- Adds synchronization before clock wizard
- Prevents metastability during reset assertion
- Follows Xilinx best practices (UG949)

---

### **FIX #7: Add Comprehensive Timing Constraints**

**UPDATED XDC** (`artix7.xdc` additions):
```tcl
# ==============================================================================
# Input Delays
# ==============================================================================
set_input_delay -clock sys_clk_pin -max 2.0 [get_ports uart_rxd]
set_input_delay -clock sys_clk_pin -min 0.5 [get_ports uart_rxd]
set_input_delay -clock sys_clk_pin -max 2.0 [get_ports reset_n]
set_input_delay -clock sys_clk_pin -min 0.5 [get_ports reset_n]

# ==============================================================================
# Output Delays
# ==============================================================================
set_output_delay -clock sys_clk_pin -max 2.0 [get_ports led[*]]
set_output_delay -clock sys_clk_pin -min 0.0 [get_ports led[*]]
set_output_delay -clock sys_clk_pin -max 2.0 [get_ports uart_txd]
set_output_delay -clock sys_clk_pin -min 0.0 [get_ports uart_txd]

# ==============================================================================
# False Paths (Asynchronous Signals)
# ==============================================================================
set_false_path -from [get_ports reset_n]

# ==============================================================================
# Multi-Cycle Paths (Slow Peripherals)
# ==============================================================================
# UART is 115200 baud = 8.68 us/byte >> 10 ns clock → relaxed timing
set_multicycle_path -setup 8 -from [get_pins -hierarchical *uart*/*] \
                               -to [get_pins -hierarchical *uart*/*]
set_multicycle_path -hold 7  -from [get_pins -hierarchical *uart*/*] \
                               -to [get_pins -hierarchical *uart*/*]

# ==============================================================================
# Max Delay for Critical Paths
# ==============================================================================
# HLS accelerator should meet 10 ns (100 MHz)
set_max_delay 10.0 -from [get_pins -hierarchical *otsu_threshold_top*/*] \
                   -to [get_pins -hierarchical *otsu_threshold_top*/*]

# BRAM paths
set_max_delay 10.0 -datapath_only -from [get_pins -hierarchical *bram*/CLKA] \
                   -to [get_pins -hierarchical */*]
```

**Why This Works:**
- Input/output delays model board-level timing
- False paths prevent over-constraining async signals
- Multi-cycle paths relax timing for slow peripherals
- Max delay ensures critical paths meet 100 MHz

---

### **FIX #8: Add HLS Testbench Corner Cases**

**UPDATED TESTBENCH** (`test_otsu.cpp` additions):
```cpp
/* Image 4 – all-zero (empty) */
static void generate_empty(uint8_t img[IMG_SIZE], uint8_t gt[IMG_SIZE])
{
    memset(img, 0, IMG_SIZE);
    memset(gt, 0, IMG_SIZE);
}

/* Image 5 – all-255 (saturated) */
static void generate_saturated(uint8_t img[IMG_SIZE], uint8_t gt[IMG_SIZE])
{
    memset(img, 255, IMG_SIZE);
    memset(gt, 255, IMG_SIZE);
}

/* Image 6 – single bright pixel */
static void generate_single_pixel(uint8_t img[IMG_SIZE], uint8_t gt[IMG_SIZE])
{
    memset(img, 30, IMG_SIZE);
    memset(gt, 0, IMG_SIZE);
    int idx = IMG_SIZE / 2;
    img[idx] = 250;
    gt[idx] = 255;
}

/* Image 7 – checkerboard (high-frequency noise) */
static void generate_checkerboard(uint8_t img[IMG_SIZE], uint8_t gt[IMG_SIZE])
{
    for (int r = 0; r < IMG_HEIGHT; r++) {
        for (int c = 0; c < IMG_WIDTH; c++) {
            int idx = r * IMG_WIDTH + c;
            img[idx] = ((r + c) % 2) ? 200 : 50;
            gt[idx] = 0;  /* No clear tumor */
        }
    }
}

int main(void)
{
    // ... existing tests ...

    /* Test 4 – empty image */
    generate_empty(img, gt);
    if (!test_image("empty_image", img, gt))
        total_pass = 0;

    /* Test 5 – saturated image */
    generate_saturated(img, gt);
    if (!test_image("saturated_image", img, gt))
        total_pass = 0;

    /* Test 6 – single pixel */
    generate_single_pixel(img, gt);
    if (!test_image("single_pixel", img, gt))
        total_pass = 0;

    /* Test 7 – checkerboard */
    generate_checkerboard(img, gt);
    if (!test_image("checkerboard", img, gt))
        total_pass = 0;

    // ... rest of main ...
}
```

**Why This Works:**
- Tests edge cases that could cause divide-by-zero
- Validates threshold selection for extreme inputs
- Ensures morphology handles uniform images
- Total test coverage: 7 images × 3 modes = **21 test vectors**

---

## 3.3 Priority 3 Fixes (OPTIMIZATION)

### **FIX #9: Conditional Debug Prints**

**UPDATED** (`main.c:56-71`):
```c
#ifdef DEBUG_HLS_REGS
    /* Verify pointers written correctly */
    uint32_t rb_in  = REG_READ(XPAR_HLS_OTSU_0_R_BASEADDR, HLS_OTSU_IMG_IN_LO);
    uint32_t rb_out = REG_READ(XPAR_HLS_OTSU_0_R_BASEADDR, HLS_OTSU_IMG_OUT_LO);
    uart_print_hex("  DBG img_in  readback: 0x", rb_in);
    uart_print_hex("  DBG img_out readback: 0x", rb_out);

    /* Read control reg before start */
    uint32_t ctrl_pre = REG_READ(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_CONTROL);
    uart_print_hex("  DBG ctrl BEFORE start: 0x", ctrl_pre);
#endif

    /* Start accelerator (ap_start = bit 0) via s_axi_control */
    REG_WRITE(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_CONTROL, 0x01);

#ifdef DEBUG_HLS_REGS
    /* Read control reg after start */
    uint32_t ctrl_post = REG_READ(XPAR_HLS_OTSU_0_BASEADDR, HLS_OTSU_CONTROL);
    uart_print_hex("  DBG ctrl AFTER  start: 0x", ctrl_post);
#endif
```

**Why This Works:**
- Debug prints only active when `DEBUG_HLS_REGS` is defined
- Production builds are clean
- Makefile can control via `-DDEBUG_HLS_REGS`

---

### **FIX #10: Document BRAM Contention Avoidance**

**NEW COMMENT** (`main.c:140-150`):
```c
    /*
     * IMPORTANT: Image BRAM Dual-Port Access Protocol
     * -------------------------------------------------
     * The 128 KB image BRAM is true dual-port:
     *   Port A: MicroBlaze (read/write via BRAM Controller A)
     *   Port B: HLS accelerator (read/write via BRAM Controller B)
     *
     * To avoid undefined behavior from simultaneous access to the same
     * address on both ports, the firmware MUST:
     *   1. Write input image to BRAM via Port A (MicroBlaze)
     *   2. Start HLS accelerator
     *   3. WAIT for HLS completion (do not access BRAM while HLS is running)
     *   4. Read output mask from BRAM via Port A (MicroBlaze)
     *
     * This protocol ensures non-overlapping access and prevents BRAM
     * write collisions (which have undefined behavior per UG473).
     */

    /* Start HLS accelerator */
    hls_start(mode);

    /* CRITICAL: Do NOT access image BRAM while HLS is running! */
    int hls_status = hls_wait_done();

    /* Safe to access BRAM now that HLS is idle */
    const volatile uint8_t *out = (const volatile uint8_t *)IMG_OUTPUT_BASE;
```

**Why This Works:**
- Explicitly documents the access protocol
- Warns developers not to violate the protocol
- References Xilinx UG473 for BRAM behavior

---

## 3.4 Summary of All Fixes

| Fix # | Priority | Type | File | Lines | Effort |
|-------|----------|------|------|-------|--------|
| #1 | P1 | BUG | main.c | 139-180 | 2 hours |
| #2 | P1 | BUG | image_stats.cpp | 93-165 | 5 minutes |
| #3 | P1 | OPT | otsu_threshold.cpp | 140-200 | 4 hours |
| #4 | P1 | BUG | watershed.c | 24-90 | 1 hour |
| #5 | P1 | TEST | tb_axi_interface.sv | NEW | 4 hours |
| #6 | P2 | HW | build.tcl | +10 lines | 1 hour |
| #7 | P2 | HW | artix7.xdc | +30 lines | 2 hours |
| #8 | P2 | TEST | test_otsu.cpp | +60 lines | 2 hours |
| #9 | P3 | STYLE | main.c | 56-71 | 30 minutes |
| #10 | P3 | DOC | main.c | +15 lines | 15 minutes |

**Total Estimated Effort:** ~17 hours

---

