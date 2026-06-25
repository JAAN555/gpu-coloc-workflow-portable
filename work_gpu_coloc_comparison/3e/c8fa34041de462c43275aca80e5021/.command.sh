#!/bin/bash -euo pipefail
set -euo pipefail
source /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh

[[ -d "/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_astle_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped" ]] || { echo "ERROR: dir1 not found: /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_astle_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped" >&2; exit 2; }
[[ -d "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/exon_parquets" ]] || { echo "ERROR: dir2 not found: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/exon_parquets" >&2; exit 2; }

echo "comparison_id: Astle_2016_m1e6_vs_exon" > "Astle_2016_m1e6_vs_exon.log"
echo "gwas_name: Astle_2016_m1e6" >> "Astle_2016_m1e6_vs_exon.log"
echo "eqtl_name: exon" >> "Astle_2016_m1e6_vs_exon.log"
echo "dir1: /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_astle_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped" >> "Astle_2016_m1e6_vs_exon.log"
echo "dir2: /gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/exon_parquets" >> "Astle_2016_m1e6_vs_exon.log"
echo "p12: 1e-6" >> "Astle_2016_m1e6_vs_exon.log"
echo "H4: 0.8" >> "Astle_2016_m1e6_vs_exon.log"
echo "task_host: $(hostname)" >> "Astle_2016_m1e6_vs_exon.log"
echo "task_start: $(date)" >> "Astle_2016_m1e6_vs_exon.log"
echo "Matched chromosomes:" >> "Astle_2016_m1e6_vs_exon.log"

comm -12 \
  <(find -L "/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_astle_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort) \
  <(find -L "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/exon_parquets" -maxdepth 1 -mindepth 1 -type d -printf "%f\n" | sort) \
  >> "Astle_2016_m1e6_vs_exon.log" || true

/usr/bin/time -v python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/gpu_coloc/coloc.py \
  --dir1 "/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/nf_out_prepare_astle_parquets_modular_36_fillminus1e6/03_gwas_grouped_root/gwas_grouped" \
  --dir2 "/gpfs/helios/projects/shared_gwas/gpu-coloc_resources/eQTL_Catalogue/exon_parquets" \
  --results "Astle_2016_m1e6_vs_exon.tsv" \
  --p12 "1e-6" \
  --H4 "0.8" \
  >> "Astle_2016_m1e6_vs_exon.log" 2> "Astle_2016_m1e6_vs_exon.time"

echo "task_end: $(date)" >> "Astle_2016_m1e6_vs_exon.log"

if [[ ! -s "Astle_2016_m1e6_vs_exon.tsv" ]]; then
  echo -e "PP.H3\tPP.H4\tsignal1\tlead1\tsignal2\tlead2" > "Astle_2016_m1e6_vs_exon.tsv"
fi

test -s "Astle_2016_m1e6_vs_exon.tsv"
test -s "Astle_2016_m1e6_vs_exon.log"
test -s "Astle_2016_m1e6_vs_exon.time"
