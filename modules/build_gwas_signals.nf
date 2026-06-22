process BUILD_GWAS_SIGNALS {
  tag { gwas_id }
  publishDir "${params.outdir}/01_gwas_signals/${gwas_id}", mode: 'symlink'
  cpus 2
  time '12h'
  memory '24 GB'

  input:
    tuple val(gwas_id), val(gwas_path)

  output:
    tuple val(gwas_id), path("gwas_signals")

  script:
  """
  set -euo pipefail

  if [[ -f ${projectDir}/env.sh ]]; then
    source ${projectDir}/env.sh
  fi

  rm -rf gwas_signals
  mkdir -p gwas_signals

  python3 ${projectDir}/scripts/build_gwas_signals.py \\
    --gwas "${gwas_path}" \\
    --trait "${gwas_id}" \\
    --outdir gwas_signals \\
    --window "${params.gwas_window}" \\
    --lead-p "${params.gwas_lead_p}" \\
    --min-lbf "${params.gwas_min_lbf}" \\
    --effect-prior "${params.gwas_effect_prior}" \\
    --chunksize "${params.gwas_chunksize}" \\
    ${params.gwas_chr ? "--gwas-chr ${params.gwas_chr}" : ""}

  test -s gwas_signals/summary.tsv
  test -d gwas_signals/signals
  """
}
