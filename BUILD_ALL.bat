@echo off
echo ========================================
echo FPGA Brain Tumor Segmentation Build
echo ========================================

echo Configuring Xilinx Toolchain Environment...
call D:\2025.1\Vivado\settings64.bat
call D:\2025.1\Vitis\settings64.bat

echo Phase 1: Validating Images...
cd 01_python_verification || exit /b 1
python run_all_tests.py || exit /b 1
python ../05_test_images/convert_to_bin.py --from-phase1 || exit /b 1
cd ..

echo.
echo Phase 2: Compiling HLS using Vitis Unified IDE...
cd 02_hls_accelerator || exit /b 1
call vitis-run --tcl --input_file run_hls.tcl || exit /b 1
cd ..

echo.
echo Phase 3: Running Vivado Build...
cd 03_vivado_hardware || exit /b 1
call vivado -mode batch -source build.tcl || exit /b 1
cd ..

echo.
echo Phase 4: Vitis Make
cd 04_vitis_software || exit /b 1
call xsct create_vitis_project.tcl || exit /b 1
call make all || exit /b 1
cd ..

echo.
echo ========================================
echo Build Complete Successfully!
pause
