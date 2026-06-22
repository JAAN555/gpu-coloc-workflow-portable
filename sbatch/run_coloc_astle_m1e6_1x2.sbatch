#!/bin/bash
#SBATCH --job-name=coloc_astle_m1e6
#SBATCH --partition=main
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=24:00:00
#SBATCH --output=nf_coloc_astle_m1e6.%j.out
#SBATCH --error=nf_coloc_astle_m1e6.%j.err

set -euo pipefail

cd ~/gpu-coloc

module load any/python/3.8.3-conda
module load openjdk/17.0.3_7

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate gpucoloc_nf

export PATH="$HOME/.conda/envs/gpucoloc_nf/bin:$PATH"
export LD_LIBRARY_PATH="$HOME/.conda/envs/gpucoloc_nf/lib:${LD_LIBRARY_PATH:-}"

export NXF_ANSI_LOG=false
export NXF_OPTS="-Xms1g -Xmx4g"

NF="main_coloc_comparisons_modular.nf"
CFG="configs/coloc_comparisons_modular.config"
YML="params/params_coloc_comparisons_astle_m1e6_1x2.yml"

START_EPOCH=$(date +%s)

echo "======================================="
echo "Running Astle -1e6 parquet gpu-coloc validation"
echo "======================================="
echo "PWD        : $(pwd)"
echo "NF         : $NF"
echo "CFG        : $CFG"
echo "YML        : $YML"
echo "JOB        : ${SLURM_JOB_ID:-NA}"
echo "HOST       : $(hostname)"
echo "START      : $(date)"
echo "START_EPOCH: ${START_EPOCH}"
echo "======================================="

"$HOME/nextflow" run "$NF" \
  -c "$CFG" \
  -params-file "$YML" \
  -resume

END_EPOCH=$(date +%s)
DURATION=$((END_EPOCH - START_EPOCH))

echo "======================================="
echo "END        : $(date)"
echo "END_EPOCH  : ${END_EPOCH}"
echo "DURATION_S : ${DURATION}"
echo "DURATION_H : $(python3 - <<PY
print(round(${DURATION}/3600, 3))
PY
)"
echo "Pipeline finished"
echo "======================================="

sacct -j "${SLURM_JOB_ID}" --format=JobID,JobName,Partition,State,Elapsed,AllocCPUS,ReqMem,MaxRSS,CPUTimeRaw,NodeList -P || true
