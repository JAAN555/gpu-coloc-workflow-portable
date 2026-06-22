process ASSEMBLE_GWAS_GROUPED_ROOT {
  publishDir "${params.outdir}/03_gwas_grouped_root", mode: 'copy'
  cpus 1
  time '30m'
  memory '4 GB'

  input:
    path(chr_dirs)

  output:
    path("gwas_grouped")
    path("grouped_file_count.txt")

  script:
  """
  set -euo pipefail

  rm -rf gwas_grouped
  mkdir -p gwas_grouped

  for d in ${chr_dirs}; do
    [[ -d "\$d" ]] || continue

    for chr_sub in "\$d"/*; do
      [[ -d "\$chr_sub" ]] || continue

      chr=\$(basename "\$chr_sub")
      mkdir -p "gwas_grouped/\$chr"

      for f in "\$chr_sub"/*.parquet; do
        [[ -f "\$f" ]] || continue
        ln -s "\$(realpath "\$f")" "gwas_grouped/\$chr/\$(basename "\$f")"
      done
    done
  done

  find gwas_grouped -name "*.parquet" | wc -l > grouped_file_count.txt

  echo "Grouped parquet count:"
  cat grouped_file_count.txt

  test -d gwas_grouped
  """
}
