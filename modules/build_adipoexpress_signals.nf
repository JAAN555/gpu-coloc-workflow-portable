process BUILD_ADIPOEXPRESS_SIGNALS {
  tag { "chr${chrom}" }

  publishDir "${params.outdir}/01_eqtl_signals/chr${chrom}", mode: 'symlink'

  cpus 4
  time '12h'
  memory '64 GB'

  input:
    tuple val(dataset), val(chrom), val(eqtl_path)

  output:
    tuple val(dataset), val(chrom), path("eqtl_signals")

  script:
  """
  set -euo pipefail

  if [[ -f ${projectDir}/env.sh ]]; then
    source ${projectDir}/env.sh
  fi

  rm -rf eqtl_signals
  mkdir -p eqtl_signals

  python3 ${projectDir}/scripts/build_adipoexpress_eqtl_signals.py \\
    --input "${eqtl_path}" \\
    --dataset-name "${dataset}" \\
    --chrom "${chrom}" \\
    --outdir eqtl_signals \\
    --fasta "${params.reference_fasta}" \\
    --min-lbf "${params.eqtl_min_lbf}"

  test -s eqtl_signals/summary.tsv
  test -d eqtl_signals/signals
  """
}
