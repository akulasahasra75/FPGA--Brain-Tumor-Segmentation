################################################################################
# run_hls.tcl
# -------------
# Vitis HLS script for the Otsu threshold accelerator.
#
# Usage (Vitis HLS 2023.x / 2024.x / 2025.x):
#   vitis_hls -f run_hls.tcl
#
# Target: Xilinx Artix-7 (xc7a100tcsg324-1, Nexys A7-100T)
# Clock : 100 MHz (10 ns period)
#
# ============================================================================
# PERFORMANCE OPTIMIZATION NOTES
# ============================================================================
# This script configures HLS for production-level synthesis:
#   - Aggressive loop pipelining (II=1 target)
#   - Complete histogram partitioning (8K FFs for zero bank conflicts)
#   - Line-buffer morphology (minimal BRAM bandwidth)
#   - AXI burst optimization (max burst length 64)
#
# Expected synthesis results:
#   - MODE_FAST latency:    ~35K cycles (0.35 ms @ 100 MHz)
#   - MODE_NORMAL latency:  ~72K cycles (0.72 ms)
#   - MODE_CAREFUL latency: ~125K cycles (1.25 ms)
#   - Resource: ~15% BRAM, ~10% FF, ~13% LUT, ~6% DSP
# ============================================================================
################################################################################

# --- Project settings --------------------------------------------------------
set PROJECT_NAME  "otsu_hls"
set SOLUTION_NAME "solution1"
set TOP_FUNCTION  "otsu_threshold_top"
set PART          "xc7a100tcsg324-1"
set CLOCK_PERIOD  10
set CLOCK_UNCERTAINTY 1.25

# --- Create / open project ---------------------------------------------------
open_project ${PROJECT_NAME} -reset

# --- Source files -------------------------------------------------------------
add_files otsu_threshold.cpp
add_files otsu_threshold.h
add_files image_stats.cpp
add_files image_stats.h

# --- Testbench files ----------------------------------------------------------
add_files -tb test_otsu.cpp

# --- Set top function ---------------------------------------------------------
set_top ${TOP_FUNCTION}

# --- Create solution ----------------------------------------------------------
open_solution ${SOLUTION_NAME} -reset

# --- Target FPGA and clock ----------------------------------------------------
set_part ${PART}
create_clock -period ${CLOCK_PERIOD} -name default

# --- Clock uncertainty for timing margin --------------------------------------
set_clock_uncertainty ${CLOCK_UNCERTAINTY}

# =============================================================================
# HLS CONFIGURATION - Performance Optimization
# =============================================================================

# Enable aggressive optimizations
config_compile -pipeline_loops 1
config_schedule -effort high
config_bind -effort high

# AXI interface optimization
config_interface -m_axi_conservative_mode=0
config_interface -m_axi_max_widen_bitwidth 64
config_interface -m_axi_addr64

# Array optimizations
config_array_partition -complete_threshold 256
config_array_partition -throughput_driven

# =============================================================================
# STEP 1: C Simulation  (compile + run testbench on desktop)
# =============================================================================
puts "===> Running C Simulation..."
csim_design -clean
puts "===> C Simulation complete."

# =============================================================================
# STEP 2: Synthesis  (convert C++ to RTL)
# =============================================================================
puts "===> Running C Synthesis..."
csynth_design
puts "===> C Synthesis complete."

# =============================================================================
# STEP 3: Co-Simulation  (optional – very slow for large images)
#   Uncomment the next two lines to run RTL co-simulation:
#   cosim_design -trace_level all
#   puts "===> Co-Simulation complete."
# =============================================================================

# =============================================================================
# STEP 4: Export IP  (package as Vivado IP core)
# =============================================================================
puts "===> Exporting IP..."
export_design -format ip_catalog \
              -description "Otsu Threshold Accelerator – 3 modes (FAST/NORMAL/CAREFUL) - Performance Optimized" \
              -vendor "custom" \
              -library "hls" \
              -version "2.0" \
              -display_name "otsu_threshold_v2"
puts "===> IP Export complete."

# =============================================================================
# STEP 5: Generate Synthesis Report Summary
# =============================================================================
puts ""
puts "=============================================="
puts "  HLS Synthesis Results Summary"
puts "=============================================="
puts ""
puts "Project: ${PROJECT_NAME}"
puts "Solution: ${SOLUTION_NAME}"
puts "Target: ${PART} @ [expr {1000.0/${CLOCK_PERIOD}}] MHz"
puts ""
puts "IP core location: ${PROJECT_NAME}/${SOLUTION_NAME}/impl/ip"
puts ""
puts "To view detailed reports:"
puts "  - Synthesis: ${PROJECT_NAME}/${SOLUTION_NAME}/syn/report"
puts "  - Timing:    ${PROJECT_NAME}/${SOLUTION_NAME}/impl/report"
puts ""
puts "=============================================="

exit
