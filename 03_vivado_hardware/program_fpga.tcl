################################################################################
# program_fpga.tcl
# -----------------
# Programs the Nexys A7-100T with the brain_tumor_soc bitstream using
# Vivado Hardware Manager (JTAG).
#
# Usage (Vivado 2023.x):
#   vivado -mode batch -source program_fpga.tcl
################################################################################

set SCRIPT_DIR [file dirname [file normalize [info script]]]
set BIT_FILE "$SCRIPT_DIR/vivado_project/brain_tumor_soc.runs/impl_1/top_module.bit"

if { ![file exists $BIT_FILE] } {
    puts "ERROR: Bitstream not found at: $BIT_FILE"
    puts "       Run build.tcl first to generate the bitstream."
    exit 1
}

puts "INFO: Opening Hardware Manager..."
open_hw_manager

puts "INFO: Connecting to hw_server (local)..."
connect_hw_server -url localhost:3121 -allow_non_jtag

puts "INFO: Opening hardware target..."
open_hw_target

puts "INFO: Available devices:"
foreach dev [get_hw_devices] {
    puts "  $dev"
}

# Select Artix-7 device (xc7a100t)
set device [lindex [get_hw_devices xc7a100t_0] 0]
if { $device eq "" } {
    set device [lindex [get_hw_devices] 0]
    puts "WARNING: Could not find xc7a100t_0 by name, using: $device"
}

puts "INFO: Programming device: $device"
puts "INFO: Bitstream: $BIT_FILE"

refresh_hw_device -update_hw_probes false $device
set_property PROGRAM.FILE $BIT_FILE $device
program_hw_devices $device
refresh_hw_device $device

puts ""
puts "=============================================="
puts "  FPGA programmed successfully!"
puts "  Connect a serial terminal at 115200 baud"
puts "  to the Nexys A7 USB-UART port to see output."
puts "=============================================="

close_hw_target
disconnect_hw_server
close_hw_manager
exit
