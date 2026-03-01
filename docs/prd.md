📁 PROJECT DIRECTORY & FLOW - Complete Guide
text
BRAIN TUMOR SEGMENTATION FPGA PROJECT
=======================================
📂 COMPLETE DIRECTORY STRUCTURE
text
FPGA--Brain-Tumor-Segmentation/
│
├── 📁 01_python_verification/ ← PHASE 1 (YOU ARE HERE)
│ ├── generate_test_images.py # Creates test MRI images
│ ├── otsu_watershed.py # Main algorithm (Otsu + Watershed)
│ ├── verify_results.py # Compares with expected
│ ├── run_all_tests.py # Runs everything
│ ├── requirements.txt # Python dependencies
│ └── 📁 test_images/ # Generated images
│ ├── brain_01.png
│ ├── brain_02.png
│ ├── brain_03.png
│ └── 📁 expected_results/
│
├── 📁 02_hls_accelerator/ ← PHASE 2 (NEXT)
│ ├── otsu_threshold.cpp # HLS Otsu implementation
│ ├── otsu_threshold.h  
│ ├── image_stats.cpp # NOVELTY: Adaptive logic
│ ├── image_stats.h
│ ├── test_otsu.cpp # C++ testbench
│ └── run_hls.tcl # HLS synthesis script
│
├── 📁 03_vivado_hardware/ ← PHASE 3
│ ├── 📁 srcs/
│ │ └── 📁 verilog/
│ │ ├── top_module.v # Main FPGA wrapper
│ │ ├── axi_interface.v # AXI bus communication
│ │ └── bram_controller.v # Memory controller
│ ├── 📁 constraints/
│ │ └── artix7.xdc # Pin assignments
│ ├── 📁 ip_repo/ # HLS IP cores
│ │ └── (otsu_ip.zip will go here)
│ └── build.tcl # Vivado build script
│
├── 📁 04_vitis_software/ ← PHASE 4
│ ├── 📁 src/
│ │ ├── main.c # Main program
│ │ ├── watershed.c # Watershed algorithm
│ │ ├── watershed.h
│ │ ├── adaptive_controller.c # NOVELTY: Mode selection
│ │ ├── adaptive_controller.h
│ │ ├── energy_analyzer.c # NOVELTY: Power calc
│ │ ├── energy_analyzer.h
│ │ ├── image_loader.c # Load images to FPGA
│ │ ├── image_loader.h
│ │ ├── uart_debug.c # Serial output
│ │ ├── platform_config.h # Hardware addresses
│ │ └── test_images.h # Images as C arrays
│ └── Makefile
│
├── 📁 05_test_images/ ← PHASE 5
│ ├── convert_to_bin.py # PNG → Binary converter
│ ├── brain_01.bin
│ ├── brain_02.bin
│ ├── brain_03.bin
│ └── 📁 c_headers/
│ ├── brain_01.h
│ ├── brain_02.h
│ └── brain_03.h
│
├── 📁 06_documentation/ ← PHASE 6
│ ├── project_report.md
│ ├── presentation.pptx
│ ├── user_manual.md
│ └── results.txt
│
├── .gitignore
├── LICENSE
└── README.md

🔄 PROJECT FLOW (How to Code)
PHASE 1: PYTHON VERIFICATION ← YOU ARE HERE
text
START → [Python] Verify algorithms work
↓
Write generate_test_images.py
↓
Write otsu_watershed.py  
 ↓
