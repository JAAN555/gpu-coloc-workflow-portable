#!/bin/bash
#SBATCH --job-name=coloc_adipo_test
#SBATCH --partition=main
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=12:00:00
#SBATCH --output=nf_coloc_adipo_test.%j.out
#SBATCH --error=nf_coloc_adipo_test.%j.err

set -euo pipefail

cd "${SLURM_SUBMIT_DIR:-$(pwd)}"

module load any/python/3.8.3-conda || true
module load nextflow/25.10.2 || module load nextflow || true
module load openjdk/17.0.3_7 || true

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate gpucoloc_nf

export PATH="$CONDA_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"

export NXF_ANSI_LOG=false
export NXF_OPTS="-Xms1g -Xmx4g"

NF="main_coloc_comparisons_modular.nf"
CFG="configs/coloc_comparisons_modular.config"
YML="params/params_coloc_comparisons_astle_adipo_test.yml"

if command -v nextflow >/dev/null 2>&1; then
    NEXTFLOW_CMD="nextflow"
elif [ -x "$HOME/nextflow" ]; then
    NEXTFLOW_CMD="$HOME/nextflow"
else
    echo "ERROR: Nextflow not found on PATH or at \$HOME/nextflow"
    exit 1
fi

START_EPOCH=$(date +%s)

echo "======================================="
echo "Running Astle vs AdipoExpress gpu-coloc test"
echo "======================================="
echo "PWD        : $(pwd)"
echo "NF         : $NF"
echo "CFG        : $CFG"
echo "YML        : $YML"
echo "NEXTFLOW   : $NEXTFLOW_CMD"
echo "JOB        : ${SLURM_JOB_ID:-NA}"
echo "HOST       : $(hostname)"
echo "START      : $(date)"
echo "CONDA_ENV  : ${CONDA_PREFIX:-NA}"
echo "======================================="

"$NEXTFLOW_CMD" run "$NF" \
  -c "$CFG" \
  -params-file "$YML" \
  -work-dir work_coloc_astle_adipo_test \
  -resume

END_EPOCH=$(date +%s)
DURATION=$((END_EPOCH - START_EPOCH))

echo "======================================="
echo "END        : $(date)"
echo "DURATION_S : ${DURATION}"
echo "DURATION_H : $(python - <<PY
print(round(${DURATION}/3600, 3))
PY
)"
echo "Pipeline finished"
echo "======================================="
