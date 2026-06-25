#!/bin/bash -euo pipefail
set -euo pipefail

if [[ -f /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh ]]; then
  source /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/env.sh
fi

rm -rf "chr_19"
mkdir -p "chr_19"

python3 /gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/scripts/build_gwas_grouped_parquet_chr.py \
  --chrom "19" \
  --gwas-items "de_Lange_2017_28067908-GCST004133-EFO_0000729=/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/work_de_lange_m1e6/10/883ffe9bbd1ac5378c25ee0b605749/gwas_signals|||de_Lange_2017_28067908-GCST004132-EFO_0000384=/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/work_de_lange_m1e6/9c/5243c430283c7db8970b73a03a1097/gwas_signals|||de_Lange_2017_28067908-GCST004131-EFO_0003767=/gpfs/helios/home/jaanotte/gpu-coloc-workflow-portable/work_de_lange_m1e6/d9/f8b29e97a572d0660bd3a012b45eaf/gwas_signals" \
  --merge-gap "0" \
  --max-signals-per-group "20" \
  --outdir "chr_19"

test -d "chr_19"
