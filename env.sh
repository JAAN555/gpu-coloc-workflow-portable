#!/usr/bin/env bash

module load any/python/3.8.3-conda || true

source "$(conda info --base)/etc/profile.d/conda.sh"
conda activate gpucoloc_nf

export PATH="$CONDA_PREFIX/bin:$PATH"
export LD_LIBRARY_PATH="$CONDA_PREFIX/lib:${LD_LIBRARY_PATH:-}"
