#!/usr/bin/env python3
"""
Chain sweep_arch.py and MATLAB run_sweep for every configuration in a YAML config file.

Usage:
    python run_sweeps.py [sweeps.yaml]           # run all sweeps + postprocess
    python run_sweeps.py --postprocess-only       # skip sweeps, just postprocess
    python run_sweeps.py sweeps.yaml --postprocess-only

Config file defaults to sweeps.yaml in the same directory as this script.
"""

import os
import sys
import subprocess
import yaml

REPO_ROOT       = os.path.dirname(os.path.abspath(__file__))
MATLAB_ROOT     = os.path.join(REPO_ROOT, "gemtoo", "matlab")
SWEEP_ARCH      = os.path.join(REPO_ROOT, "gemtoo", "matlab", "src", "inputs", "sweep_arch.py")
INPUTS_DIR      = os.path.join(MATLAB_ROOT, "src", "inputs", "sweep_files")
OUTPUTS_ROOT    = os.path.join(MATLAB_ROOT, "src", "outputs")
POSTPROCESS     = os.path.join(OUTPUTS_ROOT, "postprocess_sweep.py")


def run(cmd, **kwargs):
    print(f"\n>>> {' '.join(cmd)}")
    result = subprocess.run(cmd, **kwargs)
    assert result.returncode == 0, f"Command failed with exit code {result.returncode}"


def build_sweep_arch_cmd(cfg):
    cmd = [sys.executable, SWEEP_ARCH,
           "--n_rows", str(cfg["n_rows"]),
           "--n_word",  str(cfg["n_word"])]

    if "base" in cfg:
        cmd += ["--base", cfg["base"]]
    for flag, key in [("--partitioning_bl", "partitioning_bl"),
                      ("--partitioning_wl", "partitioning_wl"),
                      ("--folding_bl",      "folding_bl"),
                      ("--folding_wl",      "folding_wl")]:
        if key in cfg:
            cmd += [flag] + [str(v) for v in cfg[key]]
    for flag, key in [("--max_rows", "max_rows"), ("--max_cols", "max_cols"),
                      ("--min_rows", "min_rows"), ("--min_cols", "min_cols")]:
        if cfg.get(key) is not None:
            cmd += [flag, str(cfg[key])]
    return cmd


def run_matlab_sweep(sweep_dir, out_dir):
    # Build a one-liner that sets up paths then calls run_sweep
    matlab_cmd = (
        f"p=userpath(); addpath(p); "
        f"run_sweep('{sweep_dir}', '{out_dir}'); "
        f"exit"
    )
    run(["matlab", "-nodisplay", "-nosplash", "-nodesktop", "-r", matlab_cmd],
        cwd=MATLAB_ROOT)


def process_sweep(cfg, out_dir):
    name  = cfg.get("name", f"sweep_r{cfg['n_rows']}_w{cfg['n_word']}")
    n_rows, n_word = cfg["n_rows"], cfg["n_word"]
    sweep_dir = os.path.join(INPUTS_DIR, f"sweep_r{n_rows}_w{n_word}")

    print(f"\n{'='*60}")
    print(f"Sweep: {name}")
    print(f"  sweep_dir : {sweep_dir}")
    print(f"  out_dir   : {out_dir}")
    print(f"{'='*60}")

    # Step 1: generate input .m files
    run(build_sweep_arch_cmd(cfg))

    # Step 2: run GEMTOO via MATLAB
    run_matlab_sweep(sweep_dir, out_dir)


def main():
    args = sys.argv[1:]
    postprocess_only = "--postprocess-only" in args
    args = [a for a in args if a != "--postprocess-only"]

    config_path = args[0] if args else os.path.join(REPO_ROOT, "sweeps.yaml")
    assert os.path.isfile(config_path), f"Config file not found: {config_path}"

    with open(config_path) as f:
        config = yaml.safe_load(f)

    sweeps = config.get("sweeps", [])
    assert len(sweeps) > 0, "No sweeps defined in config"

    # Compute output dirs for all sweeps (needed for both paths)
    out_dirs = [
        cfg.get("out_dir") or os.path.join(OUTPUTS_ROOT, f"sweep_r{cfg['n_rows']}_w{cfg['n_word']}")
        for cfg in sweeps
    ]

    if not postprocess_only:
        for cfg, out_dir in zip(sweeps, out_dirs):
            process_sweep(cfg, out_dir)
        print(f"\nAll {len(sweeps)} sweep(s) complete.")

    print(f"\n{'='*60}")
    print("Running postprocessing...")
    print(f"{'='*60}")
    run([sys.executable, POSTPROCESS] + out_dirs)


if __name__ == "__main__":
    main()
