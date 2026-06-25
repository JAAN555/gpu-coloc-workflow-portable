#!/bin/bash -euo pipefail
set -euo pipefail

if [[ -f /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh ]]; then
  source /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh
fi

rm -rf gwas_signals
mkdir -p gwas_signals

python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/scripts/build_gwas_signals.py \
  --gwas "/gpfs/space/projects/genomic_references/summary_stats/GWASCatalog/Astle_2016/AstleWJ_27863252_GCST004615/harmonised/27863252-GCST004615-EFO_0004509.h.tsv.gz" \
  --trait "Astle_2016_AstleWJ_27863252_GCST004615" \
  --outdir gwas_signals \
  --window "1000000" \
  --lead-p "5.0E-8" \
  --min-lbf "5.0" \
  --effect-prior "0.2" \
  --chunksize "500000" \


test -s gwas_signals/summary.tsv
test -d gwas_signals/signals
