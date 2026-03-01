#!/usr/bin/env python3
"""
convert_to_bin.py
------------------
Convert PNG/JPEG grayscale images to raw binary (.bin) files and C header
arrays for embedding in the MicroBlaze firmware.

Usage:
    python convert_to_bin.py                      # convert all in input/
    python convert_to_bin.py --input image.png    # convert one file
    python convert_to_bin.py --from-phase1        # use Phase 1 test images

Output:
    bin/          – raw 256×256 uint8 binary files
    c_headers/    – C header files with uint8_t arrays
"""

import argparse
import os
import sys
from pathlib import Path

import cv2
import numpy as np


# ---- Constants ----
IMG_WIDTH = 256
IMG_HEIGHT = 256
IMG_SIZE = IMG_WIDTH * IMG_HEIGHT


def convert_image(input_path: str, bin_dir: str, header_dir: str) -> bool:
    """Convert a single image to .bin and .h files."""
    img = cv2.imread(input_path, cv2.IMREAD_GRAYSCALE)
    if img is None:
        print(f"  ERROR: Cannot read {input_path}")
        return False

    # Resize to 256×256
    if img.shape != (IMG_HEIGHT, IMG_WIDTH):
        img = cv2.resize(img, (IMG_WIDTH, IMG_HEIGHT),
                         interpolation=cv2.INTER_AREA)

    # Flatten to row-major
    flat = img.flatten().astype(np.uint8)
    assert flat.shape[0] == IMG_SIZE, f"Unexpected size: {flat.shape[0]}"

    stem = Path(input_path).stem
    # Sanitise for C identifier
    c_name = stem.replace("-", "_").replace(" ", "_").lower()

    # ---- Write .bin ----
    bin_path = os.path.join(bin_dir, f"{stem}.bin")
    flat.tofile(bin_path)
    print(f"  BIN: {bin_path} ({os.path.getsize(bin_path)} bytes)")

    # ---- Write .h ----
    header_path = os.path.join(header_dir, f"{c_name}.h")
    guard = f"IMG_{c_name.upper()}_H"

    with open(header_path, "w") as f:
        f.write(f"/* Auto-generated from {os.path.basename(input_path)} */\n")
        f.write(f"#ifndef {guard}\n")
        f.write(f"#define {guard}\n\n")
        f.write(f"#include <stdint.h>\n\n")
        f.write(
            f"/* {IMG_WIDTH}x{IMG_HEIGHT} 8-bit grayscale ({IMG_SIZE} bytes) */\n")
        f.write(f"static const uint8_t img_{c_name}[{IMG_SIZE}] = {{\n")

        for i in range(0, IMG_SIZE, 16):
            row = flat[i: i + 16]
            vals = ", ".join(f"{v:3d}" for v in row)
            comma = "," if i + 16 < IMG_SIZE else ""
            f.write(f"    {vals}{comma}\n")

        f.write(f"}};\n\n")
        f.write(f"#endif /* {guard} */\n")

    print(f"  HDR: {header_path}")
    return True


def main():
    parser = argparse.ArgumentParser(
        description="Convert images to .bin and C headers")
    parser.add_argument("--input", type=str,
                        help="Single image file to convert")
    parser.add_argument(
        "--input-dir",
        type=str,
        default="input",
        help="Directory of images to convert (default: input/)",
    )
    parser.add_argument(
        "--from-phase1",
        action="store_true",
        help="Use test images from 01_python_verification/test_images/",
    )
    parser.add_argument("--bin-dir", type=str, default="bin",
                        help="Output .bin directory")
    parser.add_argument(
        "--header-dir", type=str, default="c_headers", help="Output .h directory"
    )
    args = parser.parse_args()

    # Create output dirs
    os.makedirs(args.bin_dir, exist_ok=True)
    os.makedirs(args.header_dir, exist_ok=True)

    # Determine input files
    input_files = []

    if args.input:
        input_files = [args.input]
    elif args.from_phase1:
        phase1_dir = os.path.join(
            os.path.dirname(
                __file__), "..", "01_python_verification", "test_images"
        )
        if os.path.isdir(phase1_dir):
            for fname in sorted(os.listdir(phase1_dir)):
                fpath = os.path.join(phase1_dir, fname)
                if os.path.isfile(fpath) and fname.lower().endswith(
                    (".png", ".jpg", ".jpeg", ".bmp", ".tif", ".tiff")
                ):
                    input_files.append(fpath)
        if not input_files:
            print(f"No image files found in {phase1_dir}")
            sys.exit(1)
    else:
        if os.path.isdir(args.input_dir):
            for fname in sorted(os.listdir(args.input_dir)):
                fpath = os.path.join(args.input_dir, fname)
                if os.path.isfile(fpath) and fname.lower().endswith(
                    (".png", ".jpg", ".jpeg", ".bmp", ".tif", ".tiff")
                ):
                    input_files.append(fpath)
        if not input_files:
            print(f"No image files found in {args.input_dir}/")
            print("Usage: python convert_to_bin.py --from-phase1")
            print("   or: python convert_to_bin.py --input image.png")
            sys.exit(1)

    print(f"Converting {len(input_files)} image(s)...\n")
    success = 0
    for fpath in input_files:
        print(f"[{os.path.basename(fpath)}]")
        if convert_image(fpath, args.bin_dir, args.header_dir):
            success += 1
        print()

    print(f"Done: {success}/{len(input_files)} converted successfully.")
    print(f"  Binary files: {args.bin_dir}/")
    print(f"  C headers:    {args.header_dir}/")


if __name__ == "__main__":
    main()
