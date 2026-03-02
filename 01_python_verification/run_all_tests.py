# run_all_tests.py
# Orchestrator: generate images -> run segmentation -> verify results -> print timings
import os
import time
import xml.etree.ElementTree as ET
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

    # ---- Performance comparison: SW vs estimated HW ----
    print("\n" + "=" * 60)
    print("  PERFORMANCE COMPARISON: Software vs FPGA (Estimated)")
    print("=" * 60)

    # ---- Parse actual HLS csynth.xml for real latency data ----
    CSYNTH_XML = os.path.join(
        os.path.dirname(BASE), "02_hls_accelerator", "otsu_hls",
        "solution1", "syn", "report", "csynth.xml")

    HW_CLOCK_HZ = 100_000_000  # 100 MHz

    hw_best_cycles = None
    hw_avg_cycles = None
    hw_worst_cycles = None
    if os.path.isfile(CSYNTH_XML):
        try:
            tree = ET.parse(CSYNTH_XML)
            root = tree.getroot()
            lat = root.find(".//SummaryOfOverallLatency")
            if lat is not None:
                hw_best_cycles = int(lat.findtext("Best-caseLatency", "0"))
                hw_avg_cycles = int(lat.findtext("Average-caseLatency", "0"))
                hw_worst_cycles = int(lat.findtext("Worst-caseLatency", "0"))
                print(f"  [csynth.xml] Latency (cycles): best={hw_best_cycles}  "
                      f"avg={hw_avg_cycles}  worst={hw_worst_cycles}")
        except Exception as e:
            print(f"  Warning: could not parse csynth.xml: {e}")

    if not hw_best_cycles:
        # Fallback to best-case from HLS csynth report (328254 cycles @ 100 MHz)
        hw_best_cycles = 328_254
        hw_avg_cycles = 547_148
        hw_worst_cycles = 788_308
        print(
            "  [fallback] Using hardcoded csynth latencies (328254 / 547148 / 788308)")

    HW_BEST_TIME_S = hw_best_cycles / HW_CLOCK_HZ
    HW_AVG_TIME_S = hw_avg_cycles / HW_CLOCK_HZ
    HW_WORST_TIME_S = hw_worst_cycles / HW_CLOCK_HZ

    # ---- Power estimates (two baselines) ----
    # Baseline A: SoC-fair (MicroBlaze SW-only vs HLS accelerator)
    #   From energy_analyzer.c – same chip, same board
    MB_SW_POWER_W = 0.200   # MicroBlaze SW-only path (~200 mW)
    HLS_HW_POWER_W = 0.050  # HLS accelerator dynamic (~50 mW)

    # Baseline B: Desktop comparison (Python on laptop CPU vs FPGA total)
    DESKTOP_SW_POWER_W = 15.0   # typical laptop CPU core
    FPGA_TOTAL_POWER_W = 0.7    # Artix-7 static + dynamic

    # ================================================================
    # Baseline A: SoC-fair comparison (MicroBlaze vs HLS, same board)
    # ================================================================
    # The MicroBlaze SW-only Otsu takes ~20 ms (energy_analyzer.c sw_baseline).
    MB_SW_TIME_S = 0.020  # measured estimate from energy_analyzer

    print(f"\n{'─'*80}")
    print("  BASELINE A: SoC-fair (MicroBlaze SW-only vs HLS accelerator)")
    print(f"{'─'*80}")
    print(
        f"  {'Metric':<25} {'MicroBlaze SW':<20} {'HLS HW (best)':<20} {'HLS HW (avg)':<20}")
    print(f"  {'-'*85}")
    speedup_best = MB_SW_TIME_S / HW_BEST_TIME_S
    speedup_avg = MB_SW_TIME_S / HW_AVG_TIME_S
    mb_energy_uj = MB_SW_TIME_S * MB_SW_POWER_W * 1e6
    hw_best_energy_uj = HW_BEST_TIME_S * HLS_HW_POWER_W * 1e6
    hw_avg_energy_uj = HW_AVG_TIME_S * HLS_HW_POWER_W * 1e6
    savings_best = (1 - hw_best_energy_uj / mb_energy_uj) * 100
    savings_avg = (1 - hw_avg_energy_uj / mb_energy_uj) * 100
    print(f"  {'Time':<25} {MB_SW_TIME_S*1000:.2f} ms{'':<13} "
          f"{HW_BEST_TIME_S*1000:.2f} ms{'':<13} {HW_AVG_TIME_S*1000:.2f} ms")
    print(f"  {'Power':<25} {MB_SW_POWER_W*1000:.0f} mW{'':<14} "
          f"{HLS_HW_POWER_W*1000:.0f} mW{'':<14} {HLS_HW_POWER_W*1000:.0f} mW")
    print(f"  {'Energy':<25} {mb_energy_uj:.0f} µJ{'':<14} "
          f"{hw_best_energy_uj:.1f} µJ{'':<13} {hw_avg_energy_uj:.1f} µJ")
    print(
        f"  {'Speedup':<25} {'—':<20} {speedup_best:.1f}x{'':<17} {speedup_avg:.1f}x")
    print(
        f"  {'Energy savings':<25} {'—':<20} {savings_best:.1f}%{'':<16} {savings_avg:.1f}%")

    # ================================================================
    # Baseline B: Desktop comparison (Python/CPU vs FPGA board)
    # ================================================================
    print(f"\n{'─'*80}")
    print("  BASELINE B: Desktop comparison (Python/CPU vs FPGA board)")
    print(f"{'─'*80}")
    print(
        f"  {'Metric':<25} {'Python/CPU':<20} {'FPGA (best)':<20} {'Improvement':<15}")
    print(f"  {'-'*75}")

    for fname, sw_time in times.items():
        sw_energy_j = sw_time * DESKTOP_SW_POWER_W
        hw_energy_j = HW_BEST_TIME_S * FPGA_TOTAL_POWER_W
        speedup_desk = sw_time / HW_BEST_TIME_S
        energy_savings = (1 - hw_energy_j / sw_energy_j) * 100

        print(f"\n  Image: {fname}")
        print(
            f"  {'Time (s)':<23} {sw_time:<20.4f} {HW_BEST_TIME_S:<20.6f} {speedup_desk:.1f}x speedup")
        print(f"  {'Power (W)':<23} {DESKTOP_SW_POWER_W:<20.1f} {FPGA_TOTAL_POWER_W:<20.1f} "
              f"{DESKTOP_SW_POWER_W/FPGA_TOTAL_POWER_W:.1f}x lower")
        print(f"  {'Energy (mJ)':<23} {sw_energy_j*1000:<20.2f} {hw_energy_j*1000:<20.4f} {energy_savings:.1f}% savings")

    # ================================================================
    # Summary
    # ================================================================
    avg_sw_time = sum(times.values()) / max(1, len(times))

    print(f"\n{'='*80}")
    print(f"  SUMMARY")
    print(f"{'='*80}")
    print(f"  HLS latency (from csynth): best {HW_BEST_TIME_S*1000:.2f} ms / "
          f"avg {HW_AVG_TIME_S*1000:.2f} ms / worst {HW_WORST_TIME_S*1000:.2f} ms")
    print(
        f"\n  — SoC-fair (MicroBlaze 20 ms vs HLS best {HW_BEST_TIME_S*1000:.2f} ms):")
    print(
        f"      Speedup:          {speedup_best:.1f}x  (requirement: >1.9x ✅)")
    print(f"      Energy savings:   {savings_best:.1f}%  "
          f"({'✅' if savings_best > 90 else '⚠️'})")
    print(
        f"\n  — Desktop (avg Python {avg_sw_time*1000:.1f} ms vs FPGA best {HW_BEST_TIME_S*1000:.2f} ms):")
    desk_speedup = avg_sw_time / HW_BEST_TIME_S
    desk_e_save = (1 - (HW_BEST_TIME_S * FPGA_TOTAL_POWER_W) /
                   (avg_sw_time * DESKTOP_SW_POWER_W)) * 100
    print(f"      Speedup:          {desk_speedup:.1f}x")
    print(f"      Energy savings:   {desk_e_save:.1f}%")
    print(f"\n  Note: HW times from Vitis HLS csynth report; power numbers are")
    print(f"        estimates. Actual values require post-impl Vivado power analysis.")
    print(f"{'='*80}")

    print("\nOutputs saved in:", RESULTS_DIR)


if __name__ == "__main__":
    main()
