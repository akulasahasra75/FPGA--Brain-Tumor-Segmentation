# 03_vivado_hardware

## Purpose

Vivado hardware platform: integrates the HLS IP core with MicroBlaze processor for the Nexys A7 FPGA board.

## Files

- **`build.tcl`** - Main Vivado build script (creates block design, generates bitstream, exports XSA)
- **`build_demo.tcl`** - Demo build script for standalone testing
- **`build_demo.bat`** - Windows batch script for demo build
- **`program_fpga.tcl`** - Programs the FPGA with the generated bitstream via JTAG
- **`program_demo.tcl`** - Programs FPGA with demo bitstream
- **`program_demo.bat`** - Windows batch script for demo programming
- **`constraints/`** - Timing and pin constraint files (XDC)
- **`srcs/verilog/`** - Verilog source files (top_module, AXI interface, BRAM controller, demo)
- **`ip_repo/`** - HLS IP core repository (copied from 02_hls_accelerator)

## Generated Outputs

- **`vivado_project/`** - Main Vivado project (generated)
- **`vivado_project_demo/`** - Demo Vivado project (generated)
- **`brain_tumor_demo.bit`** - Pre-built demo bitstream
- **`brain_tumor_demo_utilization.rpt`** - Resource utilization report

## Usage

```bash
# Build the hardware (run Vivado in batch mode)
vivado -mode batch -source build.tcl

# Program the FPGA
vivado -mode batch -source program_fpga.tcl
```

## System Architecture

- **MicroBlaze** soft processor @ 100 MHz
- **AXI Interconnect** for peripheral communication
- **Otsu Threshold IP** (from HLS)
- **UART** for console communication (115200 baud)
- **GPIO** for status LEDs
- **Block RAM** for instruction/data memory

## Target Board

- **Digilent Nexys A7-100T** (xc7a100tcsg324-1)
- USB-JTAG for programming
- USB-UART for serial communication
