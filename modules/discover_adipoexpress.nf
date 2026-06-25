process DISCOVER_ADIPOEXPRESS {
  tag { params.eqtl_dataset_name }

  publishDir "${params.outdir}/00_discovery", mode: 'copy'

  cpus 1
  time '30m'
  memory '2 GB'

  output:
    path("adipoexpress_paths.tsv")

  script:
  """
  set -euo pipefail

  python3 ${projectDir}/scripts/discover_adipoexpress.py \\
    --root "${params.summary_stats_root}" \\
    --pattern "${params.eqtl_pattern}" \\
    --dataset-name "${params.eqtl_dataset_name}" \\
    --limit "${params.eqtl_limit}" \\
    --out adipoexpress_paths.tsv

  test -s adipoexpress_paths.tsv
  """
}
