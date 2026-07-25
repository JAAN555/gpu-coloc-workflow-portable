#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="gpucoloc_nf"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/environment.yml"

if command -v module >/dev/null 2>&1; then
    module load any/python/3.8.3-conda
fi

if ! command -v conda >/dev/null 2>&1; then
    echo "ERROR: Conda is not available." >&2
    echo "Install Conda/Miniconda or load the appropriate HPC module." >&2
    exit 1
fi

source "$(conda info --base)/etc/profile.d/conda.sh"

if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo "Conda environment '$ENV_NAME' already exists. Updating..."
    conda env update \
        -n "$ENV_NAME" \
        -f "$ENV_FILE" \
        --prune
else
    echo "Creating conda environment '$ENV_NAME'..."
    conda env create \
        -n "$ENV_NAME" \
        -f "$ENV_FILE"
fi

conda activate "$ENV_NAME"

echo "=== Environment check ==="
echo "Python: $(which python)"
python --version

python - <<'PY'
import numpy
import pandas
import pyarrow
import pysam
import torch
import tqdm

print("Python package check OK")
print("torch:", torch.__version__)
PY

echo "Java:"
java -version

echo "Nextflow:"
nextflow -version

echo "Setup complete."
