################################################################################
# lab_build_sw.ps1
# -----------------
# Builds the MicroBlaze software and embeds it into the FPGA bitstream.
#
# Usage:
#   powershell -ExecutionPolicy Bypass -File lab_build_sw.ps1
#
# Prerequisites:
#   - Vivado build completed (build.tcl produced the initial bitstream + XSA)
#   - Vivado 2025.1 installed at D:\2025.1
#
# What it does:
#   1. Compiles all C source files with mb-gcc (no Vitis needed!)
#   2. Links into MicroBlaze ELF with custom linker script
#   3. Uses Vivado to embed ELF into bitstream (via BRAM init)
#   4. Produces C:/bts/brain_tumor_final.bit ready for FPGA programming
################################################################################

$ErrorActionPreference = "Stop"

# --- Paths ---
$VIVADO  = "D:\2025.1\Vivado\bin\vivado.bat"
$MBGCC   = "D:\2025.1\gnu\microblaze\nt\bin\mb-gcc.exe"
$MBSIZE  = "D:\2025.1\gnu\microblaze\nt\bin\mb-size.exe"
$PROJECT = Split-Path -Parent $PSScriptRoot
if (-not $PROJECT) { $PROJECT = (Get-Location).Path }

$SRC_DIR = "$PROJECT\04_vitis_software\src"
$BUILD   = "C:\bts\build"
$LDSCRIPT = "$PROJECT\04_vitis_software\lscript.ld"
$STUBS   = "$PROJECT\04_vitis_software\mb_stubs.c"

# Check tools
if (-not (Test-Path $MBGCC))  { Write-Error "mb-gcc not found at $MBGCC"; exit 1 }
if (-not (Test-Path $VIVADO)) { Write-Error "Vivado not found at $VIVADO"; exit 1 }

# Create build dir
New-Item -ItemType Directory -Path $BUILD -Force | Out-Null

Write-Host "============================================================"
Write-Host "  Brain Tumor Segmentation - MicroBlaze Software Build"
Write-Host "============================================================"
Write-Host "  Source: $SRC_DIR"
Write-Host "  Build:  $BUILD"
Write-Host ""

# --- Step 1: Compile ---
Write-Host ">>> Step 1: Compiling ..."
$sources = @("main","uart_debug","image_loader","adaptive_controller","energy_analyzer","watershed")
foreach ($f in $sources) {
    Write-Host "  CC $f.c"
    & $MBGCC "-mcpu=v11.0" "-Os" "-Wall" "-ffunction-sections" "-fdata-sections" `
        "-I$SRC_DIR" "-c" "$SRC_DIR\$f.c" "-o" "$BUILD\$f.o" 2>&1
    if ($LASTEXITCODE -ne 0) { Write-Error "Compilation failed: $f.c"; exit 1 }
}

# Compile stubs
Write-Host "  CC mb_stubs.c"
& $MBGCC "-mcpu=v11.0" "-Os" "-c" $STUBS "-o" "$BUILD\mb_stubs.o" 2>&1
if ($LASTEXITCODE -ne 0) { Write-Error "Compilation failed: mb_stubs.c"; exit 1 }

# --- Step 2: Link ---
Write-Host "`n>>> Step 2: Linking ..."
$objs = (Get-ChildItem "$BUILD\*.o").FullName
& $MBGCC "-mcpu=v11.0" "-Os" "-nodefaultlibs" "-Wl,--gc-sections" `
    "-T" $LDSCRIPT $objs "-lgcc" "-lc" "-lgcc" "-o" "$BUILD\brain_tumor.elf" 2>&1
if ($LASTEXITCODE -ne 0) { Write-Error "Link failed"; exit 1 }

Write-Host "  ELF: $BUILD\brain_tumor.elf"
& $MBSIZE "$BUILD\brain_tumor.elf"

# Check size fits in 64KB
$elfInfo = & $MBSIZE "$BUILD\brain_tumor.elf" 2>&1
$totalLine = ($elfInfo | Select-Object -Last 1)
if ($totalLine -match "(\d+)\s+(\d+)\s+(\d+)\s+(\d+)") {
    $total = [int]$Matches[4]
    $pct = [math]::Round($total / 65536 * 100, 1)
    Write-Host "  Total: $total bytes ($pct% of 64KB BRAM)"
    if ($total -gt 65536) {
        Write-Error "ELF too large for 64KB BRAM! ($total bytes)"
        exit 1
    }
}

# --- Step 3: Embed ELF into bitstream ---
Write-Host "`n>>> Step 3: Embedding ELF into bitstream (Vivado) ..."

# Map to short path if needed
$shortProject = $PROJECT
if ($PROJECT.Length -gt 100) {
    subst Z: $PROJECT 2>$null
    $shortProject = "Z:"
}

$tclScript = @"
set project_dir "$($shortProject -replace '\\','/')/03_vivado_hardware/vivado_project"
open_project `$project_dir/brain_tumor_soc.xpr
set elf_file "C:/bts/build/brain_tumor.elf"
catch {remove_files [get_files *.elf]}
add_files -norecurse `$elf_file
set_property SCOPED_TO_REF  microblaze_soc [get_files [file tail `$elf_file]]
set_property SCOPED_TO_CELLS microblaze_0  [get_files [file tail `$elf_file]]
reset_run impl_1 -from_step write_bitstream
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
set bit "`$project_dir/brain_tumor_soc.runs/impl_1/microblaze_soc_wrapper.bit"
file copy -force `$bit C:/bts/brain_tumor_final.bit
puts "BITSTREAM_OK"
close_project
"@

$tclScript | Out-File -Encoding ascii "C:\bts\embed_elf_auto.tcl"
& $VIVADO -mode batch -source "C:\bts\embed_elf_auto.tcl" 2>&1 | Tee-Object -FilePath "C:\bts\embed_log.txt"

if (Test-Path "C:\bts\brain_tumor_final.bit") {
    $bitSize = (Get-Item "C:\bts\brain_tumor_final.bit").Length
    Write-Host "`n============================================================"
    Write-Host "  BUILD COMPLETE!"
    Write-Host "============================================================"
    Write-Host "  Bitstream: C:\bts\brain_tumor_final.bit ($bitSize bytes)"
    Write-Host ""
    Write-Host "  To program FPGA:"
    Write-Host "    vivado -mode batch -source lab_program.tcl"
    Write-Host ""
    Write-Host "  Or in Vivado GUI:"
    Write-Host "    Flow > Open Hardware Manager > Auto Connect > Program Device"
    Write-Host "============================================================"
} else {
    Write-Error "Bitstream generation failed! Check C:\bts\embed_log.txt"
    exit 1
}
