# generate_test_images.py
# Creates three synthetic MRI-like images and binary ground-truth masks.
import os
import numpy as np
import cv2

OUT_DIR = os.path.join(os.path.dirname(__file__), "test_images")
EXPECTED_DIR = os.path.join(OUT_DIR, "expected_results")
os.makedirs(EXPECTED_DIR, exist_ok=True)


def make_mri_like(shape=(256, 256), n_blobs=1, noise_level=12, seed=None):
    if seed is not None:
        np.random.seed(seed)
    img = np.zeros(shape, dtype=np.uint8)

    # base brain-like ellipse
    center = (shape[1]//2 + np.random.randint(-10, 10),
              shape[0]//2 + np.random.randint(-10, 10))
    axes = (shape[1]//3 + np.random.randint(-8, 8),
            shape[0]//2 - 10 + np.random.randint(-8, 8))
    cv2.ellipse(img, center, axes, angle=np.random.randint(0, 30),
                startAngle=0, endAngle=360, color=70, thickness=-1)

    # simulate white-matter variations
    for _ in range(5):
        rr = (np.random.randint(0, shape[1]), np.random.randint(0, shape[0]))
        cv2.circle(img, rr, radius=np.random.randint(10, 30),
                   color=40 + np.random.randint(0, 30), thickness=-1)

    mask = np.zeros(shape, dtype=np.uint8)

    # add tumor blobs (bright)
    for i in range(n_blobs):
        r = np.random.randint(12, 28)
        x = center[0] + np.random.randint(-axes[0]//2, axes[0]//2)
        y = center[1] + np.random.randint(-axes[1]//2, axes[1]//2)
        cv2.circle(img, (x, y), r, color=200 +
                   np.random.randint(-20, 20), thickness=-1)
        cv2.circle(mask, (x, y), r, color=255, thickness=-1)

    # gaussian blur and noise
    img = cv2.GaussianBlur(img, (5, 5), 0)
    noise = np.random.normal(0, noise_level, size=shape).astype(np.int16)
    img = np.clip(img.astype(np.int16) + noise, 0, 255).astype(np.uint8)

    return img, mask


def main():
    seeds = [10, 23, 99]
    blobs = [1, 2, 1]
    for i, (s, b) in enumerate(zip(seeds, blobs), start=1):
        img, mask = make_mri_like(n_blobs=b, seed=s)
        fname = f"brain_{i:02d}.png"
        mname = f"brain_{i:02d}_mask.png"
        cv2.imwrite(os.path.join(OUT_DIR, fname), img)
        cv2.imwrite(os.path.join(EXPECTED_DIR, mname), mask)
        print("Saved", fname, "and", mname)


if __name__ == "__main__":
    main()
