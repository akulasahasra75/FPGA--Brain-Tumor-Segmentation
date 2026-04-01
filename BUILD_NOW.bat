@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo   VIVADO BUILD - Brain Tumor Segmentation SoC
echo   Memory-Optimized Configuration (single-threaded)
echo   Started: %date% %time%
echo ============================================================
echo.
echo NOTE: This system has 8GB RAM. Build uses single-threaded
echo       synthesis to avoid out-of-memory errors.
echo.
echo IMPORTANT: Close all other applications to free memory!
echo.

REM Kill any existing Vivado processes
echo Stopping any running Vivado processes...
taskkill /F /IM vivado.exe 2>nul
timeout /t 3 /nobreak >nul

REM Clean up old project if it exists
cd /d "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation"
if exist "03_vivado_hardware\vivado_project" (
    echo Removing old project directory...
    rmdir /s /q "03_vivado_hardware\vivado_project" 2>nul
)
if exist "03_vivado_hardware\.Xil" rmdir /s /q "03_vivado_hardware\.Xil" 2>nul

REM Setup Vivado environment
echo.
echo Setting up Vivado 2025.1 environment...
call "D:\2025.1\Vivado\settings64.bat"
if errorlevel 1 (
    echo ERROR: Could not setup Vivado environment
    pause
    exit /b 1
)

REM Change to hardware directory
cd /d "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\03_vivado_hardware"

echo.
echo Working directory: %CD%
echo.
echo ============================================================
echo   Starting Vivado synthesis and implementation
echo   Estimated time: 45-90 minutes (single-threaded)
echo ============================================================
echo.

REM Run Vivado with increased memory settings
set JAVA_TOOL_OPTIONS=-Xmx2g
vivado -mode batch -source build.tcl -notrace

echo.
echo ============================================================
echo   BUILD COMPLETED
echo   Exit code: %ERRORLEVEL%
echo   Finished: %date% %time%
echo ============================================================

REM Check for bitstream
if exist "vivado_project\brain_tumor_soc.runs\impl_1\microblaze_soc_wrapper.bit" (
    echo.
    echo [SUCCESS] Bitstream generated!
    echo Copying to output directory...
    copy /Y "vivado_project\brain_tumor_soc.runs\impl_1\microblaze_soc_wrapper.bit" "..\06_documentation\hardware_output\brain_tumor_soc.bit"
    copy /Y "vivado_project\brain_tumor_soc.xsa" "..\06_documentation\hardware_output\brain_tumor_soc.xsa"
    echo.
    echo Output files:
    echo   - 06_documentation\hardware_output\brain_tumor_soc.bit
    echo   - 06_documentation\hardware_output\brain_tumor_soc.xsa
) else (
    echo.
    echo [ERROR] Bitstream not found - check logs for errors
)

echo.
pause
