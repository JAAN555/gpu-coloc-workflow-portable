#!/bin/bash -euo pipefail
set -euo pipefail
source /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh

[[ -d "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/Suzuki_Aragam_parquets" ]] || { echo "ERROR: dir1 not found: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/Suzuki_Aragam_parquets" >&2; exit 2; }
[[ -d "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/leafcutter_parquets" ]] || { echo "ERROR: dir2 not found: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/leafcutter_parquets" >&2; exit 2; }

echo "comparison_id: Suzuki_Aragam_vs_leafcutter" > "Suzuki_Aragam_vs_leafcutter.log"
echo "gwas_name: Suzuki_Aragam" >> "Suzuki_Aragam_vs_leafcutter.log"
echo "eqtl_name: leafcutter" >> "Suzuki_Aragam_vs_leafcutter.log"
echo "dir1: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/Suzuki_Aragam_parquets" >> "Suzuki_Aragam_vs_leafcutter.log"
echo "dir2: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/leafcutter_parquets" >> "Suzuki_Aragam_vs_leafcutter.log"
echo "p12: 1e-6" >> "Suzuki_Aragam_vs_leafcutter.log"
echo "H4: 0.8" >> "Suzuki_Aragam_vs_leafcutter.log"
echo "task_host: $(hostname)" >> "Suzuki_Aragam_vs_leafcutter.log"
echo "task_start: $(date)" >> "Suzuki_Aragam_vs_leafcutter.log"
echo "Matched chromosomes:" >> "Suzuki_Aragam_vs_leafcutter.log"

comm -12 \
  <(find -L "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/Suzuki_Aragam_parquets" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort) \
  <(find -L "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/leafcutter_parquets" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort) \
  >> "Suzuki_Aragam_vs_leafcutter.log" || true

/usr/bin/time -v python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/gpu_coloc/coloc.py \
  --dir1 "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/Suzuki_Aragam_parquets" \
  --dir2 "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/leafcutter_parquets" \
  --results "Suzuki_Aragam_vs_leafcutter.tsv" \
  --p12 "1e-6" \
  --H4 "0.8" \
  >> "Suzuki_Aragam_vs_leafcutter.log" 2> "Suzuki_Aragam_vs_leafcutter.time"

echo "task_end: $(date)" >> "Suzuki_Aragam_vs_leafcutter.log"

if [[ ! -s "Suzuki_Aragam_vs_leafcutter.tsv" ]]; then
  echo -e "PP.H3\tPP.H4\tsignal1\tlead1\tsignal2\tlead2" > "Suzuki_Aragam_vs_leafcutter.tsv"
fi

test -s "Suzuki_Aragam_vs_leafcutter.tsv"
test -s "Suzuki_Aragam_vs_leafcutter.log"
test -s "Suzuki_Aragam_vs_leafcutter.time"
