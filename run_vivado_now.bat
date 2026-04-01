@echo off
echo Setting up Vivado environment...
call "D:\2025.1\Vivado\settings64.bat"

echo.
echo Running Vivado synthesis and implementation...
cd /d "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\03_vivado_hardware"

echo Current directory: %CD%
echo Running: vivado -mode batch -source build.tcl

vivado -mode batch -source build.tcl -notrace

echo.
echo Vivado completed with exit code: %ERRORLEVEL%
