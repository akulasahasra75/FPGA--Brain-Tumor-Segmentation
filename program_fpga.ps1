################################################################################
# program_fpga.ps1
# -----------------
# Programs the Nexys A7-100T FPGA with the brain tumor segmentation design.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File program_fpga.ps1
#
# Prerequisites:
#   - build_all.ps1 completed successfully (C:\bts\brain_tumor_final.bit exists)
#   - Nexys A7-100T connected via USB
################################################################################

$ErrorActionPreference = "Stop"

$VIVADO   = "D:\2025.1\Vivado\bin\vivado.bat"
$BITFILE  = "C:\bts\brain_tumor_final.bit"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Brain Tumor Segmentation - FPGA Programming" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# Check bitstream exists
if (-not (Test-Path $BITFILE)) {
    Write-Host "ERROR: Bitstream not found: $BITFILE" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run build_all.ps1 first to generate the bitstream."
    exit 1
}

Write-Host "  Bitstream: $BITFILE"
Write-Host ""
Write-Host "  Programming FPGA (ensure Nexys A7-100T is connected)..."
Write-Host ""

# Create TCL script for programming
$tclScript = @"
open_hw_manager
connect_hw_server -allow_non_jtag
open_hw_target

# Find the FPGA device
set device [lindex [get_hw_devices xc7a100t*] 0]
if {`$device eq ""} {
    puts "ERROR: Artix-7 device not found!"
    puts "       Make sure Nexys A7-100T is connected and powered on."
    exit 1
}
puts "Found device: `$device"

current_hw_device `$device
set_property PROGRAM.FILE {$($BITFILE -replace '\\','/')} [current_hw_device]
program_hw_devices [current_hw_device]

puts ""
puts "============================================================"
puts "  PROGRAMMING COMPLETE!"
puts "============================================================"
puts ""
puts "  The FPGA is now running the brain tumor segmentation design."
puts ""
puts "  NEXT: Connect a serial terminal to view output"
puts "        - Port: COMx (check Device Manager)"
puts "        - Baud: 115200"
puts "        - Settings: 8-N-1"
puts ""
puts "  You should see:"
puts "    ========================================"
puts "     Brain Tumor Segmentation – FPGA SoC"
puts "     Nexys A7-100T / Artix-7 / MicroBlaze"
puts "    ========================================"
puts ""

close_hw_manager
"@

$tclScript | Out-File -Encoding ascii "C:\bts\program.tcl"

& $VIVADO -mode batch -source "C:\bts\program.tcl" 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Programming may have failed. Check:" -ForegroundColor Yellow
    Write-Host "  1. Is Nexys A7-100T connected via USB?"
    Write-Host "  2. Is the board powered on?"
    Write-Host "  3. Are Digilent drivers installed?"
    Write-Host ""
}
