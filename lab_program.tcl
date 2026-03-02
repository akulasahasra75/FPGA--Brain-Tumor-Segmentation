################################################################################
# lab_program.tcl
# ----------------
# Vivado Tcl script to program the Nexys A7-100T FPGA.
#
# The bitstream already has the MicroBlaze ELF embedded (via embed_elf.tcl),
# so a single JTAG program operation is all that's needed.
#
# Usage:
#   vivado -mode batch -source lab_program.tcl
#
# Prerequisites:
#   - Build completed: build.tcl → mb-gcc → embed_elf.tcl
#   - Nexys A7-100T connected via USB and powered on
#   - Open a serial terminal (115200, 8N1) BEFORE running this
################################################################################

set script_dir [file dirname [file normalize [info script]]]

# --- Locate bitstream ---
# Priority: pre-built at C:/bts, then project output
set bit_file ""
foreach candidate [list \
    "C:/bts/brain_tumor_final.bit" \
    "$script_dir/03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/microblaze_soc_wrapper.bit" \
] {
    if {[file exists $candidate]} {
        set bit_file $candidate
        break
    }
}

if {$bit_file eq ""} {
    puts "ERROR: No bitstream found."
    puts "  Expected: C:/bts/brain_tumor_final.bit"
    puts "  Run the build pipeline first."
    exit 1
}

puts "============================================================"
puts "  Brain Tumor Segmentation — FPGA Programming"
puts "============================================================"
puts "  Bitstream: $bit_file"
puts ""

# --- Open hardware manager and connect ---
open_hw_manager
connect_hw_server -allow_non_jtag

set targets [get_hw_targets]
if {[llength $targets] == 0} {
    puts "ERROR: No JTAG targets found."
    puts "  Check: board powered on? USB cable connected?"
    close_hw_manager
    exit 1
}

puts "Found targets: $targets"
open_hw_target [lindex $targets 0]

# --- Find xc7a100t device ---
set devices [get_hw_devices]
set fpga_dev ""
foreach dev $devices {
    set part [get_property PART $dev]
    if {[string match "*7a100t*" $part]} {
        set fpga_dev $dev
        break
    }
}
if {$fpga_dev eq ""} {
    set fpga_dev [lindex $devices 0]
    puts "WARNING: xc7a100t not found, using first device: $fpga_dev"
}

# --- Program ---
puts "Programming $fpga_dev ..."
current_hw_device $fpga_dev
set_property PROGRAM.FILE $bit_file $fpga_dev
program_hw_devices $fpga_dev

puts ""
puts "============================================================"
puts "  FPGA Programmed Successfully!"
puts "============================================================"
puts ""
puts "  The MicroBlaze is running — check the serial terminal."
puts "  Port: COMx (see Device Manager > Ports)"
puts "  Baud: 115200, 8-N-1"
puts ""
puts "  LEDs:"
puts "    LD0 = heartbeat     LD1 = processing"
puts "    LD2-3 = mode        LD4 = done"
puts "============================================================"

close_hw_target
disconnect_hw_server
close_hw_manager

