#!/bin/bash -euo pipefail
set -euo pipefail

python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/scripts/discover_adipoexpress.py \
  --root "/gpfs/space/projects/genomic_references/summary_stats/AdipoExpress/labfs" \
  --pattern "EURonly_AB1_local_eQTL_meta_chr*.labf_variable.txt.gz" \
  --dataset-name "AdipoExpress" \
  --limit "0" \
  --out adipoexpress_paths.tsv

test -s adipoexpress_paths.tsv
