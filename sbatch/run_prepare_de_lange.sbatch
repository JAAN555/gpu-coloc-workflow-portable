#!/bin/bash
#SBATCH --job-name=prep_de_lange_m1e6
#SBATCH --partition=main
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=72:00:00
#SBATCH --output=nf_prep_de_lange_m1e6.%j.out
#SBATCH --error=nf_prep_de_lange_m1e6.%j.err

set -euo pipefail

# Run from the directory where sbatch was submitted
cd "${SLURM_SUBMIT_DIR:-$(pwd)}"

# Load cluster modules if available
module load any/python/3.8.3-conda || true
module load nextflow/25.10.2 || module load nextflow || true
module load openjdk/17.0.3_7 || true

# Activate conda environment
source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate gpucoloc_nf

# Prefer binaries and libraries from the active conda environment
export PATH="$CONDA_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"

export NXF_ANSI_LOG=false
export NXF_OPTS="-Xms1g -Xmx4g"

NF="main_prepare_de_lange_parquets_modular.nf"
CFG="configs/prepare_de_lange_parquets_modular.config"
YML="params/params_prepare_de_lange.yml"

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
echo "Running modular de Lange parquet preparation with missing variants = -1e6"
echo "======================================="
echo "PWD        : $(pwd)"
echo "NF         : $NF"
echo "CFG        : $CFG"
echo "YML        : $YML"
echo "NEXTFLOW   : $NEXTFLOW_CMD"
echo "JOB        : ${SLURM_JOB_ID:-NA}"
echo "HOST       : $(hostname)"
echo "START      : $(date)"
echo "START_EPOCH: ${START_EPOCH}"
echo "CONDA_ENV  : ${CONDA_PREFIX:-NA}"
echo "======================================="

"$NEXTFLOW_CMD" run "$NF" \
  -c "$CFG" \
  -params-file "$YML" \
  -resume

END_EPOCH=$(date +%s)
DURATION=$((END_EPOCH - START_EPOCH))

echo "======================================="
echo "END        : $(date)"
echo "END_EPOCH  : ${END_EPOCH}"
echo "DURATION_S : ${DURATION}"
echo "DURATION_H : $(python - <<PY
print(round(${DURATION}/3600, 3))
PY
)"
echo "Pipeline finished"
echo "======================================="

if command -v sacct >/dev/null 2>&1 && [ -n "${SLURM_JOB_ID:-}" ]; then
    sacct -j "${SLURM_JOB_ID}" --format=JobID,JobName,Partition,State,Elapsed,AllocCPUS,ReqMem,MaxRSS,CPUTimeRaw,NodeList -P || true
fi
