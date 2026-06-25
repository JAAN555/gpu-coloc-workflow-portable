#!/bin/bash -euo pipefail
set -euo pipefail

python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/scripts/discover_gwas_gwascatalog.py \
  --root "/gpfs/space/projects/genomic_references/summary_stats" \
  --pattern "GWASCatalog/de_Lange_2017/*.h.tsv.gz" \
  --limit "3" \
  --out gwas_paths.tsv

test -s gwas_paths.tsv
