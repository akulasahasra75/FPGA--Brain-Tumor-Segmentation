@echo off
echo Setting up Vivado/Vitis environment...
call "D:\2025.1\Vivado\settings64.bat"

echo.
echo Running Vitis HLS synthesis...
cd /d "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\02_hls_accelerator"

echo Current directory: %CD%
echo Running: vitis-run --mode hls --tcl run_hls.tcl

REM Use vitis-run with HLS mode
vitis-run --mode hls --tcl run_hls.tcl

echo.
echo HLS synthesis completed with exit code: %ERRORLEVEL%
