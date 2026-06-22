#!/usr/bin/env python3
import argparse
import glob
import os
import sys

def main():
    ap = argparse.ArgumentParser(description="Discover GWASCatalog harmonised *.h.tsv.gz")
    ap.add_argument("--root", required=True, help="summary_stats root")
    ap.add_argument("--limit", type=int, default=0, help="0=no limit")
    ap.add_argument("--out", required=True, help="Output TSV (GWAS, GWAS_path)")
    args = ap.parse_args()

    gwascatalog = os.path.join(args.root, "GWASCatalog")
    pattern = os.path.join(gwascatalog, "**", "harmonised", "*.h.tsv.gz")
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
                paper = parts[i+1]
                study = parts[i+2]
            except Exception:
                paper = "GWASCatalog"
                study = os.path.basename(os.path.dirname(os.path.dirname(p)))
            gwas_id = f"{paper}_{study}"
            out.write(f"{gwas_id}\t{p}\n")

    print(f"Wrote {len(paths)} GWAS paths to {args.out}", file=sys.stderr)

if __name__ == "__main__":
    main()
