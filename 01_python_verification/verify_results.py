# verify_results.py
# Compares results saved in test_images/results with expected_results masks
import os
import cv2
import numpy as np
from otsu_watershed import dice_coef, iou
from pathlib import Path

BASE = os.path.dirname(__file__)
TEST_DIR = os.path.join(BASE, "test_images")
RESULTS_DIR = os.path.join(TEST_DIR, "results")
EXPECTED_DIR = os.path.join(TEST_DIR, "expected_results")


def load_mask(path):
    m = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
    if m is None:
        return None
    return (m > 127).astype(np.uint8)


def main():
    res_files = sorted([f for f in os.listdir(
        RESULTS_DIR) if f.endswith("_seg.png")])
    summary = []
    for res in res_files:
        base = res.replace("_seg.png", "")
        exp_name = f"{base}_mask.png"
        exp_path = os.path.join(EXPECTED_DIR, exp_name)
        res_path = os.path.join(RESULTS_DIR, res)
        if not os.path.exists(exp_path):
            print("WARNING: expected mask missing for", base)
            continue
        gt = load_mask(exp_path)
        pred = load_mask(res_path)
        if gt is None or pred is None:
            print(f"WARNING: could not load mask for {base}, skipping")
            continue
        d = dice_coef(pred, gt)
        j = iou(pred, gt)
        summary.append((base, d, j))
        print(f"{base}: Dice={d:.4f}, IoU={j:.4f}")
    if summary:
        avg_d = np.mean([s[1] for s in summary])
        avg_j = np.mean([s[2] for s in summary])
        print(f"Average Dice: {avg_d:.4f}  Average IoU: {avg_j:.4f}")
    else:
        print("No results to summarize.")


if __name__ == "__main__":
    main()
