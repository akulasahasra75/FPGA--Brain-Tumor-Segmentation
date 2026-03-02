################################################################################
# lab_program.tcl
# ----------------
# XSCT script to build the Vitis application and program the FPGA.
#
# Usage (after lab_run.tcl has finished):
#   xsct lab_program.tcl
#
# Prerequisites:
#   - lab_run.tcl completed successfully (XSA exists)
#   - Nexys A7-100T connected via USB
#   - Vitis 2025.1 installed (xsct on PATH)
################################################################################

set script_dir [file dirname [file normalize [info script]]]
set xsa_file   "$script_dir/03_vivado_hardware/vivado_project/brain_tumor_soc.xsa"
set src_dir    "$script_dir/04_vitis_software/src"
set ws_dir     "$script_dir/vitis_workspace"
set bit_file   "$script_dir/03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/microblaze_soc_wrapper.bit"

puts "============================================================"
puts "  Brain Tumor Segmentation — Vitis Build & Program"
puts "============================================================"

# --- Verify XSA exists ---
if { ![file exists $xsa_file] } {
    puts "ERROR: XSA not found at $xsa_file"
    puts "       Run lab_run.tcl first."
    exit 1
}

# ==============================================================================
# Step 1 — Create Vitis workspace, platform, and application
# ==============================================================================
puts ">>> Creating Vitis workspace at $ws_dir ..."

if { [file exists $ws_dir] } {
    file delete -force $ws_dir
}

setws $ws_dir

# Create platform from XSA
puts ">>> Creating platform from XSA ..."
platform create \
    -name brain_tumor_platform \
    -hw $xsa_file \
    -os standalone \
    -proc microblaze_0

platform generate

# Create application
puts ">>> Creating application ..."
app create \
    -name brain_tumor_app \
    -platform brain_tumor_platform \
    -proc microblaze_0 \
    -os standalone \
    -lang c

# Copy source files
puts ">>> Importing source files ..."
set app_src "$ws_dir/brain_tumor_app/src"
foreach f [glob -nocomplain $src_dir/*.c $src_dir/*.h] {
    file copy -force $f $app_src/
    puts "  Copied: [file tail $f]"
}

# Build
puts ">>> Building application ..."
app build -name brain_tumor_app

set elf_file "$ws_dir/brain_tumor_app/Debug/brain_tumor_app.elf"
if { ![file exists $elf_file] } {
    set elf_file "$ws_dir/brain_tumor_app/Release/brain_tumor_app.elf"
}

if { [file exists $elf_file] } {
    puts ">>> ELF built: $elf_file"
} else {
    puts "ERROR: ELF not found — check build output above."
    exit 1
}

# ==============================================================================
# Step 2 — Program FPGA and run
# ==============================================================================
puts ""
puts ">>> Programming FPGA ..."

# Connect to hardware server
connect

# Find the FPGA target
targets -set -filter {name =~ "xc7a*"}
puts ">>> Loading bitstream ..."
fpga $bit_file

# Find MicroBlaze
after 1000
targets -set -filter {name =~ "MicroBlaze*"}

puts ">>> Downloading ELF ..."
dow $elf_file

puts ">>> Starting execution ..."
con

puts ""
puts "============================================================"
puts "  FPGA PROGRAMMED & RUNNING"
puts "============================================================"
puts ""
puts "  Open a serial terminal NOW (if not already open):"
puts "    - Port: check Device Manager for the USB Serial Port"
puts "    - Baud: 115200, 8-N-1"
puts ""
puts "  You should see the segmentation results printing."
puts ""
puts "  LEDs:"
puts "    LD0 = heartbeat (system alive)"
puts "    LD1 = processing"
puts "    LD2-3 = mode (00=FAST, 01=NORMAL, 10=CAREFUL)"
puts "    LD4 = done"
puts ""
puts "  Press Ctrl+C here when finished."
puts "============================================================"

# Keep connection alive so user can observe
# (xsct will exit when user presses Ctrl+C)
after 300000

