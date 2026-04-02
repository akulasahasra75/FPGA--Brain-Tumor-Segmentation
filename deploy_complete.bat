@echo off
REM ============================================================================
REM COMPLETE FPGA DEPLOYMENT SCRIPT
REM Runs all deployment steps automatically when FPGA is connected
REM ============================================================================

echo ========================================
echo FPGA Brain Tumor Segmentation
echo Complete Deployment Script
echo ========================================
echo.

REM Check if we're in the right directory
if not exist "04_vitis_software" (
    echo ERROR: Please run this script from the project root directory
    echo Expected: FPGA--Brain-Tumor-Segmentation\
    pause
    exit /b 1
)

echo [1/4] Setting up Xilinx environment...
call D:\2025.1\Vitis\settings64.bat
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to source Vitis environment
    echo Check that Vitis is installed at D:\2025.1\Vitis\
    pause
    exit /b 1
)

echo.
echo [2/4] Building MicroBlaze software...
cd 04_vitis_software
call xsct create_vitis_project.tcl
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Software build had issues
    echo This may be OK if ELF already exists
    echo Continuing anyway...
)
cd ..

echo.
echo [3/4] Verifying build outputs...
if exist "04_vitis_software\vitis_workspace\brain_tumor_app\Debug\brain_tumor_app.elf" (
    echo   OK: ELF file found
) else (
    echo   WARNING: ELF file not found
    echo   You may need to build manually
)

if exist "03_vivado_hardware\vivado_project\brain_tumor_soc.runs\impl_1\top_module.bit" (
    echo   OK: Bitstream found
) else (
    echo   ERROR: Bitstream not found
    echo   Run Vivado build first: cd 03_vivado_hardware ^&^& vivado -mode batch -source build.tcl
    pause
    exit /b 1
)

echo.
echo [4/4] Ready for hardware programming!
echo.
echo ========================================
echo NEXT STEPS:
echo ========================================
echo.
echo 1. Connect Nexys 4 DDR board via USB
echo 2. Power on the board
echo 3. Run these XSCT commands:
echo.
echo    xsct
echo    connect
echo    targets -set -filter {name =~^ "xc7a*"}
echo    fpga 03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/top_module.bit
echo    after 2000
echo    targets -set -filter {name =~^ "*MicroBlaze*"}
echo    rst -processor
echo    dow 04_vitis_software/vitis_workspace/brain_tumor_app/Debug/brain_tumor_app.elf
echo    con
echo    disconnect
echo    exit
echo.
echo 4. Open serial terminal (PuTTY/TeraTerm) at 115200 baud
echo 5. Observe LED0 blinking and serial output
echo.
echo ========================================
echo For detailed instructions, see:
echo   DEPLOY_ON_HARDWARE.md
echo ========================================
echo.

pause
