"""
Postprocessing script for gemtoo sweep output JSON files.

Usage:
    python postprocess_sweep.py <dir1> [dir2 ...]

For each JSON file found in the given directories, extracts architecture
parameters and key metrics (tread, twrite, total_area), then:
  - Reports the configurations that minimize each objective
  - Plots scatter charts of rows_per_subarray vs cols_per_subarray,
    color-coded by each objective value
"""

import json
import sys
import glob
import os
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.colors as mcolors


def load_results(dirs):
    records = []
    for d in dirs:
        for path in glob.glob(os.path.join(d, "*.json")):
            with open(path) as f:
                data = json.load(f)
            arch = data["architecture"]
            pbl = arch["n_partitioning_bl"]
            pwl = arch["n_partitioning_wl"]
            fbl = arch["n_folding_bl"]
            fwl = arch["n_folding_wl"]
            rows_per_subarray = arch["n_rows"] // (2 ** (pbl + fbl))
            cols_per_subarray = arch["n_word"] // (2 ** (pwl + fwl))
            records.append({
                "file": os.path.basename(path),
                "input_file": data["input_file"],
                "n_rows": arch["n_rows"],
                "n_word": arch["n_word"],
                "n_partitioning_bl": pbl,
                "n_partitioning_wl": pwl,
                "n_folding_bl": fbl,
                "n_folding_wl": fwl,
                "rows_per_subarray": rows_per_subarray,
                "cols_per_subarray": cols_per_subarray,
                "tread": data["timing"]["tread"],
                "twrite": data["timing"]["twrite"],
                "total_area": data["area"]["total_area"],
            })
    return records


def report_best(records):
    objectives = [
        ("tread",      "Read time (s)"),
        ("twrite",     "Write time (s)"),
        ("total_area", "Total area (m^2)"),
    ]
    for key, label in objectives:
        best = min(records, key=lambda r: r[key])
        print(f"\nBest {label}: {best[key]:.4e}")
        print(f"  Config: {best['input_file']}")
        print(f"  pbl={best['n_partitioning_bl']} pwl={best['n_partitioning_wl']} "
              f"fbl={best['n_folding_bl']} fwl={best['n_folding_wl']}")
        print(f"  rows_per_subarray={best['rows_per_subarray']}  "
              f"cols_per_subarray={best['cols_per_subarray']}")


def plot_scatter(records, dirs, output_dir):
    objectives = [
        ("tread",      "Read time (s)",   "viridis_r"),
        ("twrite",     "Write time (s)",  "plasma_r"),
        ("total_area", "Total area (m²)", "cividis_r"),
    ]

    rows = np.array([r["rows_per_subarray"] for r in records], dtype=float)
    cols = np.array([r["cols_per_subarray"] for r in records], dtype=float)

    # Add small jitter in log2 space so displacement is uniform on the log axis
    rng = np.random.default_rng(0)
    jitter_scale = 0.15
    rows_j = 2 ** (np.log2(rows) + rng.uniform(-jitter_scale, jitter_scale, size=len(rows)))
    cols_j = 2 ** (np.log2(cols) + rng.uniform(-jitter_scale, jitter_scale, size=len(cols)))

    fig, axes = plt.subplots(1, 3, figsize=(18, 6))

    for ax, (key, label, cmap) in zip(axes, objectives):
        values = np.array([r[key] for r in records])
        norm = mcolors.LogNorm(vmin=values.min(), vmax=values.max())
        sc = ax.scatter(cols_j, rows_j, c=values, cmap=cmap, norm=norm, s=80, edgecolors="k", linewidths=0.4)

        # Colorbar with log-spaced ticks
        cb = fig.colorbar(sc, ax=ax)
        tick_vals = np.geomspace(values.min(), values.max(), 6)
        cb.set_ticks(tick_vals)
        cb.set_ticklabels([f"{v:.2e}" for v in tick_vals])
        cb.set_label(label, fontsize=10)

        # Mark the best (minimum) point
        best_idx = int(np.argmin(values))
        ax.scatter(cols_j[best_idx], rows_j[best_idx],
                   c="red", s=160, marker="*", zorder=5, label="best")
        ax.legend(fontsize=9)

        ax.set_xlabel("Columns per subarray", fontsize=11)
        ax.set_ylabel("Rows per subarray", fontsize=11)
        ax.set_title(f"Minimize {label}", fontsize=12)
        ax.set_xscale("log", base=2)
        ax.set_yscale("log", base=2)

        # Use integer ticks for subarray dims
        #unique_cols = sorted(set(int(c) for c in cols))
        #unique_rows = sorted(set(int(r) for r in rows))
        #ax.set_xticks(unique_cols)
        #ax.set_xticklabels([str(c) for c in unique_cols], rotation=45, ha="right")
        #ax.set_yticks(unique_rows)

    fig.tight_layout()
    os.makedirs(output_dir, exist_ok=True)
    tag = "_".join(os.path.basename(d.rstrip("/")) for d in dirs)
    out_path = os.path.join(output_dir, f"sweep_scatter_{tag}.png")
    fig.savefig(out_path, dpi=150)
    print(f"\nPlot saved to: {out_path}")


def main():
    assert len(sys.argv) >= 2, "Usage: python postprocess_sweep.py <dir1> [dir2 ...]"
    dirs = sys.argv[1:]
    for d in dirs:
        assert os.path.isdir(d), f"Not a directory: {d}"

    records = load_results(dirs)
    assert len(records) > 0, "No JSON files found in the given directories"

    print(f"Loaded {len(records)} configurations from {len(dirs)} director(ies).")
    report_best(records)
    figs_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "figs")
    plot_scatter(records, dirs, output_dir=figs_dir)


if __name__ == "__main__":
    main()
