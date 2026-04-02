@echo off
REM Quick cleanup and start build script

REM Get vivado PIDs and kill them
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq vivado.exe" /fo csv ^| find "vivado"') do (
    taskkill /f /pid %%~i 2>nul
)

timeout /t 3 /nobreak >nul

REM Remove old project
cd /d "c:\Users\anees\Documents\Projects\FPGA--Brain-Tumor-Segmentation"
if exist "03_vivado_hardware\vivado_project" rmdir /s /q "03_vivado_hardware\vivado_project"
if exist "03_vivado_hardware\.Xil" rmdir /s /q "03_vivado_hardware\.Xil"

echo Cleanup complete. Starting build...

REM Start the build in a new window
start "Vivado Build" cmd /c "BUILD_NOW.bat"
