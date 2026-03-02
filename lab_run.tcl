################################################################################
# lab_run.tcl
# ------------
# ONE-CLICK LAB SCRIPT — builds everything and programs the FPGA.
#
# Usage (run from the project root directory):
#
#   vivado -mode batch -source lab_run.tcl
#
# What it does:
#   1. Builds the Vivado hardware (calls 03_vivado_hardware/build.tcl)
#   2. Exports the .xsa hardware platform
#   3. Prints next-step instructions for Vitis
#
# Prerequisites:
#   - Vivado 2025.1 on PATH
#   - Digilent board files installed
#   - HLS IP already in 03_vivado_hardware/ip_repo/ (done)
#
# Time estimate: 25–45 minutes (synthesis + implementation + bitstream)
################################################################################

set script_dir [file dirname [file normalize [info script]]]
puts "============================================================"
puts "  Brain Tumor Segmentation — Automated Lab Build"
puts "  Project root: $script_dir"
puts "============================================================"
puts ""

# ==============================================================================
# Step 1 — Verify prerequisites
# ==============================================================================
set ip_repo "$script_dir/03_vivado_hardware/ip_repo"
set component "$ip_repo/component.xml"

if { ![file exists $component] } {
    puts "ERROR: HLS IP not found at $ip_repo"
    puts "       Expected: $component"
    puts "       Run the HLS flow first, then copy the IP to ip_repo/."
    exit 1
}
puts "OK: HLS IP found in ip_repo/"

# ==============================================================================
# Step 2 — Run the Vivado build
# ==============================================================================
puts ""
puts ">>> Starting Vivado hardware build (this takes 25-45 minutes)..."
puts ""

cd "$script_dir/03_vivado_hardware"
source build.tcl

# ==============================================================================
# Step 3 — Verify outputs
# ==============================================================================
set xsa_file "$script_dir/03_vivado_hardware/vivado_project/brain_tumor_soc.xsa"
set bit_file "$script_dir/03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/microblaze_soc_wrapper.bit"

puts ""
puts "============================================================"
puts "  BUILD COMPLETE"
puts "============================================================"

if { [file exists $xsa_file] } {
    puts "  XSA file : $xsa_file"
} else {
    puts "  WARNING: XSA file not found — check build log for errors."
}

if { [file exists $bit_file] } {
    puts "  Bitstream: $bit_file"
} else {
    puts "  WARNING: Bitstream not found — check build log for errors."
}

puts ""
puts "============================================================"
puts "  NEXT STEPS (do these manually in Vitis):"
puts "============================================================"
puts ""
puts "  1. Launch Vitis:"
puts "       vitis"
puts ""
puts "  2. Create Platform Project:"
puts "       - File > New > Platform Project"
puts "       - Name: brain_tumor_platform"
puts "       - XSA:  $xsa_file"
puts "       - OS: standalone,  Processor: microblaze_0"
puts "       - Build the platform"
puts ""
puts "  3. Create Application Project:"
puts "       - File > New > Application Project"
puts "       - Platform: brain_tumor_platform"
puts "       - Name: brain_tumor_app"
puts "       - Template: Empty Application (C)"
puts ""
puts "  4. Import source files:"
puts "       - Right-click brain_tumor_app/src > Import > File System"
puts "       - Browse to: $script_dir/04_vitis_software/src/"
puts "       - Select ALL .c and .h files"
puts ""
puts "  5. Build:"
puts "       - Right-click project > Build"
puts ""
puts "  6. Run on hardware:"
puts "       - Open serial terminal (PuTTY/TeraTerm): 115200 baud, 8-N-1"
puts "       - Right-click brain_tumor_app > Run As > Launch on Hardware"
puts ""
puts "  OR use XSCT command-line (faster):"
puts "       xsct $script_dir/lab_program.tcl"
puts ""
puts "============================================================"

