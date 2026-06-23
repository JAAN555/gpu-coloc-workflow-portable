process BUILD_GWAS_GROUPED_PARQUET_CHR {
  tag { "chr${chrom}" }
  publishDir "${params.outdir}/02_gwas_grouped_chr", mode: 'symlink'

  cpus 2
  time '6h'
  memory '32 GB'

  input:
    val chrom
    val gwas_items

  output:
    tuple val(chrom), path("chr_${chrom}")

  script:
  """
  set -euo pipefail

  if [[ -f ${projectDir}/env.sh ]]; then
    source ${projectDir}/env.sh
  fi

  rm -rf "chr_${chrom}"
  mkdir -p "chr_${chrom}"

  python3 ${projectDir}/scripts/build_gwas_grouped_parquet_chr.py \\
    --chrom "${chrom}" \\
    --gwas-items "${gwas_items.join('|||')}" \\
    --merge-gap "${params.coloc_group_merge_gap}" \\
    --max-signals-per-group "${params.max_signals_per_group}" \\
    --outdir "chr_${chrom}"

  test -d "chr_${chrom}"
  """
}
