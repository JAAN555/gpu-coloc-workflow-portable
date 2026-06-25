#!/bin/bash -euo pipefail
set -euo pipefail

  export GWAS_ROOTS='Suzuki_Aragam=/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/Suzuki_Aragam_parquets|FinnGen_MVP_UKBB=/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/FinnGen+MVP+UKBB_parquets|FinnGen=/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/FinnGen_lbf_parquets|Astle_2016_m1e6=/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_astle_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped|de_Lange_2017_m1e6=/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_de_lange_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped'
  export EQTL_ROOTS='ge_microarray_aptamer=/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/ge_microarray_aptamer_parquets|exon=/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/exon_parquets|leafcutter=/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/leafcutter_parquets|tx=/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/tx_parquets|txrev=/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets'
  export P12='1e-6'
  export H4='0.8'

  python3 - <<'PY'
from pathlib import Path
import pandas as pd
import os
import re

def parse_roots(s):
    rows = []
    for item in s.split("|"):
        item = item.strip()
        if not item:
            continue
        if "=" not in item:
            raise SystemExit(f"ERROR: root entry must be name=/path, got: {item}")
        name, path = item.split("=", 1)
        rows.append((name.strip(), Path(path.strip()).resolve()))
    return rows

def has_parquets(root):
    return root.exists() and root.is_dir() and any(root.glob("*/*.parquet"))

def safe_id(s):
    s = re.sub(r"[^A-Za-z0-9_.-]+", "_", s)
    return s.strip("_")

gwas_roots = parse_roots(os.environ["GWAS_ROOTS"])
eqtl_roots = parse_roots(os.environ["EQTL_ROOTS"])

p12 = os.environ["P12"]
H4 = os.environ["H4"]

rows = []

for gwas_name, gwas_path in gwas_roots:
    if not has_parquets(gwas_path):
        print(f"SKIP GWAS root without parquets: {gwas_name} {gwas_path}")
        continue

    for eqtl_name, eqtl_path in eqtl_roots:
        if not has_parquets(eqtl_path):
            print(f"SKIP eQTL root without parquets: {eqtl_name} {eqtl_path}")
            continue

        comparison_id = safe_id(f"{gwas_name}_vs_{eqtl_name}")

        rows.append({
            "comparison_id": comparison_id,
            "gwas_name": gwas_name,
            "eqtl_name": eqtl_name,
            "dir1": str(gwas_path),
            "dir2": str(eqtl_path),
            "p12": p12,
            "H4": H4,
        })

if not rows:
    raise SystemExit("ERROR: no valid comparison rows created.")

df = pd.DataFrame(rows)
df.to_csv("comparisons.tsv", sep="\t", index=False)

print("Created comparisons:")
print(df.to_string(index=False))
print()
print("N comparisons:", len(df))
PY

  test -s comparisons.tsv
