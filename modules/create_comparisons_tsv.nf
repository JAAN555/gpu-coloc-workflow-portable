process CREATE_COMPARISONS_TSV {
  publishDir "${params.outdir}/00_comparisons", mode: 'copy'
  cpus 1
  time '10m'
  memory '1 GB'

  output:
    path("comparisons.tsv")

  script:
  """
  set -euo pipefail

  export GWAS_ROOTS='${params.gwas_roots}'
  export EQTL_ROOTS='${params.eqtl_roots}'
  export P12='${params.p12}'
  export H4='${params.H4}'

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
df.to_csv("comparisons.tsv", sep="\\t", index=False)

print("Created comparisons:")
print(df.to_string(index=False))
print()
print("N comparisons:", len(df))
PY

  test -s comparisons.tsv
  """
}
