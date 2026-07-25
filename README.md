# gpu-coloc-workflow-portable

A modular Nextflow DSL2 framework for preparing GWAS and eQTL datasets for gpu-coloc and performing large-scale Bayesian genetic colocalisation analyses on HPC systems.

The framework consists of three main workflows:

- GWAS parquet preparation
- eQTL parquet preparation
- Large-scale gpu-coloc analysis

The workflows are implemented using reusable Nextflow DSL2 modules and are intended for execution on a SLURM-managed HPC environment.

---

# Repository structure

```
configs/            Nextflow execution configuration files
modules/            Reusable Nextflow DSL2 modules
params/             Workflow parameter files
reproducibility/    Software environment records
sbatch/             SLURM submission scripts
scripts/            Supporting Python scripts
```

---

# First-time setup

Clone the repository and create the Conda environment.

```bash
git clone https://github.com/JAAN555/gpu-coloc-workflow-portable.git
cd gpu-coloc-workflow-portable

bash setup_gpucoloc.sh
source env.sh
```

---

# Subsequent sessions

Activate the existing Conda environment.

```bash
cd gpu-coloc-workflow-portable
source env.sh
```

---

# Workflow configuration

Workflow parameters are stored in the `params/` directory.

Execution settings are stored in the `configs/` directory.

Before running a workflow, update the parameter file for your analysis. Commonly modified parameters include:

- input dataset locations
- output directory
- dataset names
- filename patterns
- workflow-specific analysis parameters

Example:

```yaml
gwas_roots: "Astle_2016=/path/to/gwas_parquets"
eqtl_roots: "exon=/path/to/eqtl_parquets"
outdir: "/path/to/output"
```

---

# Running workflows

SLURM submission scripts are located in the `sbatch/` directory.

Run the desired workflow using:

```bash
sbatch sbatch/<script>.sbatch
```


# Reproducibility

The software environment used for the framework is specified in `environment.yml`.

The `reproducibility/` directory contains records of the software environment used for the final validated workflow execution:

- `software_versions.txt`
- `conda_packages.txt`
- `pip_packages.txt`

These files document the software versions used during development and validation of the framework.

---

# HPC environment

The framework was developed on the University of Tartu Rocket HPC cluster.

The helper scripts currently assume:

```bash
module load any/python/3.8.3-conda
module load nextflow/25.10.2
```

Users running the framework on another system may need to modify `setup_gpucoloc.sh` and `env.sh` according to their local software environment.

---

# Notes

- The initial Conda environment creation may take several minutes.
- Input GWAS and eQTL datasets are not included in this repository.
- Dataset locations should be configured through the parameter files.
- The workflows assume execution in a SLURM-managed HPC environment.
