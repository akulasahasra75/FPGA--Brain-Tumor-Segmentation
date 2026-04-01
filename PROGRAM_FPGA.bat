@echo off
REM ============================================================================
REM PROGRAM_FPGA.bat - Program Nexys 4 DDR with Brain Tumor Segmentation
REM ============================================================================
REM
REM This script programs the FPGA bitstream using Vivado Hardware Manager.
REM Run from Vivado Command Prompt or ensure Vivado is in PATH.
REM
REM Prerequisites:
REM   - Nexys 4 DDR connected via USB
REM   - Vivado 2025.1 (or compatible version)
REM ============================================================================

echo.
echo ============================================================
echo  FPGA PROGRAMMING - Brain Tumor Segmentation
echo  Target: Nexys 4 DDR (xc7a100t-csg324)
echo ============================================================
echo.

set SCRIPT_DIR=%~dp0
set BIT_FILE=%SCRIPT_DIR%06_documentation\hardware_output\brain_tumor_soc.bit

REM Check if bitstream exists
if not exist "%BIT_FILE%" (
    echo ERROR: Bitstream not found at:
    echo        %BIT_FILE%
    echo.
    echo Please ensure the hardware build completed successfully.
    pause
    exit /b 1
)

echo Bitstream: %BIT_FILE%
echo.

REM Check for Vivado
where vivado >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Vivado not found in PATH
    echo Please run from Vivado Command Prompt or add Vivado to PATH
    echo.
    echo Manual programming steps:
    echo   1. Open Vivado
    echo   2. Open Hardware Manager
    echo   3. Open Target ^> Auto Connect
    echo   4. Program Device
    echo   5. Select: %BIT_FILE%
    echo.
    pause
    exit /b 1
)

echo Programming FPGA...
echo.

REM Create TCL script for programming
set TCL_SCRIPT=%TEMP%\program_fpga.tcl
echo # Auto-generated FPGA programming script > "%TCL_SCRIPT%"
echo open_hw_manager >> "%TCL_SCRIPT%"
echo connect_hw_server >> "%TCL_SCRIPT%"
echo open_hw_target >> "%TCL_SCRIPT%"
echo set_property PROGRAM.FILE {%BIT_FILE%} [get_hw_devices xc7a100t_0] >> "%TCL_SCRIPT%"
echo current_hw_device [get_hw_devices xc7a100t_0] >> "%TCL_SCRIPT%"
echo program_hw_devices [get_hw_devices xc7a100t_0] >> "%TCL_SCRIPT%"
echo puts "Programming complete!" >> "%TCL_SCRIPT%"
echo close_hw_manager >> "%TCL_SCRIPT%"
echo exit >> "%TCL_SCRIPT%"

REM Run Vivado in batch mode
vivado -mode batch -source "%TCL_SCRIPT%" -notrace

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================
    echo  PROGRAMMING SUCCESSFUL!
    echo ============================================================
    echo.
    echo Next steps:
    echo   1. Open a serial terminal (PuTTY, TeraTerm, etc.)
    echo   2. Connect to the COM port for Nexys 4 DDR
    echo   3. Settings: 115200 baud, 8N1, no flow control
    echo   4. You should see the application banner
    echo.
) else (
    echo.
    echo ============================================================
    echo  PROGRAMMING FAILED
    echo ============================================================
    echo.
    echo Troubleshooting:
    echo   - Ensure Nexys 4 DDR is connected via USB
    echo   - Check that the board power is ON
    echo   - Try unplugging and reconnecting the USB cable
    echo   - Check Device Manager for the FPGA device
    echo.
)

pause
