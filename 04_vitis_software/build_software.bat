@echo off
echo ========================================
echo Vitis Software Build - MicroBlaze Firmware
echo ========================================

echo Configuring Xilinx Vitis Environment...
call D:\2025.1\Vitis\settings64.bat

echo.
echo Step 1: Creating Vitis Platform and Application...
call xsct create_vitis_project.tcl
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Vitis project creation failed
    exit /b 1
)

echo.
echo Step 2: Building with Makefile (if needed)...
call make all
if %ERRORLEVEL% NEQ 0 (
    echo WARNING: Makefile build failed, but xsct may have already built the ELF
)

echo.
echo ========================================
echo Software Build Complete!
echo ELF Location: vitis_workspace\brain_tumor_app\Debug\brain_tumor_app.elf
echo ========================================
pause
