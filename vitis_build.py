################################################################################
# vitis_build.py
# ---------------
# Vitis 2025.1 Python script to create platform + application and build.
#
# Usage:
#   D:\2025.1\Vitis\bin\vitis -s vitis_build.py
#
# This replaces the old xsct TCL flow.
################################################################################

import vitis
import os
import shutil
import glob

# Paths — use C:\bts to keep paths short (Windows 260 char limit)
script_dir = "C:/bts"
xsa_file   = os.path.join(script_dir, "brain_tumor_soc.xsa")
src_dir    = os.path.join(os.path.dirname(os.path.abspath(__file__)), "04_vitis_software", "src")
ws_dir     = os.path.join(script_dir, "ws")

print("=" * 60)
print("  Brain Tumor Segmentation — Vitis 2025.1 Build")
print("=" * 60)

# Verify XSA
if not os.path.exists(xsa_file):
    # Try the Z: drive mapped path
    xsa_file = "Z:/03_vivado_hardware/vivado_project/brain_tumor_soc.xsa"
    if not os.path.exists(xsa_file):
        print(f"ERROR: XSA not found. Run Vivado build first.")
        exit(1)

print(f"  XSA: {xsa_file}")
print(f"  Sources: {src_dir}")
print(f"  Workspace: {ws_dir}")

# Clean previous workspace
if os.path.exists(ws_dir):
    print("  Removing previous workspace...")
    shutil.rmtree(ws_dir, ignore_errors=True)

# Create workspace
client = vitis.create_client()
client.set_workspace(ws_dir)

# Create platform
print("\n>>> Creating platform from XSA ...")
platform = client.create_platform_component(
    name="brain_tumor_platform",
    hw_design=xsa_file,
    os="standalone",
    cpu="microblaze_0"
)

print(">>> Building platform ...")
platform = client.get_component("brain_tumor_platform")
platform.build()

# Create application
print("\n>>> Creating application ...")
app = client.create_app_component(
    name="brain_tumor_app",
    platform="brain_tumor_platform",
    template="empty"
)

# Copy source files to the app source directory
print(">>> Importing source files ...")
app_src = os.path.join(ws_dir, "brain_tumor_app", "src")
os.makedirs(app_src, exist_ok=True)

for f in glob.glob(os.path.join(src_dir, "*.c")) + glob.glob(os.path.join(src_dir, "*.h")):
    dest = os.path.join(app_src, os.path.basename(f))
    shutil.copy2(f, dest)
    print(f"  Copied: {os.path.basename(f)}")

# Build application
print("\n>>> Building application ...")
app = client.get_component("brain_tumor_app")
app.build()

print("\n" + "=" * 60)
print("  BUILD COMPLETE")
print("=" * 60)

# Find ELF
for root, dirs, files in os.walk(ws_dir):
    for f in files:
        if f.endswith(".elf"):
            elf_path = os.path.join(root, f)
            print(f"  ELF: {elf_path}")

print("\n  Next: Program the FPGA with Vivado Hardware Manager")
print("  Bitstream: Z:/03_vivado_hardware/vivado_project/brain_tumor_soc.runs/impl_1/microblaze_soc_wrapper.bit")
print("=" * 60)
