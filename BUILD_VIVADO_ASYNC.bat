@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo   VIVADO BUILD - Brain Tumor Segmentation SoC
echo   Started: %date% %time%
echo ============================================================
echo.

call "D:\2025.1\Vivado\settings64.bat"

cd /d "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\03_vivado_hardware"
echo Working directory: %CD%
echo.

echo Starting Vivado synthesis and implementation...
echo This will take approximately 20-40 minutes.
echo.

vivado -mode batch -source build.tcl -notrace

echo.
echo ============================================================
echo   VIVADO BUILD COMPLETED
echo   Exit code: %ERRORLEVEL%
echo   Finished: %date% %time%
echo ============================================================

if exist vivado_project\brain_tumor_soc.runs\impl_1\*.bit (
    echo [SUCCESS] Bitstream generated!
    copy /Y vivado_project\brain_tumor_soc.runs\impl_1\*.bit ..\06_documentation\hardware_output\
    echo Bitstream copied to 06_documentation\hardware_output\
) else (
    echo [WARNING] Bitstream not found - check logs for errors
)

echo Done.
