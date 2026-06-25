#!/bin/bash -euo pipefail
set -euo pipefail

if [[ -f /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh ]]; then
  source /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh
fi

rm -rf eqtl_signals
mkdir -p eqtl_signals

python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/scripts/build_adipoexpress_eqtl_signals.py \
  --input "/gpfs/space/projects/genomic_references/summary_stats/AdipoExpress/labfs/EURonly_AB1_local_eQTL_meta_chr1.labf_variable.txt.gz" \
  --dataset-name "AdipoExpress" \
  --chrom "1" \
  --outdir eqtl_signals \
  --fasta "/gpfs/space/projects/genomic_references/annotations/hg38/hg38.fa" \
  --min-lbf "5.0"

test -s eqtl_signals/summary.tsv
test -d eqtl_signals/signals
