# run_all_tests.py
# Orchestrator: generate images -> run segmentation -> verify results -> print timings
import os
import time
from generate_test_images import main as gen_main
from otsu_watershed import run_all
from verify_results import main as verify_main

BASE = os.path.dirname(__file__)
TEST_DIR = os.path.join(BASE, "test_images")
RESULTS_DIR = os.path.join(TEST_DIR, "results")


def ensure_dirs():
    os.makedirs(TEST_DIR, exist_ok=True)
    os.makedirs(RESULTS_DIR, exist_ok=True)
    os.makedirs(os.path.join(TEST_DIR, "expected_results"), exist_ok=True)


def main():
    ensure_dirs()
    print("=== Generating test images ===")
    gen_main()
    print("\n=== Running Otsu+Watershed on images ===")
    start = time.perf_counter()
    times, metrics = run_all()
    total = time.perf_counter() - start
    print(
        f"Processed {len(times)} images in {total:.3f} s (avg {total/max(1, len(times)):.3f} s/image)\n")
    print("=== Verifying results ===")
    verify_main()
    print("\nOutputs saved in:", RESULTS_DIR)


if __name__ == "__main__":
    main()
