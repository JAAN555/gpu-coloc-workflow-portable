process RUN_GPU_COLOC_COMPARISON {
  tag { comparison_id }
  publishDir "${params.outdir}/01_results/${comparison_id}", mode: 'copy'
  cpus 4
  time '48h'
  memory '40 GB'
  queue 'gpu'
  clusterOptions '--gres=gpu:1'

  input:
    tuple val(comparison_id), val(gwas_name), val(eqtl_name), val(dir1), val(dir2), val(p12), val(H4)

  output:
    tuple val(comparison_id), path("${comparison_id}.tsv"), path("${comparison_id}.log"), path("${comparison_id}.time")

  script:
  """
  set -euo pipefail
  source ${projectDir}/env.sh

  [[ -d "${dir1}" ]] || { echo "ERROR: dir1 not found: ${dir1}" >&2; exit 2; }
  [[ -d "${dir2}" ]] || { echo "ERROR: dir2 not found: ${dir2}" >&2; exit 2; }

  echo "comparison_id: ${comparison_id}" > "${comparison_id}.log"
  echo "gwas_name: ${gwas_name}" >> "${comparison_id}.log"
  echo "eqtl_name: ${eqtl_name}" >> "${comparison_id}.log"
  echo "dir1: ${dir1}" >> "${comparison_id}.log"
  echo "dir2: ${dir2}" >> "${comparison_id}.log"
  echo "p12: ${p12}" >> "${comparison_id}.log"
  echo "H4: ${H4}" >> "${comparison_id}.log"
  echo "task_host: \$(hostname)" >> "${comparison_id}.log"
  echo "task_start: \$(date)" >> "${comparison_id}.log"
  echo "Matched chromosomes:" >> "${comparison_id}.log"

  comm -12 \\
    <(find -L "${dir1}" -maxdepth 1 -mindepth 1 -type d -printf "%f\\n" | sort) \\
    <(find -L "${dir2}" -maxdepth 1 -mindepth 1 -type d -printf "%f\\n" | sort) \\
    >> "${comparison_id}.log" || true

  /usr/bin/time -v python3 ${projectDir}/gpu_coloc/coloc.py \\
    --dir1 "${dir1}" \\
    --dir2 "${dir2}" \\
    --results "${comparison_id}.tsv" \\
    --p12 "${p12}" \\
    --H4 "${H4}" \\
    >> "${comparison_id}.log" 2> "${comparison_id}.time"

  echo "task_end: \$(date)" >> "${comparison_id}.log"

  if [[ ! -s "${comparison_id}.tsv" ]]; then
    echo -e "PP.H3\\tPP.H4\\tsignal1\\tlead1\\tsignal2\\tlead2" > "${comparison_id}.tsv"
  fi

  test -s "${comparison_id}.tsv"
  test -s "${comparison_id}.log"
  test -s "${comparison_id}.time"
  """
}
