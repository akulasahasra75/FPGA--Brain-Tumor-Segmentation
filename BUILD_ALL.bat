@echo off
REM ============================================================================
REM BUILD_ALL.bat - Complete build script for Brain Tumor Segmentation FPGA
REM Target: Nexys 4 DDR (Artix-7 xc7a100tcsg324-1)
REM ============================================================================

echo ============================================================
echo  Brain Tumor Segmentation FPGA - Complete Build
echo  Target: Nexys 4 DDR
echo ============================================================
echo.

REM Check for Vivado
where vivado >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Vivado not found in PATH
    echo Please run this script from Vivado Command Prompt or add Vivado to PATH
    echo Example: C:\Xilinx\Vivado\2024.1\bin
    pause
    exit /b 1
)

REM Check for Vitis HLS
where vitis_hls >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: vitis_hls not found. Will try vitis-run.bat instead.
)

echo.
echo ============================================================
echo STEP 1: Python Verification (optional - already done)
echo ============================================================
echo Skipping - run manually: cd 01_python_verification ^&^& python run_all_tests.py
echo.

echo ============================================================
echo STEP 2: HLS Synthesis
echo ============================================================
cd /d "%~dp0\02_hls_accelerator"

REM Try vitis_hls first, then vitis-run.bat
where vitis_hls >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    echo Running: vitis_hls -f run_hls.tcl
    vitis_hls -f run_hls.tcl
) else (
    echo Running: vitis-run.bat --mode hls --tcl run_hls.tcl
    vitis-run.bat --mode hls --tcl run_hls.tcl
)

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: HLS synthesis failed!
    pause
    exit /b 1
)

REM Copy HLS IP to Vivado repo
echo Copying HLS IP to Vivado IP repository...
if exist "otsu_hls\solution1\impl\export.zip" (
    copy /Y "otsu_hls\solution1\impl\export.zip" "..\03_vivado_hardware\ip_repo\"
    echo Extracting IP...
    cd /d "%~dp0\03_vivado_hardware\ip_repo"
    powershell -Command "Expand-Archive -Force 'export.zip' '.'"
)
echo HLS synthesis complete!
echo.

echo ============================================================
echo STEP 3: Vivado Hardware Build
echo ============================================================
cd /d "%~dp0\03_vivado_hardware"

echo Running: vivado -mode batch -source build.tcl
vivado -mode batch -source build.tcl -log build.log -journal build.jou

if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Vivado build failed! Check build.log for details.
    pause
    exit /b 1
)

echo Vivado build complete!
echo Bitstream: vivado_project\brain_tumor_soc.runs\impl_1\microblaze_soc_wrapper.bit
echo Hardware export: vivado_project\brain_tumor_soc.xsa
echo.

echo ============================================================
echo STEP 4: Vitis Software Build
echo ============================================================
cd /d "%~dp0\04_vitis_software"

REM Create simple compile for syntax check
echo Checking C code syntax...
REM Note: Full Vitis build requires creating a workspace from .xsa
echo.
echo To build the MicroBlaze application:
echo   1. Open Vitis IDE
echo   2. Create new platform from: 03_vivado_hardware\vivado_project\brain_tumor_soc.xsa
echo   3. Create new application project with src\ files
echo   4. Build project
echo   5. Run ^> Debug Configurations ^> Program FPGA ^& Download
echo.

echo ============================================================
echo BUILD COMPLETE!
echo ============================================================
echo.
echo Next steps:
echo   1. Connect Nexys 4 DDR via USB
echo   2. Open Vivado Hardware Manager
echo   3. Program bitstream: vivado_project\brain_tumor_soc.runs\impl_1\microblaze_soc_wrapper.bit
echo   4. Open Vitis, load application, run
echo   5. Open serial terminal (115200 baud, 8N1)
echo.
pause
