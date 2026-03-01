################################################################################
# run_hls.tcl
# -------------
# Vitis HLS script for the Otsu threshold accelerator.
#
# Usage:
#   vitis-run --tcl --input_file run_hls.tcl
#   (Vitis 2025.1: vitis_hls is now vitis-run)
#
# Target: Xilinx Artix-7 (xc7a35tcpg236-1)
# Clock : 100 MHz (10 ns period)
################################################################################

# --- Project settings --------------------------------------------------------
set PROJECT_NAME  "otsu_hls"
set SOLUTION_NAME "solution1"
set TOP_FUNCTION  "otsu_threshold_top"
set PART          "xc7a35tcpg236-1"
set CLOCK_PERIOD  10

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
              -description "Otsu Threshold Accelerator – 3 modes (FAST/NORMAL/CAREFUL)" \
              -vendor "custom" \
              -library "hls" \
              -version "1.0" \
              -display_name "otsu_threshold"
puts "===> IP Export complete."

# --- Done! --------------------------------------------------------------------
puts ""
puts "=============================================="
puts "  HLS flow finished successfully."
puts "  IP core is in: ${PROJECT_NAME}/${SOLUTION_NAME}/impl/ip"
puts "=============================================="

exit
