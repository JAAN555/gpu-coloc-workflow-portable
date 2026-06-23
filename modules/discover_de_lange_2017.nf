process DISCOVER_DE_LANGE_2017 {
  tag { "de_Lange_2017" }

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
    --pattern "GWASCatalog/de_Lange_2017/*.h.tsv.gz" \\
    --out gwas_paths.tsv

  test -s gwas_paths.tsv
  """
}
