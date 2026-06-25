#!/bin/bash -euo pipefail
set -euo pipefail

python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/scripts/discover_gwas_gwascatalog.py \
  --root "/gpfs/space/projects/genomic_references/summary_stats" \
  --pattern "GWASCatalog/Astle_2016/**/harmonised/*.h.tsv.gz" \
  --limit "36" \
  --out gwas_paths.tsv

test -s gwas_paths.tsv
