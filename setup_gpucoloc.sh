#!/usr/bin/env bash
set -euo pipefail

ENV_NAME="gpucoloc_nf"

module load any/python/3.8.3-conda || true
module load nextflow/25.10.2 || module load nextflow || true

source "$(conda info --base)/etc/profile.d/conda.sh"

if conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
    echo "Conda environment '$ENV_NAME' already exists. Updating..."
    conda env update -n "$ENV_NAME" -f environment.yml --prune
else
    echo "Creating conda environment '$ENV_NAME'..."
    conda env create -n "$ENV_NAME" -f environment.yml
fi

conda activate "$ENV_NAME"

echo "=== Environment check ==="
echo "Python: $(which python)"
python --version
python - <<'PY'
import pandas
import numpy
import pyarrow
import tqdm
import torch
import pysam
print("Python package check OK")
print("torch:", torch.__version__)
PY

echo "Java:"
java -version

echo "Nextflow:"
if command -v nextflow >/dev/null 2>&1; then
    nextflow -version
elif [ -x "$HOME/nextflow" ]; then
    "$HOME/nextflow" -version
else
    echo "WARNING: Nextflow not found. Install Nextflow separately or place it on PATH."
fi

echo "Setup complete."
