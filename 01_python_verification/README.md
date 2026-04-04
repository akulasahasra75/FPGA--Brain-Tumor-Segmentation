# 01_python_verification

## Purpose

Software-only Python prototype to verify the Otsu thresholding algorithm before hardware implementation.

## Files

- **`otsu_watershed.py`** - Main Otsu thresholding + watershed segmentation implementation
- **`generate_test_images.py`** - Generates test images for validation
- **`verify_results.py`** - Verifies segmentation results against expected output
- **`run_all_tests.py`** - Runs all verification tests
- **`requirements.txt`** - Python dependencies (NumPy, OpenCV, Pillow)

## Usage

```bash
pip install -r requirements.txt
python run_all_tests.py
```

## Output

- Processed images saved to `../05_test_images/output/`
- Console output shows threshold values and processing time
- Used to validate algorithm correctness before HLS/HDL implementation
