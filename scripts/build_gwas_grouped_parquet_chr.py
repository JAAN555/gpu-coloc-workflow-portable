#!/usr/bin/env python3
import argparse
import os
from pathlib import Path

import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq


META_COLS = [
"signal",
"chromosome",
"location_min",
"location_max",
"signal_strength",
"lead_variant",
]


def clean_chromosome(x):
return (
str(x)
.replace("chr", "")
.replace(".0", "")
)


def main():
ap = argparse.ArgumentParser(description="Build chromosome-level grouped GWAS parquet files")
ap.add_argument("--chrom", required=True)
ap.add_argument("--gwas-items", required=True, help="Items formatted as GWAS_ID=ROOT|||GWAS_ID=ROOT")
ap.add_argument("--merge-gap", type=int, required=True)
ap.add_argument("--max-signals-per-group", type=int, required=True)
ap.add_argument("--outdir", required=True)
args = ap.parse_args()

chrom_target = str(args.chrom)
items = [x for x in args.gwas_items.split("|||") if x]
merge_gap = int(args.merge_gap)
max_signals = int(args.max_signals_per_group)

records = []

for item in items:
gwas_id, root_s = item.split("=", 1)
root = Path(root_s)

summary = root / "summary.tsv"
signals_dir = root / "signals"

if not summary.exists():
print("SKIP missing summary", summary)
continue

df = pd.read_csv(summary, sep="\t")

if df.empty:
continue

df["chromosome_clean"] = df["chromosome"].map(clean_chromosome)
df = df[df["chromosome_clean"] == chrom_target].copy()

if df.empty:
continue

for _, row in df.iterrows():
signal = str(row["signal"])
pickle_file = signals_dir / (signal + ".pickle")

if not pickle_file.exists():
print("SKIP missing pickle", pickle_file)
continue

records.append({
"gwas_id": gwas_id,
"pickle_file": str(pickle_file),
"signal": signal,
"chromosome": chrom_target,
"location_min": int(row["location_min"]),
"location_max": int(row["location_max"]),
"signal_strength": float(row["signal_strength"]),
"lead_variant": str(row["lead_variant"]),
})

out_root = Path(args.outdir)
out_chr = out_root / chrom_target
out_chr.mkdir(parents=True, exist_ok=True)

if not records:
print("No signals for chromosome", chrom_target)
return

idx = pd.DataFrame(records)
idx = idx.sort_values(["location_min", "location_max", "signal"]).reset_index(drop=True)

groups = []
current = []
cur_end = None

for _, r in idx.iterrows():
start = int(r["location_min"])
end = int(r["location_max"])

if not current:
current = [r]
cur_end = end
continue

can_merge_by_region = start <= cur_end + merge_gap
can_merge_by_size = len(current) < max_signals

if can_merge_by_region and can_merge_by_size:
current.append(r)
cur_end = max(cur_end, end)
else:
groups.append(current)
current = [r]
cur_end = end

if current:
groups.append(current)

print("chrom", chrom_target, "signals", len(idx), "groups", len(groups))

for gi, group in enumerate(groups, start=1):
frames = []

for r in group:
mat = pd.read_pickle(r["pickle_file"]).reset_index(drop=True)

mat.insert(0, "lead_variant", str(r["lead_variant"]))
mat.insert(0, "signal_strength", float(r["signal_strength"]))
mat.insert(0, "location_max", int(r["location_max"]))
mat.insert(0, "location_min", int(r["location_min"]))
mat.insert(0, "chromosome", str(r["chromosome"]))
mat.insert(0, "signal", str(r["signal"]))

frames.append(mat)

merged = pd.concat(frames, ignore_index=True, sort=False)

first_cols = [c for c in META_COLS if c in merged.columns]
snp_cols = [c for c in merged.columns if c not in first_cols]

merged[snp_cols] = merged[snp_cols].fillna(-1e6)
merged = merged[first_cols + sorted(snp_cols)]

out = out_chr / ("chr" + str(chrom_target) + "_group_" + str(gi).zfill(6) + ".parquet")
pq.write_table(pa.Table.from_pandas(merged, preserve_index=False), out)

print("WROTE", out, "rows", len(merged), "cols", len(merged.columns))

print("DONE chr", chrom_target)


if __name__ == "__main__":
main()
