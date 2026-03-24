################################################################################
# build_all.ps1
# --------------
# ONE-CLICK BUILD SCRIPT for Brain Tumor Segmentation FPGA Project
#
# This script builds EVERYTHING from source:
#   1. HLS synthesis (Otsu accelerator)
#   2. Vivado hardware build (MicroBlaze SoC)
#   3. MicroBlaze firmware compilation
#   4. ELF embedding into bitstream
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File build_all.ps1
#
# Prerequisites:
#   - Xilinx Vivado/Vitis 2025.1 installed at D:\2025.1
#   - ~40-60 minutes for full build
#
# Output:
#   - C:\bts\brain_tumor_final.bit (ready to program FPGA)
################################################################################

$ErrorActionPreference = "Stop"
$StartTime = Get-Date

# ==============================================================================
# Configuration
# ==============================================================================
$XILINX_ROOT = "D:\2025.1"
$VIVADO      = "$XILINX_ROOT\Vivado\bin\vivado.bat"
$VITIS_RUN   = "$XILINX_ROOT\Vitis\bin\vitis-run.bat"
$MBGCC       = "$XILINX_ROOT\gnu\microblaze\nt\bin\mb-gcc.exe"
$MBSIZE      = "$XILINX_ROOT\gnu\microblaze\nt\bin\mb-size.exe"

$PROJECT     = Split-Path -Parent $MyInvocation.MyCommand.Path
$HLS_DIR     = "$PROJECT\02_hls_accelerator"
$VIVADO_DIR  = "$PROJECT\03_vivado_hardware"
$SW_DIR      = "$PROJECT\04_vitis_software"
$BUILD_DIR   = "C:\bts"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Brain Tumor Segmentation - Complete Build System" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  Target: Nexys A7-100T (Artix-7 xc7a100tcsg324-1)"
Write-Host "  Project: $PROJECT"
Write-Host "  Started: $StartTime"
Write-Host ""

# ==============================================================================
# Step 1: Verify Prerequisites
# ==============================================================================
Write-Host ">>> Step 1: Checking prerequisites..." -ForegroundColor Yellow

$missing = @()
if (-not (Test-Path $VIVADO))   { $missing += "Vivado ($VIVADO)" }
if (-not (Test-Path $VITIS_RUN)) { $missing += "Vitis HLS ($VITIS_RUN)" }
if (-not (Test-Path $MBGCC))    { $missing += "MicroBlaze GCC ($MBGCC)" }

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "ERROR: Missing required tools:" -ForegroundColor Red
    foreach ($m in $missing) {
        Write-Host "  - $m" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "Please install Xilinx Vivado/Vitis 2025.1 at $XILINX_ROOT"
    exit 1
}

Write-Host "  [OK] Vivado found"
Write-Host "  [OK] Vitis HLS found"
Write-Host "  [OK] MicroBlaze GCC found"
Write-Host ""

# Create output directory
New-Item -ItemType Directory -Path $BUILD_DIR -Force | Out-Null
New-Item -ItemType Directory -Path "$BUILD_DIR\build" -Force | Out-Null

# ==============================================================================
# Step 2: HLS Synthesis (Optional - skip if IP already exists)
# ==============================================================================
Write-Host ">>> Step 2: HLS Synthesis..." -ForegroundColor Yellow

$hlsIP = "$VIVADO_DIR\ip_repo\component.xml"
$runHLS = $true

if (Test-Path $hlsIP) {
    Write-Host "  HLS IP already exists at: $hlsIP"
    $response = Read-Host "  Re-run HLS synthesis? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        $runHLS = $false
        Write-Host "  [SKIP] Using existing HLS IP"
    }
}

