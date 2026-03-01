# otsu_watershed.py
# Implements Otsu thresholding + watershed segmentation pipeline.
import os
import cv2
import numpy as np
from time import perf_counter
from typing import Tuple

BASE_DIR = os.path.dirname(__file__)
IN_DIR = os.path.join(BASE_DIR, "test_images")
OUT_SEG_DIR = os.path.join(IN_DIR, "results")
os.makedirs(OUT_SEG_DIR, exist_ok=True)


def dice_coef(pred: np.ndarray, gt: np.ndarray) -> float:
    pred_bool = (pred > 0).astype(np.uint8)
    gt_bool = (gt > 0).astype(np.uint8)
    inter = (pred_bool & gt_bool).sum()
    denom = pred_bool.sum() + gt_bool.sum()
    if denom == 0:
        return 1.0 if inter == 0 else 0.0
    return 2.0 * inter / denom


def iou(pred: np.ndarray, gt: np.ndarray) -> float:
    pred_bool = (pred > 0).astype(np.uint8)
    gt_bool = (gt > 0).astype(np.uint8)
    inter = (pred_bool & gt_bool).sum()
    union = (pred_bool | gt_bool).sum()
    if union == 0:
        return 1.0 if inter == 0 else 0.0
    return inter / union


def process_image(img: np.ndarray, return_overlay=True, debug=True) -> Tuple[np.ndarray, np.ndarray]:
    """
    Otsu thresholding + watershed segmentation pipeline:
      1. Otsu threshold (fallback to stricter threshold if Otsu covers too much area)
      2. Distance transform + watershed to separate touching regions
      3. Per-component mean intensity filtering
      4. Morphological refinement
    Params tuned for synthetic images; adjust min_area and intensity_factor as needed.
    """
    h, w = img.shape
    area_img = h * w

    # blur to remove small noise
    blur = cv2.GaussianBlur(img, (5, 5), 0)

    # global image stats
    img_mean = float(blur.mean())
    img_std = float(blur.std())
    if debug:
        print(f"img mean={img_mean:.1f}, std={img_std:.1f}, area={area_img}")

    # 1) Otsu
    _, th_otsu = cv2.threshold(
        blur, 0, 255, cv2.THRESH_BINARY + cv2.THRESH_OTSU)
    nonzero_otsu = int((th_otsu > 0).sum())
    frac_otsu = nonzero_otsu / area_img
    if debug:
        print("Otsu nonzero:", nonzero_otsu, f"({frac_otsu*100:.1f}%)")

    # If Otsu selects too much (>20% of image) use stricter threshold
    strict_frac_thresh = 0.20
    if frac_otsu > strict_frac_thresh:
        k = 0.6
        strict_t = int(max(1, img_mean + k * img_std))
        if debug:
            print("Otsu too permissive, using strict threshold:", strict_t)
        _, th = cv2.threshold(blur, strict_t, 255, cv2.THRESH_BINARY)
    else:
        th = th_otsu

    # morphological cleaning
    kernel = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (3, 3))
    th = cv2.morphologyEx(th, cv2.MORPH_OPEN, kernel, iterations=1)
    th = cv2.morphologyEx(th, cv2.MORPH_CLOSE, kernel, iterations=1)

    # 2) Watershed segmentation
    # Sure background via dilation
    sure_bg = cv2.dilate(th, kernel, iterations=3)

    # Distance transform for sure foreground
    dist_transform = cv2.distanceTransform(th, cv2.DIST_L2, 5)
    dist_max = dist_transform.max()

    if dist_max == 0:
        # No foreground found — return empty segmentation
        seg = np.zeros_like(img, dtype=np.uint8)
        overlay = None
        if return_overlay:
            img_color = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
            overlay = img_color.copy()
        return seg, overlay

    _, sure_fg = cv2.threshold(dist_transform, 0.4 * dist_max, 255, 0)
    sure_fg = np.uint8(sure_fg)

    # Unknown region
    unknown = cv2.subtract(sure_bg, sure_fg)

    # Marker labelling
    num_labels, markers = cv2.connectedComponents(sure_fg)
    markers = markers + 1            # background becomes 1 (not 0)
    markers[unknown == 255] = 0      # unknown region marked as 0

    # Apply watershed
    img_color = cv2.cvtColor(img, cv2.COLOR_GRAY2BGR)
    markers = cv2.watershed(img_color, markers)
    # markers == -1: boundaries, markers == 1: background, markers > 1: regions

    if debug:
        print("watershed labels found:", num_labels)

    # 3) Filter components by area and intensity
    comps = []
    for lbl in range(2, num_labels + 1):  # skip background (1)
        comp_mask = (markers == lbl).astype(np.uint8)
        area = int(comp_mask.sum())
        if area == 0:
            continue
        mean_int = float(cv2.mean(img, mask=comp_mask)[0])
        comps.append((lbl, area, mean_int))

    if debug:
        print("components (label, area, mean_int) sample:", comps[:6])

    min_area = 200
    intensity_factor = 0.7

    selected_labels = []
    for lbl, area, mean_int in comps:
        if area >= min_area and mean_int >= img_mean + intensity_factor * img_std:
            selected_labels.append(lbl)

    # fallback: pick component with highest mean intensity
    if not selected_labels and comps:
        comps_sorted = sorted(comps, key=lambda x: (x[2], x[1]), reverse=True)
        selected_labels = [comps_sorted[0][0]]
        if debug:
            print("No component met thresholds; falling back to highest-mean component:",
                  comps_sorted[0])

    # build segmentation mask
    seg = np.zeros_like(img, dtype=np.uint8)
    for lbl in selected_labels:
        seg[markers == lbl] = 255

    # 4) Morphological refinement
    seg = cv2.morphologyEx(seg, cv2.MORPH_OPEN, kernel, iterations=1)
    seg = cv2.morphologyEx(seg, cv2.MORPH_CLOSE, kernel, iterations=2)

    if debug:
        print("final seg nonzero:", int((seg > 0).sum()),
              "selected labels:", selected_labels)

    # overlay
    overlay = None
    if return_overlay:
        overlay = img_color.copy()
        overlay[seg > 0] = (0, 0, 255)
        overlay = cv2.addWeighted(img_color, 0.6, overlay, 0.4, 0)

    return seg, overlay


def run_all(input_dir=IN_DIR, save_outputs=True):
    times = {}
    metrics = {}
    files = sorted([f for f in os.listdir(input_dir) if f.endswith(
        ".png") and not f.endswith("_mask.png")])
    for f in files:
        path = os.path.join(input_dir, f)
        img = cv2.imread(path, cv2.IMREAD_GRAYSCALE)
        t0 = perf_counter()
        seg, overlay = process_image(img, return_overlay=True)
        t1 = perf_counter()
        dt = t1 - t0
        times[f] = dt
        metrics[f] = {'time_s': dt}
        if save_outputs:
            cv2.imwrite(os.path.join(
                OUT_SEG_DIR, f.replace(".png", "_seg.png")), seg)
            if overlay is not None:
                cv2.imwrite(os.path.join(OUT_SEG_DIR, f.replace(
                    ".png", "_overlay.png")), overlay)
    return times, metrics


if __name__ == "__main__":
    t, m = run_all()
    for k in t:
        print(f"{k}: {t[k]:.4f} s")
