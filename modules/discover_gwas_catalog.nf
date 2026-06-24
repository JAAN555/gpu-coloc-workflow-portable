process DISCOVER_GWAS_GWASCATALOG {
  tag { params.gwas_dataset_name }

  publishDir "${params.outdir}/00_discovery", mode: 'copy'

  cpus 1
  time '30m'
  memory '2 GB'

  output:
    path("gwas_paths.tsv")

  script:
  """
  set -euo pipefail

  python3 ${projectDir}/scripts/discover_gwas_gwascatalog.py \\
    --root "${params.summary_stats_root}" \\
    --pattern "${params.gwas_pattern}" \\
    --limit "${params.gwas_limit}" \\
    --out gwas_paths.tsv

  test -s gwas_paths.tsv
  """
}
