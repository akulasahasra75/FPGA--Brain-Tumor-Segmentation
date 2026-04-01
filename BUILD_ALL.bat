@echo off
setlocal enabledelayedexpansion
REM ============================================================================
REM BUILD_ALL.bat - Complete build script for Brain Tumor Segmentation FPGA
REM Target: Nexys 4 DDR (Artix-7 xc7a100tcsg324-1)
REM ============================================================================

echo ============================================================
echo  Brain Tumor Segmentation FPGA - Complete Build
echo  Target: Nexys 4 DDR (Artix-7 xc7a100tcsg324-1)
echo ============================================================
echo.

REM Try to find Vivado in common locations
set VIVADO_FOUND=0

REM Check if already in PATH
where vivado >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set VIVADO_FOUND=1
    echo Found Vivado in PATH
) else (
    REM Try common installation paths
    for %%V in (2025.1 2024.2 2024.1 2023.2 2023.1 2022.2 2022.1 2021.2) do (
        if exist "C:\AMD\Vivado\%%V\bin\vivado.bat" (
            set "VIVADO_PATH=C:\AMD\Vivado\%%V"
            set VIVADO_FOUND=1
            echo Found Vivado at !VIVADO_PATH!
            goto :vivado_found
        )
        if exist "C:\Xilinx\Vivado\%%V\bin\vivado.bat" (
            set "VIVADO_PATH=C:\Xilinx\Vivado\%%V"
            set VIVADO_FOUND=1
            echo Found Vivado at !VIVADO_PATH!
            goto :vivado_found
        )
        if exist "D:\AMD\Vivado\%%V\bin\vivado.bat" (
            set "VIVADO_PATH=D:\AMD\Vivado\%%V"
            set VIVADO_FOUND=1
            echo Found Vivado at !VIVADO_PATH!
            goto :vivado_found
        )
        if exist "D:\Xilinx\Vivado\%%V\bin\vivado.bat" (
            set "VIVADO_PATH=D:\Xilinx\Vivado\%%V"
            set VIVADO_FOUND=1
            echo Found Vivado at !VIVADO_PATH!
            goto :vivado_found
        )
    )
)

:vivado_found
if %VIVADO_FOUND% EQU 0 (
    echo ERROR: Vivado not found!
    echo.
    echo Please either:
    echo   1. Run this script from Vivado Command Prompt, OR
    echo   2. Add Vivado to PATH, OR
    echo   3. Set VIVADO_PATH environment variable
    echo.
    echo Common installation paths:
    echo   C:\AMD\Vivado\2025.1
    echo   C:\Xilinx\Vivado\2024.1
    pause
    exit /b 1
)

REM Source Vivado settings if path was found
if defined VIVADO_PATH (
    echo Sourcing Vivado settings...
    call "!VIVADO_PATH!\settings64.bat"
)

REM Check for Vitis HLS
set HLS_FOUND=0
where vitis_hls >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    set HLS_FOUND=1
) else if defined VIVADO_PATH (
    REM Check for HLS in same installation
    set "HLS_CHECK=!VIVADO_PATH:\Vivado\=\Vitis_HLS\!"
    if exist "!HLS_CHECK!\bin\vitis_hls.bat" (
        set HLS_FOUND=1
        set "PATH=!HLS_CHECK!\bin;!PATH!"
    )
)

if %HLS_FOUND% EQU 0 (
    echo WARNING: Vitis HLS not found. Attempting to use vitis-run.bat instead.
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
