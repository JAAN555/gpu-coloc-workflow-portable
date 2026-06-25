#!/bin/bash -euo pipefail
set -euo pipefail

if [[ -f /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh ]]; then
  source /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh
fi

rm -rf gwas_signals
mkdir -p gwas_signals

python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/scripts/build_gwas_signals.py \
  --gwas "/gpfs/space/projects/genomic_references/summary_stats/GWASCatalog/de_Lange_2017/28067908-GCST004132-EFO_0000384.h.tsv.gz" \
  --trait "de_Lange_2017_28067908-GCST004132-EFO_0000384" \
  --outdir gwas_signals \
  --window "1000000" \
  --lead-p "5.0E-8" \
  --min-lbf "5.0" \
  --effect-prior "0.2" \
  --chunksize "500000" \


test -s gwas_signals/summary.tsv
test -d gwas_signals/signals
