@echo off
echo ============================================================ >> "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\logs\vivado_build_20260401_163500.log"
echo   VIVADO BUILD - Brain Tumor Segmentation SoC >> "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\logs\vivado_build_20260401_163500.log"
echo   Started: %date% %time% >> "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\logs\vivado_build_20260401_163500.log"
echo ============================================================ >> "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\logs\vivado_build_20260401_163500.log"

call "D:\2025.1\Vivado\settings64.bat"

cd /d "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\03_vivado_hardware"
echo Working directory: %CD% >> "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\logs\vivado_build_20260401_163500.log"

echo Starting Vivado build... >> "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\logs\vivado_build_20260401_163500.log"
vivado -mode batch -source build.tcl -notrace >> "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\logs\vivado_build_20260401_163500.log" 2>&1

echo. >> "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\logs\vivado_build_20260401_163500.log"
echo Build completed with exit code: %ERRORLEVEL% >> "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\logs\vivado_build_20260401_163500.log"
echo Finished: %date% %time% >> "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation\logs\vivado_build_20260401_163500.log"
