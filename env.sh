#!/usr/bin/env bash

if command -v module >/dev/null 2>&1; then
    module load any/python/3.8.3-conda
fi

if ! command -v conda >/dev/null 2>&1; then
    echo "ERROR: Conda is not available." >&2
    echo "Install Conda/Miniconda or load the appropriate HPC module." >&2
    return 1
fi

source "$(conda info --base)/etc/profile.d/conda.sh"


ENV_NAME="${GPUCOLOC_ENV_NAME:-gpucoloc_nf}"
conda activate "$ENV_NAME"


export PATH="$CONDA_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"