if ($runHLS) {
    Write-Host "  Running HLS synthesis (this takes 5-10 minutes)..."

    Push-Location $HLS_DIR
    try {
        # Vitis 2025.1 uses vitis-run for HLS
        & $VITIS_RUN --mode hls --tcl run_hls.tcl 2>&1 | Tee-Object -FilePath "$BUILD_DIR\hls_log.txt"

        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "ERROR: HLS synthesis failed!" -ForegroundColor Red
            Write-Host "Check log: $BUILD_DIR\hls_log.txt"
            exit 1
        }

        # Copy HLS IP to ip_repo
        $hlsOutput = "$HLS_DIR\otsu_hls\solution1\impl\ip"
        if (Test-Path $hlsOutput) {
            Write-Host "  Copying HLS IP to ip_repo..."
            Copy-Item -Path "$hlsOutput\*" -Destination "$VIVADO_DIR\ip_repo\" -Recurse -Force
        }
    }
    finally {
        Pop-Location
    }

    Write-Host "  [OK] HLS synthesis complete"
}
Write-Host ""

# ==============================================================================
# Step 3: Vivado Hardware Build
# ==============================================================================
Write-Host ">>> Step 3: Vivado Hardware Build..." -ForegroundColor Yellow

$bitFile = "$VIVADO_DIR\vivado_project\brain_tumor_soc.runs\impl_1\microblaze_soc_wrapper.bit"
$xsaFile = "$VIVADO_DIR\vivado_project\brain_tumor_soc.xsa"
$runVivado = $true

if ((Test-Path $bitFile) -and (Test-Path $xsaFile)) {
    Write-Host "  Bitstream already exists: $bitFile"
    $response = Read-Host "  Rebuild hardware? (y/N)"
    if ($response -ne "y" -and $response -ne "Y") {
        $runVivado = $false
        Write-Host "  [SKIP] Using existing bitstream"
    }
}

if ($runVivado) {
    Write-Host "  Running Vivado build (this takes 25-45 minutes)..."

    Push-Location $VIVADO_DIR
    try {
        & $VIVADO -mode batch -source build.tcl 2>&1 | Tee-Object -FilePath "$BUILD_DIR\vivado_log.txt"

        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "ERROR: Vivado build failed!" -ForegroundColor Red
            Write-Host "Check log: $BUILD_DIR\vivado_log.txt"
            exit 1
        }
    }
    finally {
        Pop-Location
    }

    Write-Host "  [OK] Vivado build complete"
}
Write-Host ""

# ==============================================================================
# Step 4: Compile MicroBlaze Firmware
# ==============================================================================
Write-Host ">>> Step 4: Compiling MicroBlaze firmware..." -ForegroundColor Yellow

$SRC_DIR   = "$SW_DIR\src"
$LDSCRIPT  = "$SW_DIR\lscript.ld"
$BLD       = "$BUILD_DIR\build"

# Compile all source files
$sources = @("main","uart_debug","image_loader","adaptive_controller","energy_analyzer","watershed","mb_stubs")
foreach ($f in $sources) {
    $srcFile = "$SRC_DIR\$f.c"
    if (-not (Test-Path $srcFile)) {
        Write-Host "  WARNING: Source file not found: $srcFile" -ForegroundColor Yellow
        continue
    }
    Write-Host "  CC $f.c"
    & $MBGCC -mcpu=v11.0 -Os -Wall -ffunction-sections -fdata-sections `
        -I"$SRC_DIR" -c "$srcFile" -o "$BLD\$f.o" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: Compilation failed: $f.c" -ForegroundColor Red
        exit 1
    }
}

# Link
Write-Host "  Linking..."
$objs = (Get-ChildItem "$BLD\*.o").FullName
& $MBGCC -mcpu=v11.0 -Os -nodefaultlibs -Wl,--gc-sections `
    -T "$LDSCRIPT" $objs -lgcc -lc -lgcc -o "$BLD\brain_tumor.elf" 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Link failed!" -ForegroundColor Red
    exit 1
}

