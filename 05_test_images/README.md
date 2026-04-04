# 05_test_images

## Purpose

Test images for algorithm verification and hardware validation.

## Directory Structure

- **`input/`** - Original grayscale brain MRI images (512x512 PNG)
- **`c_headers/`** - C header files with embedded image data for firmware
- **`convert_to_bin.py`** - Python script to convert images to binary format

## Image Format

- **Size**: 512x512 pixels
- **Type**: Grayscale (8-bit, 0-255)
- **Format**: PNG for viewing, binary/header for hardware

## Usage

- Python script reads from `input/`
- Hardware firmware uses headers from `c_headers/`
- Use `convert_to_bin.py` to generate binary files for HLS testbench
