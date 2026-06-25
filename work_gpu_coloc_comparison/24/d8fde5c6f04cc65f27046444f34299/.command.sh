#!/bin/bash -euo pipefail
set -euo pipefail
source /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh

[[ -d "/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_de_lange_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped" ]] || { echo "ERROR: dir1 not found: /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_de_lange_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped" >&2; exit 2; }
[[ -d "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets" ]] || { echo "ERROR: dir2 not found: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets" >&2; exit 2; }

echo "comparison_id: de_Lange_2017_m1e6_vs_txrev" > "de_Lange_2017_m1e6_vs_txrev.log"
echo "gwas_name: de_Lange_2017_m1e6" >> "de_Lange_2017_m1e6_vs_txrev.log"
echo "eqtl_name: txrev" >> "de_Lange_2017_m1e6_vs_txrev.log"
echo "dir1: /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_de_lange_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped" >> "de_Lange_2017_m1e6_vs_txrev.log"
echo "dir2: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets" >> "de_Lange_2017_m1e6_vs_txrev.log"
echo "p12: 1e-6" >> "de_Lange_2017_m1e6_vs_txrev.log"
echo "H4: 0.8" >> "de_Lange_2017_m1e6_vs_txrev.log"
echo "task_host: $(hostname)" >> "de_Lange_2017_m1e6_vs_txrev.log"
echo "task_start: $(date)" >> "de_Lange_2017_m1e6_vs_txrev.log"
echo "Matched chromosomes:" >> "de_Lange_2017_m1e6_vs_txrev.log"

comm -12 \
  <(find -L "/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_de_lange_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort) \
  <(find -L "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort) \
  >> "de_Lange_2017_m1e6_vs_txrev.log" || true

/usr/bin/time -v python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/gpu_coloc/coloc.py \
  --dir1 "/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_de_lange_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped" \
  --dir2 "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/txrev_parquets" \
  --results "de_Lange_2017_m1e6_vs_txrev.tsv" \
  --p12 "1e-6" \
  --H4 "0.8" \
  >> "de_Lange_2017_m1e6_vs_txrev.log" 2> "de_Lange_2017_m1e6_vs_txrev.time"

echo "task_end: $(date)" >> "de_Lange_2017_m1e6_vs_txrev.log"

if [[ ! -s "de_Lange_2017_m1e6_vs_txrev.tsv" ]]; then
  echo -e "PP.H3\tPP.H4\tsignal1\tlead1\tsignal2\tlead2" > "de_Lange_2017_m1e6_vs_txrev.tsv"
fi

test -s "de_Lange_2017_m1e6_vs_txrev.tsv"
test -s "de_Lange_2017_m1e6_vs_txrev.log"
test -s "de_Lange_2017_m1e6_vs_txrev.time"