# Check size
Write-Host ""
& $MBSIZE "$BLD\brain_tumor.elf"
$elfInfo = & $MBSIZE "$BLD\brain_tumor.elf" 2>&1
$totalLine = ($elfInfo | Select-Object -Last 1)
if ($totalLine -match "(\d+)\s+(\d+)\s+(\d+)\s+(\d+)") {
    $total = [int]$Matches[4]
    $pct = [math]::Round($total / 65536 * 100, 1)
    Write-Host "  Total: $total bytes ($pct% of 64KB BRAM)"
    if ($total -gt 65536) {
        Write-Host "ERROR: ELF too large for 64KB BRAM! ($total bytes)" -ForegroundColor Red
        exit 1
    }
}
Write-Host "  [OK] Firmware compiled: $BLD\brain_tumor.elf"
Write-Host ""

# ==============================================================================
# Step 5: Embed ELF into Bitstream
# ==============================================================================
Write-Host ">>> Step 5: Embedding ELF into bitstream..." -ForegroundColor Yellow

$tclScript = @"
set project_dir [file normalize "$($VIVADO_DIR -replace '\\','/')/vivado_project"]
open_project `$project_dir/brain_tumor_soc.xpr
set elf_file [file normalize "$($BLD -replace '\\','/')/brain_tumor.elf"]
puts "ELF file: `$elf_file"
catch {remove_files [get_files *.elf]}
add_files -norecurse `$elf_file
set_property SCOPED_TO_REF  microblaze_soc [get_files [file tail `$elf_file]]
set_property SCOPED_TO_CELLS microblaze_0  [get_files [file tail `$elf_file]]
reset_run impl_1 -from_step write_bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
set bit "`$project_dir/brain_tumor_soc.runs/impl_1/microblaze_soc_wrapper.bit"
file copy -force `$bit [file normalize "$($BUILD_DIR -replace '\\','/')/brain_tumor_final.bit"]
puts "BITSTREAM GENERATED SUCCESSFULLY"
close_project
"@

$tclScript | Out-File -Encoding ascii "$BUILD_DIR\embed_elf.tcl"
& $VIVADO -mode batch -source "$BUILD_DIR\embed_elf.tcl" 2>&1 | Tee-Object -FilePath "$BUILD_DIR\embed_log.txt"

$finalBit = "$BUILD_DIR\brain_tumor_final.bit"
if (-not (Test-Path $finalBit)) {
    Write-Host ""
    Write-Host "ERROR: Bitstream generation failed!" -ForegroundColor Red
    Write-Host "Check log: $BUILD_DIR\embed_log.txt"
    exit 1
}

$bitSize = (Get-Item $finalBit).Length
$EndTime = Get-Date
$Duration = $EndTime - $StartTime

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  BUILD COMPLETE!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Output Files:"
Write-Host "  - Bitstream: $finalBit"
Write-Host "    Size: $([math]::Round($bitSize / 1MB, 2)) MB"
Write-Host ""
Write-Host "  - ELF: $BLD\brain_tumor.elf"
Write-Host ""
Write-Host "  Build Duration: $($Duration.ToString('hh\:mm\:ss'))"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  NEXT STEPS - Program the FPGA" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Option 1: Use the programming script"
Write-Host "    vivado -mode batch -source lab_program.tcl"
Write-Host ""
Write-Host "  Option 2: Use Vivado GUI"
Write-Host "    1. Open Vivado"
Write-Host "    2. Flow > Open Hardware Manager"
Write-Host "    3. Open Target > Auto Connect"
Write-Host "    4. Program Device > Select $finalBit"
Write-Host ""
Write-Host "  Option 3: Quick program (PowerShell)"
Write-Host "    .\program_fpga.ps1"
Write-Host ""
Write-Host "  After programming:"
Write-Host "    1. Connect USB-UART to PC"
Write-Host "    2. Open serial terminal: 115200 baud, 8-N-1"
Write-Host "    3. You should see 'Brain Tumor Segmentation' banner"
Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
