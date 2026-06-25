#!/bin/bash -euo pipefail
set -euo pipefail
source /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh

[[ -d "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/FinnGen_lbf_parquets" ]] || { echo "ERROR: dir1 not found: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/FinnGen_lbf_parquets" >&2; exit 2; }
[[ -d "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets" ]] || { echo "ERROR: dir2 not found: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets" >&2; exit 2; }

echo "comparison_id: FinnGen_vs_txrev" > "FinnGen_vs_txrev.log"
echo "gwas_name: FinnGen" >> "FinnGen_vs_txrev.log"
echo "eqtl_name: txrev" >> "FinnGen_vs_txrev.log"
echo "dir1: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/FinnGen_lbf_parquets" >> "FinnGen_vs_txrev.log"
echo "dir2: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets" >> "FinnGen_vs_txrev.log"
echo "p12: 1e-6" >> "FinnGen_vs_txrev.log"
echo "H4: 0.8" >> "FinnGen_vs_txrev.log"
echo "task_host: $(hostname)" >> "FinnGen_vs_txrev.log"
echo "task_start: $(date)" >> "FinnGen_vs_txrev.log"
echo "Matched chromosomes:" >> "FinnGen_vs_txrev.log"

comm -12 \
  <(find -L "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/FinnGen_lbf_parquets" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort) \
  <(find -L "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort) \
  >> "FinnGen_vs_txrev.log" || true

/usr/bin/time -v python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/gpu_coloc/coloc.py \
  --dir1 "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/FinnGen_lbf_parquets" \
  --dir2 "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets" \
  --results "FinnGen_vs_txrev.tsv" \
  --p12 "1e-6" \
  --H4 "0.8" \
  >> "FinnGen_vs_txrev.log" 2> "FinnGen_vs_txrev.time"

echo "task_end: $(date)" >> "FinnGen_vs_txrev.log"

if [[ ! -s "FinnGen_vs_txrev.tsv" ]]; then
  echo -e "PP.H3\tPP.H4\tsignal1\tlead1\tsignal2\tlead2" > "FinnGen_vs_txrev.tsv"
fi

test -s "FinnGen_vs_txrev.tsv"
test -s "FinnGen_vs_txrev.log"
test -s "FinnGen_vs_txrev.time"
