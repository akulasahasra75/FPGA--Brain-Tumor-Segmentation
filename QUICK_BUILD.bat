@echo off
REM ============================================================================
REM QUICK_BUILD.bat - Simplified build script for Nexys 4 DDR
REM Run from Vivado Command Prompt or after sourcing settings64.bat
REM ============================================================================

echo.
echo ============================================================
echo  QUICK BUILD - Nexys 4 DDR Brain Tumor Segmentation
echo ============================================================
echo.
echo This script assumes Vivado/Vitis HLS are in your PATH.
echo If not, run from Vivado Command Prompt.
echo.
echo Press Ctrl+C to cancel or
pause

set PROJECT_ROOT=%~dp0

REM ============================================================
REM STEP 1: HLS Synthesis (Otsu IP Core)
REM ============================================================
echo.
echo [1/3] HLS SYNTHESIS - Creating Otsu accelerator IP...
cd /d "%PROJECT_ROOT%02_hls_accelerator"

vitis_hls -f run_hls.tcl
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: HLS synthesis failed!
    goto :error
)

echo HLS synthesis successful!

REM Copy IP to Vivado repo
echo Copying IP core to Vivado repository...
if not exist "..\03_vivado_hardware\ip_repo" mkdir "..\03_vivado_hardware\ip_repo"
xcopy /E /Y /Q "otsu_hls\solution1\impl\ip" "..\03_vivado_hardware\ip_repo\" >nul 2>&1

REM ============================================================
REM STEP 2: Vivado Hardware Build
REM ============================================================
echo.
echo [2/3] VIVADO BUILD - Creating bitstream...
cd /d "%PROJECT_ROOT%03_vivado_hardware"

vivado -mode batch -source build.tcl -notrace
if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: Vivado build failed! Check vivado.log
    goto :error
)

echo Vivado build successful!

REM ============================================================
REM STEP 3: Verify Outputs
REM ============================================================
echo.
echo [3/3] VERIFYING OUTPUTS...

set BIT_FILE=vivado_project\brain_tumor_soc.runs\impl_1\microblaze_soc_wrapper.bit
set XSA_FILE=vivado_project\brain_tumor_soc.xsa

if exist "%BIT_FILE%" (
    echo [OK] Bitstream found: %BIT_FILE%
) else (
    echo [WARNING] Bitstream not found at expected location
    echo Looking for .bit files...
    dir /s /b *.bit 2>nul
)

if exist "%XSA_FILE%" (
    echo [OK] Hardware export found: %XSA_FILE%
) else (
    echo [WARNING] XSA not found at expected location
)

echo.
echo ============================================================
echo  BUILD COMPLETE!
echo ============================================================
echo.
echo Next steps:
echo   1. Connect Nexys 4 DDR via USB
echo   2. Open Vivado Hardware Manager
echo   3. Auto-connect to board
echo   4. Program device with bitstream
echo   5. Open terminal at 115200 baud
echo.
echo Bitstream location:
echo   %PROJECT_ROOT%03_vivado_hardware\%BIT_FILE%
echo.
goto :end

:error
echo.
echo ============================================================
echo  BUILD FAILED - Check logs above
echo ============================================================
echo.
pause
exit /b 1

:end
pause
exit /b 0
