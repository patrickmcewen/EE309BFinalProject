#!/usr/bin/env python3
"""
Generate architecture sweep input files for GEMTOO.

Sweeps n_partitioning_bl, n_partitioning_wl, n_folding_bl, n_folding_wl
for a fixed n_rows and n_word, based on a template input .m file.
"""

import argparse
import itertools
import os
import re
import shutil
import math


def parse_args():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('--n_rows', type=int, required=True)
    p.add_argument('--n_word', type=int, required=True)
    p.add_argument('--base', default='load_28fdsoi_3tn.m',
                   help='Base input .m file (default: load_28fdsoi_3tn.m)')
    p.add_argument('--partitioning_bl', type=int, nargs='+', default=[0, 1, 2, 3, 4],
                   metavar='N', help='Values for n_partitioning_bl (default: 0 1 2 3 4)')
    p.add_argument('--partitioning_wl', type=int, nargs='+', default=[0, 1, 2, 3, 4],
                   metavar='N', help='Values for n_partitioning_wl (default: 0 1 2 3 4)')
    p.add_argument('--folding_bl', type=int, nargs='+', default=[0, 1, 2, 3, 4],
                   metavar='N', help='Values for n_folding_bl (default: 0 1 2)')
    p.add_argument('--folding_wl', type=int, nargs='+', default=[0, 1, 2, 3, 4],
                   metavar='N', help='Values for n_folding_wl (default: 0 1 2)')
    p.add_argument('--max_rows', type=int, default=None,
                   metavar='N', help='Max rows in any subarray; filters configs where n_rows/2^(pbl+fbl) > N')
    p.add_argument('--max_cols', type=int, default=None,
                   metavar='N', help='Max cols in any subarray; filters configs where n_word/2^(pwl+fwl) > N')
    p.add_argument('--min_rows', type=int, default=None,
                   metavar='N', help='Min rows in any subarray; filters configs where n_rows/2^(pbl+fbl) < N')
    p.add_argument('--min_cols', type=int, default=None,
                   metavar='N', help='Min cols in any subarray; filters configs where n_word/2^(pwl+fwl) < N')
    return p.parse_args()


def substitute(text, param, value):
    pattern = rf'(my_gcedram_in\.{param}\s*=\s*)[^;]+(;)'
    replacement = rf'\g<1>{value}\2'
    result, n = re.subn(pattern, replacement, text)
    assert n == 1, f'Expected exactly one match for {param}, found {n}'
    return result


def main():
    args = parse_args()

    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_path = os.path.join(script_dir, args.base)
    assert os.path.isfile(base_path), f'Base file not found: {base_path}'

    with open(base_path) as f:
        base_text = f.read()

    base_func = os.path.splitext(args.base)[0]
    out_dir = os.path.join(script_dir, "sweep_files", f'sweep_r{args.n_rows}_w{args.n_word}')
    os.makedirs(out_dir, exist_ok=True)

    combinations = list(itertools.product(
        args.partitioning_bl,
        args.partitioning_wl,
        args.folding_bl,
        args.folding_wl,
    ))

    if args.max_rows is not None:
        min_bl_shift = math.ceil(math.log2(args.n_rows / args.max_rows)) if args.n_rows > args.max_rows else 0
        before = len(combinations)
        combinations = [(pbl, pwl, fbl, fwl) for pbl, pwl, fbl, fwl in combinations
                        if pbl + fbl >= min_bl_shift]
        print(f'max_rows={args.max_rows}: requires pbl+fbl>={min_bl_shift}, kept {len(combinations)}/{before}')

    if args.max_cols is not None:
        min_wl_shift = math.ceil(math.log2(args.n_word / args.max_cols)) if args.n_word > args.max_cols else 0
        before = len(combinations)
        combinations = [(pbl, pwl, fbl, fwl) for pbl, pwl, fbl, fwl in combinations
                        if pwl + fwl >= min_wl_shift]
        print(f'max_cols={args.max_cols}: requires pwl+fwl>={min_wl_shift}, kept {len(combinations)}/{before}')

    if args.min_rows is not None:
        max_bl_shift = math.floor(math.log2(args.n_rows / args.min_rows)) if args.n_rows >= args.min_rows else -1
        before = len(combinations)
        combinations = [(pbl, pwl, fbl, fwl) for pbl, pwl, fbl, fwl in combinations
                        if pbl + fbl <= max_bl_shift]
        print(f'min_rows={args.min_rows}: requires pbl+fbl<={max_bl_shift}, kept {len(combinations)}/{before}')

    if args.min_cols is not None:
        max_wl_shift = math.floor(math.log2(args.n_word / args.min_cols)) if args.n_word >= args.min_cols else -1
        before = len(combinations)
        combinations = [(pbl, pwl, fbl, fwl) for pbl, pwl, fbl, fwl in combinations
                        if pwl + fwl <= max_wl_shift]
        print(f'min_cols={args.min_cols}: requires pwl+fwl<={max_wl_shift}, kept {len(combinations)}/{before}')

    print(f'Output directory: {out_dir}')
    print(f'Generating {len(combinations)} configurations...')

    for pbl, pwl, fbl, fwl in combinations:
        func_name = f'{base_func}_r{args.n_rows}_w{args.n_word}_pbl{pbl}_pwl{pwl}_fbl{fbl}_fwl{fwl}'
        out_path = os.path.join(out_dir, func_name + '.m')

        text = base_text
        # Update function name
        text = re.sub(rf'function\s+\w+\s*=\s*{re.escape(base_func)}',
                      f'function my_gcedram_in = {func_name}', text)
        # Update architecture parameters
        text = substitute(text, 'n_rows', args.n_rows)
        text = substitute(text, 'n_word', args.n_word)
        text = substitute(text, 'n_partitioning_bl', pbl)
        text = substitute(text, 'n_partitioning_wl', pwl)
        text = substitute(text, 'n_folding_bl', fbl)
        text = substitute(text, 'n_folding_wl', fwl)

        with open(out_path, 'w') as f:
            f.write(text)

    print(f'Done. {len(combinations)} files written to {out_dir}/')


if __name__ == '__main__':
    main()