Write verify_results.py
↓
RUN: python run_all_tests.py
↓
✅ Verify output matches expected
↓
PHASE 2: HLS C++ ← NEXT
text
↓
[HLS C++] Convert Otsu to hardware
↓
Write otsu_threshold.h (function prototypes)
↓
Write otsu_threshold.cpp (main algorithm)
↓
Add #pragma HLS for parallelism
↓
Write image_stats.cpp (novelty)
↓
Write test_otsu.cpp (testbench)
↓
Write run_hls.tcl (synthesis script)
↓
RUN: vitis_hls -f run_hls.tcl
↓
✅ Get IP core (otsu_threshold.zip)
↓
PHASE 3: VIVADO HARDWARE
text
↓
[Vivado] Build FPGA hardware
↓
Create new project (Artix-7)
↓
Add MicroBlaze processor
↓
Import HLS IP core
↓
Add BRAM controller
↓
Connect AXI bus
↓
Write top_module.v (Verilog wrapper)
↓
Add artix7.xdc constraints
↓
RUN: source build.tcl
↓
✅ Get bitstream (.bit) and hardware (.xsa)
↓
PHASE 4: VITIS SOFTWARE
text
↓
[Vitis] Write C code for MicroBlaze
↓
Import hardware platform (.xsa)
↓
Write watershed.c (main algorithm)
↓
Write adaptive_controller.c (novelty)
↓
Write energy_analyzer.c (novelty)
↓
Write main.c (control logic)
↓
Write image_loader.c
↓
Write uart_debug.c
↓
Create test_images.h (from Python)
↓
RUN: make
↓
✅ Get executable (.elf)
↓
PHASE 5: INTEGRATION
text
↓
[Integration] Combine everything
↓
Load bitstream to FPGA
↓
Load software to MicroBlaze
↓
Connect serial monitor (115200 baud)
↓
RUN: System executes
↓
✅ See results on serial terminal
↓
PHASE 6: DOCUMENTATION
text
↓
[Document] Write final report
↓
Capture screenshots of each phase
↓
Record demo video
↓
Write project_report.md
↓
Create presentation.pptx
↓
✅ Submit!

📊 WHAT TO CODE IN EACH FILE
PHASE 1: Python Files
File
What to Code
generate_test_images.py
Create 3 MRI-like images with/without tumors
otsu_watershed.py
Implement Otsu threshold, Watershed, adaptive logic, energy calc
verify_results.py
Compare output with expected, calculate accuracy
run_all_tests.py
Run all Python files in sequence

PHASE 2: HLS C++ Files
File
What to Code
otsu_threshold.h
Function prototypes, constants
otsu_threshold.cpp
3 versions of Otsu (FAST/NORMAL/CAREFUL) with pragmas
image_stats.cpp
Calculate contrast, mean, std dev from image
test_otsu.cpp
Test all 3 modes with different images
run_hls.tcl
TCL commands to synthesize and export IP

PHASE 3: Verilog Files
File
What to Code
top_module.v
Connect MicroBlaze, BRAM, Otsu IP, UART
axi_interface.v
Handle AXI reads/writes
bram_controller.v
Memory read/write logic
artix7.xdc
Pin assignments for clock, LEDs, UART
build.tcl
TCL to create project and generate bitstream

PHASE 4: C Files
File
What to Code
watershed.c
Connected components, tumor labeling
adaptive_controller.c
Select mode based on contrast
energy_analyzer.c
Calculate power and energy
main.c
Main loop: load image → call Otsu → watershed → print results
image_loader.c
Copy image from memory to Otsu
uart_debug.c
Print to serial terminal
test_images.h
C arrays of test images (auto-generated)

✅ COMPLETION CHECKLIST
PHASE 1: Python (Current)
text
[ ] generate_test_images.py working
[ ] otsu_watershed.py working  
[ ] verify_results.py working
[ ] All 3 images processed
[ ] Speedup >1.9x shown
[ ] Energy savings >99% shown
PHASE 2: HLS C++ (Next)
text
[ ] otsu_threshold.cpp compiles
[ ] test_otsu.cpp runs without errors
[ ] All 3 modes work
[ ] HLS synthesis completes
[ ] IP core generated
PHASE 3: Vivado
text
[ ] Block design created
[ ] All components connected
[ ] Bitstream generated
[ ] Hardware exported (.xsa)
PHASE 4: Vitis
text
[ ] watershed.c compiles
[ ] adaptive_controller.c works
[ ] energy_analyzer.c works
[ ] main.c runs
[ ] .elf generated
PHASE 5: Integration
text
[ ] FPGA programmed
[ ] Serial output shows results
[ ] All 3 images tested
[ ] Performance matches Python estimates

🚀 QUICK START (What to Do Now)
bash

# 1. Complete Python phase

cd 01_python_verification
python generate_test_images.py
python otsu_watershed.py
python verify_results.py

# 2. Once Python works → Move to HLS

cd ../02_hls_accelerator

# Create all files listed above

# Test with: g++ -o test test_otsu.cpp && ./test

# Synthesize: vitis_hls -f run_hls.tcl

📝 NOTES FOR CODING
Python first - Make sure algorithms work before hardware
HLS pragmas - Add them gradually, test after each
Verilog templates - Use provided code, just modify
C code - Test on PC first with gcc, then on MicroBlaze
Git commit after each working file
