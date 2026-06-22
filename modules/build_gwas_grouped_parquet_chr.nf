process BUILD_GWAS_GROUPED_PARQUET_CHR {
  tag { "chr${chrom}" }
  publishDir "${params.outdir}/02_gwas_grouped_chr", mode: 'symlink'
  cpus 2
  time '6h'
  memory '32 GB'

  input:
    val chrom
    val gwas_items

  output:
    tuple val(chrom), path("chr_${chrom}")

  script:
  """
  set -euo pipefail

  if [[ -f ${projectDir}/env.sh ]]; then
    source ${projectDir}/env.sh
  fi

  CHR="${chrom}"

  rm -rf "chr_\${CHR}"
  mkdir -p "chr_\${CHR}"

  export CHR="\${CHR}"
  export GWAS_ITEMS="${gwas_items.join('|||')}"
  export MERGE_GAP="${params.coloc_group_merge_gap}"
  export MAX_SIGNALS_PER_GROUP="${params.max_signals_per_group}"

  python3 - <<'PYCODE'
from pathlib import Path
import os
import pandas as pd
import pyarrow as pa
import pyarrow.parquet as pq

chrom_target = os.environ["CHR"]
items = [x for x in os.environ["GWAS_ITEMS"].split("|||") if x]
merge_gap = int(os.environ["MERGE_GAP"])
max_signals = int(os.environ["MAX_SIGNALS_PER_GROUP"])

meta_cols = ["signal", "chromosome", "location_min", "location_max", "signal_strength", "lead_variant"]

records = []

for item in items:
    gwas_id, root_s = item.split("=", 1)
    root = Path(root_s)

    summary = root / "summary.tsv"
    signals_dir = root / "signals"

    if not summary.exists():
        print("SKIP missing summary", summary)
        continue

    df = pd.read_csv(summary, sep="\\t")

    if df.empty:
        continue

    df["chromosome_clean"] = (
        df["chromosome"].astype(str)
        .str.replace("chr", "", regex=False)
        .str.replace(".0", "", regex=False)
    )

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

out_root = Path("chr_" + chrom_target)
out_chr = out_root / chrom_target
out_chr.mkdir(parents=True, exist_ok=True)

if not records:
    print("No signals for chromosome", chrom_target)
    raise SystemExit(0)

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

    first_cols = [c for c in meta_cols if c in merged.columns]
    snp_cols = [c for c in merged.columns if c not in first_cols]

    merged[snp_cols] = merged[snp_cols].fillna(-1e6)
    merged = merged[first_cols + sorted(snp_cols)]

    out = out_chr / ("chr" + str(chrom_target) + "_group_" + str(gi).zfill(6) + ".parquet")
    pq.write_table(pa.Table.from_pandas(merged, preserve_index=False), out)

    print("WROTE", out, "rows", len(merged), "cols", len(merged.columns))

print("DONE chr", chrom_target)
PYCODE

  test -d "chr_\${CHR}"
  """
}
