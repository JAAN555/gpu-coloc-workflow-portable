#!/usr/bin/env python3

import argparse
import glob
import os
import re
import sys


def chrom_sort_key(chrom):
    if chrom == "X":
        return 23
    return int(chrom)


def main():
    ap = argparse.ArgumentParser(
        description="Discover AdipoExpress chromosome LBF files"
    )

    ap.add_argument(
        "--root",
        required=True,
        help="Directory containing AdipoExpress chromosome files"
    )

    ap.add_argument(
        "--pattern",
        default="EURonly_AB1_local_eQTL_meta_chr*.labf_variable.txt.gz",
        help="Glob pattern relative to --root"
    )

    ap.add_argument(
        "--dataset-name",
        default="AdipoExpress"
    )

    ap.add_argument(
        "--limit",
        type=int,
        default=0,
        help="0 = no limit"
    )

    ap.add_argument(
        "--out",
        required=True
    )

    args = ap.parse_args()

    pattern = os.path.join(args.root, args.pattern)
    paths = sorted(glob.glob(pattern))

    # Ignore the combined file
    paths = [
        p for p in paths
        if os.path.basename(p) != "AdipoExpress_full.labf_variable.txt.gz"
    ]

    if not paths:
        print(f"ERROR: no files found using {pattern}", file=sys.stderr)
        sys.exit(2)

    rows = []

    for p in paths:
        base = os.path.basename(p)

        m = re.search(
            r"_chr([0-9]+|X)\.labf_variable\.txt\.gz$",
            base
        )

        if not m:
            continue

        chrom = m.group(1)

        rows.append(
            (
                args.dataset_name,
                chrom,
                p
            )
        )

    rows.sort(key=lambda x: chrom_sort_key(x[1]))

    if args.limit > 0:
        rows = rows[:args.limit]

    with open(args.out, "w") as out:
        out.write("dataset\tchrom\tpath\n")

        for dataset, chrom, path in rows:
            out.write(
                f"{dataset}\t{chrom}\t{path}\n"
            )

    print(
        f"Wrote {len(rows)} chromosome files to {args.out}",
        file=sys.stderr
    )


if __name__ == "__main__":
    main()
