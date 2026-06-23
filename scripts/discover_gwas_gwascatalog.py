#!/usr/bin/env python3
import argparse
import glob
import os
import sys

def clean_study_name(name):
    for suffix in [".h.tsv.gz", ".tsv.gz", ".gz"]:
        if name.endswith(suffix):
            return name[:-len(suffix)]
    return name

def main():
    ap = argparse.ArgumentParser(description="Discover GWASCatalog harmonised *.h.tsv.gz files")
    ap.add_argument("--root", required=True, help="summary_stats root")
    ap.add_argument(
        "--pattern",
        default="GWASCatalog/**/*.h.tsv.gz",
        help="Glob pattern relative to --root"
    )
    ap.add_argument("--limit", type=int, default=0, help="0=no limit")
    ap.add_argument("--out", required=True, help="Output TSV (GWAS, GWAS_path)")
    args = ap.parse_args()

    pattern = os.path.join(args.root, args.pattern)
    paths = sorted(glob.glob(pattern, recursive=True))

    if not paths:
        print(f"ERROR: no files found with pattern: {pattern}", file=sys.stderr)
        sys.exit(2)

    if args.limit and args.limit > 0:
        paths = paths[:args.limit]

    with open(args.out, "w") as out:
        out.write("GWAS\tGWAS_path\n")

        for p in paths:
            parts = p.split(os.sep)

            try:
                i = parts.index("GWASCatalog")
                paper = parts[i + 1]

                # Case 1:
                # GWASCatalog/Astle_2016/AstleWJ_27863252_GCST004599/harmonised/file.h.tsv.gz
                if "harmonised" in parts:
                    h = parts.index("harmonised")
                    study = parts[h - 1]

                # Case 2:
                # GWASCatalog/de_Lange_2017/file.h.tsv.gz
                else:
                    study = clean_study_name(os.path.basename(p))

            except Exception:
                paper = "GWASCatalog"
                study = clean_study_name(os.path.basename(p))

            gwas_id = f"{paper}_{study}"
            out.write(f"{gwas_id}\t{p}\n")

    print(f"Wrote {len(paths)} GWAS paths to {args.out}", file=sys.stderr)

if __name__ == "__main__":
    main()
