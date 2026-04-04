# 🎯 Complete Workflow Guide - Brain Tumor Segmentation FPGA Project

> **For Beginners**: This guide walks you through the entire project from start to finish. Think of it like building with LEGO blocks - we'll go step by step!

---

## 📖 Table of Contents

- [What This Project Does](#what-this-project-does)
- [What You'll Need](#what-youll-need)
- [The Big Picture](#the-big-picture)
- [Step-by-Step Workflow](#step-by-step-workflow)
- [How to Program the FPGA](#how-to-program-the-fpga)
- [What to Expect](#what-to-expect)
- [Troubleshooting](#troubleshooting)

---

## 🤔 What This Project Does

Imagine you're a doctor looking at brain scans (MRI images). You need to find tumors quickly to help patients. This project builds a **super-fast machine** using an FPGA chip that can:

1. **Look at brain images** (like a computer looking at a photo)
2. **Find the tumor** (the bright white spots that don't belong)
3. **Highlight it** (make it stand out so doctors can see it easily)
4. **Do it REALLY fast** - 144-229 times faster than a regular computer!

It's like having a robot assistant that can spot problems in brain scans in milliseconds! ⚡

---

## 🎒 What You'll Need

### Hardware (Physical Things)

- **Nexys A7 FPGA Board** (or Nexys 4 DDR) - This is the brain of our project
- **USB Cable** - To connect the FPGA to your computer
- **Computer** - Windows PC (the scripts are written for Windows)

### Software (Computer Programs)

1. **Python 3.8+** - For testing our idea first (free)
2. **Vivado 2023.1+** - Makes the FPGA design (from Xilinx/AMD)
3. **Vitis HLS 2025.1** - Converts C++ code to hardware (from Xilinx/AMD)
4. **Vitis 2024.1** - Builds software for the tiny processor inside the FPGA (from Xilinx/AMD)
5. **Serial Terminal** - To see the results (PuTTY, Tera Term, or Arduino Serial Monitor - free)

> **Note**: Xilinx/AMD tools are big downloads (50+ GB). Make sure you have space and a good internet connection!

---

## 🗺️ The Big Picture

Think of this project like building a car from scratch:

```
1. 🧪 DESIGN (Python)          →  Drawing blueprints on paper
2. ⚙️ BUILD ENGINE (HLS)        →  Making the engine
3. 🏗️ ASSEMBLE CAR (Vivado)    →  Putting all parts together
4. 🚗 ADD CONTROLS (Software)   →  Adding steering wheel & pedals
5. 🏁 TEST DRIVE (Program FPGA) →  Actually driving the car!
```

Each step builds on the previous one. You can't drive without building first!

---

## 📋 Step-by-Step Workflow

### Step 1: Test the Idea with Python 🐍

**What we're doing**: Making sure our brain tumor detection algorithm actually works before building hardware.

**Think of it as**: Drawing a picture before painting on canvas.

```bash
# Go to the Python folder
cd 01_python_verification

# Install the tools we need
pip install -r requirements.txt

# Run the test!
python verify_otsu.py
```

**What you'll see**:

- Processing messages in the terminal
- New images appear in `05_test_images/output/`
- The tumor areas are highlighted in white!

**Time needed**: 2-5 minutes

**What to expect**:

```
Loading image...
Computing histogram...
Otsu threshold = 127
Applying threshold...
Erosion...
Dilation...
✓ Saved: output/brain_mri_segmented.png
Processing time: 45.2ms
```

✅ **Success**: You see segmented images with tumors highlighted!
❌ **Problem**: See [Troubleshooting](#troubleshooting) section

---

### Step 2: Build the Hardware Accelerator ⚙️

**What we're doing**: Converting our C++ code into actual digital circuits that can run on the FPGA.

**Think of it as**: Turning a recipe into a cooking robot that can make food automatically.

```bash
# Go to the HLS folder
cd 02_hls_accelerator

# Run the hardware synthesis (this takes a while!)
vitis_hls -f run_hls.tcl
```

**What's happening inside**:

1. Vitis HLS reads our C++ code
2. Figures out how to build circuits to do the same thing
3. Tests it to make sure it works
4. Packages it as an "IP core" (a reusable circuit block)

**Time needed**: 10-30 minutes (depending on your computer)

**What you'll see**:

```
Opening project: otsu_hls
Running C simulation... PASS
Running synthesis...
  Analyzing code...
  Scheduling operations...
  Binding to hardware...
  Creating RTL...
Done! IP core saved to: otsu_hls/solution1/impl/ip/
```

✅ **Success**: You see "IP packaging completed successfully"
❌ **Problem**: Check that source files exist in `src/` folder

---

### Step 3: Build the Complete FPGA System 🏗️

**What we're doing**: Taking our accelerator (from Step 2) and connecting it to a tiny processor, memory, and communication ports. It's like building a complete computer!

**Think of it as**: Building a LEGO city - you already have the fire station (accelerator), now add roads (buses), houses (memory), and people (processor).

```bash
# Go to the Vivado folder
cd 03_vivado_hardware

# Build the complete FPGA design
vivado -mode batch -source build.tcl
```

**What's happening inside**:

1. Creates a "MicroBlaze" processor (a tiny CPU inside the FPGA)
2. Connects our accelerator to the processor
3. Adds UART (for talking to your PC)
4. Adds memory (for storing programs and images)
5. Converts everything to a "bitstream" (FPGA configuration file)

**Time needed**: 30-60 minutes (this is the longest step!)

**What you'll see**:

```
Creating block design...
Adding MicroBlaze processor...
Connecting IP cores...
Running synthesis...
Running implementation...
  Placement...
  Routing...
Generating bitstream...
✓ Success! Files created:
  - brain_tumor_soc.bit (FPGA configuration)
  - brain_tumor_soc.xsa (hardware description)
```

✅ **Success**: You see "Bitstream generation completed"
❌ **Problem**: Check that HLS IP exists in `ip_repo/` folder

**Important files created**:

- `vivado_project/brain_tumor_soc.runs/impl_1/microblaze_soc_wrapper.bit` - The FPGA program!
- `vivado_project/brain_tumor_soc.xsa` - Needed for next step

---

### Step 4: Write Software for the Processor 💻

**What we're doing**: Writing the control program that runs on the tiny MicroBlaze processor inside the FPGA. This tells the accelerator what to do.

**Think of it as**: Programming the brain that controls the robot.

```batch
# Go to the software folder
cd 04_vitis_software

# Build the software
build_software.bat
```

**What's happening inside**:

1. The script checks if you have the right Vitis version
2. Creates a software project
3. Compiles your C code into a program the processor understands
4. Packages it as an ".elf" file

**Time needed**: 5-10 minutes

**What you'll see with Vitis 2024.1** (Automated):

```
Checking for xsct...
✓ xsct found - using TCL-based workflow
Creating platform from XSA...
Building application...
✓ Build complete!
ELF location: vitis_workspace/brain_tumor_app/Debug/brain_tumor_app.elf
```

**What you'll see with Vitis 2025.1** (Manual):

```
Checking for xsct...
✗ xsct NOT found in Vitis 2025.1

NEXT STEPS (Manual Build Required):
  1. Install Vitis 2024.1 (Recommended) OR
  2. Use Vitis 2025.1 IDE (GUI):
     - Launch: vitis -w vitis_workspace
     - Create Platform from XSA: ../03_vivado_hardware/vivado_project/brain_tumor_soc.xsa
     - Create Application Project
     - Import sources from src/
     - Build and deploy
```

✅ **Success**: You see a `.elf` file created
❌ **Problem**: Make sure XSA file exists from Step 3

---

### Step 5: Program the FPGA! 🎉

**What we're doing**: Loading everything we built onto the actual FPGA chip. This is the moment of truth!

**Think of it as**: Installing a game on a console and pressing play!

#### Method A: Quick Programming (Just the Bitstream)

```bash
# Go to the root folder
cd ..

# Program just the hardware
vivado -mode batch -source program_fpga.tcl
```

This uploads the FPGA configuration but NOT the software yet.

#### Method B: Complete Programming (Hardware + Software)

If you used Vitis 2024.1, the software was already uploaded in Step 4!

If you're doing it manually:

1. Open Vivado Hardware Manager
2. Program the bitstream (`.bit` file)
3. Use Vitis to download the `.elf` file to the processor

**Time needed**: 1-2 minutes

**What you'll see**:

```
Connecting to FPGA via JTAG...
Programming device xc7a100t...
  [████████████████████] 100%
✓ Programming successful!
Device configured and ready.
```

**Physical signs on the FPGA board**:

- ✅ Green LED lights up (board powered)
- ✅ "DONE" LED turns on (FPGA configured)
- ✅ Some LEDs may blink (software running)

---

## 🔌 How to Program the FPGA (Detailed)

### Before You Start

1. **Connect the FPGA Board**:
   - Plug USB cable from board to computer
   - Board should power on (green LED)
   - Windows should detect it (check Device Manager → Universal Serial Bus devices)

2. **Install Drivers** (if needed):
   - Vivado installation includes FTDI drivers
   - May need to run Vivado once to install them automatically

### Programming Steps

#### Option 1: Using the TCL Script (Easiest)

```bash
# From project root
vivado -mode batch -source program_fpga.tcl
```

This automatically:

1. Finds your FPGA
2. Uploads the bitstream
3. Verifies it worked

#### Option 2: Using Vivado GUI (Step-by-Step)

1. **Open Vivado** (not in batch mode)

2. **Open Hardware Manager**:
   - Click "Flow Navigator" on left
   - Click "Open Hardware Manager"
   - Click "Open Target" → "Auto Connect"

3. **Program Device**:
   - Right-click on your FPGA (xc7a100t)
   - Select "Program Device"
   - Browse to bitstream: `03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/microblaze_soc_wrapper.bit`
   - Click "Program"

4. **Wait for "Program succeeded"**

#### Option 3: Using Vitis (Hardware + Software)

If you used Vitis to build software, you can program both together:

1. **Open Vitis**:

   ```batch
   vitis -w 04_vitis_software/vitis_workspace
   ```

2. **In Vitis**:
   - Right-click `brain_tumor_app`
   - Select "Run As" → "Launch Hardware"
   - Vitis will:
     - Program the bitstream
     - Download the ELF
     - Start the processor

---

## 🎬 What to Expect (Running the System)

### Connecting to See Results

1. **Find the COM Port**:
   - Open Device Manager (Windows)
   - Expand "Ports (COM & LPT)"
   - Look for "USB Serial Port (COM#)" - remember the number!

2. **Open Serial Terminal**:
   - **PuTTY**:
     - Connection Type: Serial
     - Serial Line: COM# (your port number)
     - Speed: 115200
     - Click "Open"
   - **Tera Term**:
     - Setup → Serial Port
     - Port: COM#
     - Baud rate: 115200
     - Click "OK"
   - **Arduino IDE**:
     - Tools → Serial Monitor
     - Select your COM port
     - Set to 115200 baud

3. **You Should See**:

```
=====================================
Brain Tumor Segmentation FPGA
Nexys A7 - MicroBlaze System
=====================================

Initializing hardware accelerator...
✓ Otsu IP found at address 0x44A00000

Loading test image (512x512 grayscale)...
✓ Image loaded

Starting segmentation...
  Computing histogram...
  Otsu threshold: 134
  Applying binary threshold...
  Morphological operations...
✓ Segmentation complete!

Results:
--------
Processing time: 2.8ms
Tumor pixels: 15,234
Background pixels: 246,862
Threshold used: 134

Press any key to process next image...
```

### LEDs on the Board

- **LED 0**: System running (blinks)
- **LED 1**: Processing active (on during segmentation)
- **LED 2**: Accelerator ready
- **LED 3-4**: Status indicators

### Expected Performance

| Metric              | Value            |
| ------------------- | ---------------- |
| Processing Time     | 2-3 milliseconds |
| Images per Second   | 300-350          |
| Speedup vs Software | 144-229× faster  |

---

## 🐛 Troubleshooting

### Problem: "FPGA not detected"

**Symptoms**: Vivado says "No hardware targets found"

**Solutions**:

1. Check USB cable is connected
2. Board power switch is ON
3. Check Device Manager - should see USB device
4. Reinstall drivers: Run Vivado once, it auto-installs
5. Try different USB port (use USB 2.0, not 3.0 if possible)

---

### Problem: "xsct is not recognized"

**Symptoms**: Software build fails with error about xsct

**Cause**: You have Vitis 2025.1, which removed the xsct tool

**Solutions**:

- **Option 1** (Recommended): Download and install Vitis 2024.1
- **Option 2**: Use Vitis 2025.1 IDE (GUI mode) - see `04_vitis_software/README.md`

---

### Problem: "XSA file not found"

**Symptoms**: Software build says it can't find `brain_tumor_soc.xsa`

**Cause**: You skipped Step 3 (Vivado build)

**Solution**:

1. Go back to Step 3
2. Run `vivado -mode batch -source build.tcl`
3. Wait for it to complete (creates the XSA file)
4. Then try Step 4 again

---

### Problem: "No output on serial terminal"

**Symptoms**: Terminal is blank, no text appears

**Solutions**:

1. **Check COM port**: Make sure you're connected to the right port
2. **Check baud rate**: Must be 115200
3. **Check software**: Make sure Step 4 completed successfully
4. **Reset board**: Press the reset button (often labeled "CPU_RESET")
5. **Reprogram**: Try programming the FPGA again

---

### Problem: "Build takes forever"

**Symptoms**: Vivado stuck at synthesis or implementation

**Solutions**:

1. This is normal! Vivado can take 30-60 minutes
2. Check task manager - Vivado should be using CPU
3. Make sure you have enough RAM (8GB minimum, 16GB recommended)
4. Close other programs to free up resources
5. Be patient - grab a coffee! ☕

---

### Problem: "Python script crashes"

**Symptoms**: `verify_otsu.py` gives errors

**Solutions**:

1. Make sure Python packages are installed:
   ```bash
   pip install -r requirements.txt
   ```
2. Check that test images exist in `05_test_images/input/`
3. Make sure output folder exists: `05_test_images/output/`
4. Try running with Python 3.8 or newer

---

## 🎓 Understanding the Files

### Important Files You Created

1. **`microblaze_soc_wrapper.bit`** (in `03_vivado_hardware/.../impl_1/`)
   - This is the FPGA configuration
   - Like a blueprint that tells every transistor what to do
   - Size: ~400KB
   - This goes INTO the FPGA chip

2. **`brain_tumor_app.elf`** (in `04_vitis_software/vitis_workspace/.../Debug/`)
   - This is the software program
   - Runs on the MicroBlaze processor
   - Size: ~100KB
   - This goes INTO the processor's memory

3. **`brain_tumor_soc.xsa`** (in `03_vivado_hardware/vivado_project/`)
   - Hardware specification file
   - Tells Vitis what hardware exists in the FPGA
   - Like a map of the city for the software developer

---

## 🏆 Success Checklist

- [ ] Python verification works (saw segmented images)
- [ ] HLS synthesis completed (IP core created)
- [ ] Vivado build completed (bitstream created)
- [ ] Software compiled (ELF file created)
- [ ] FPGA programmed (DONE LED lit)
- [ ] Serial terminal shows output
- [ ] Processing times are ~2-3ms
- [ ] Can see tumor segmentation working!

---

## 🎯 Quick Reference Card

```
╔═══════════════════════════════════════════════════════════╗
║           QUICK START GUIDE                               ║
╠═══════════════════════════════════════════════════════════╣
║ 1. cd 01_python_verification && python verify_otsu.py     ║
║ 2. cd 02_hls_accelerator && vitis_hls -f run_hls.tcl      ║
║ 3. cd 03_vivado_hardware && vivado -mode batch -source    ║
║    build.tcl                                              ║
║ 4. cd 04_vitis_software && build_software.bat             ║
║ 5. vivado -mode batch -source program_fpga.tcl            ║
║ 6. Open serial terminal (115200 baud)                     ║
║ 7. See results! 🎉                                        ║
╚═══════════════════════════════════════════════════════════╝
```

---

## 📞 Need More Help?

- **Check folder READMEs**: Each folder (`01_python_verification/`, etc.) has its own README with specific details
- **Check main README**: The root `README.md` has architecture diagrams and performance details
- **Check PRD**: `docs/prd.md` has product requirements and specifications
- **Check Nexys docs**: `docs/nexys.md` has board-specific information

---

## 🎉 Congratulations!

If you made it through all the steps, you've just:

- ✅ Designed a hardware accelerator from scratch
- ✅ Built a complete system-on-chip (SoC)
- ✅ Programmed an FPGA
- ✅ Created a real medical imaging tool that's 200× faster than software!

That's seriously impressive! You're now an FPGA developer! 🚀

---

**Last Updated**: April 2026
**Maintained By**: Project Team
**Questions?**: Open an issue on GitHub
