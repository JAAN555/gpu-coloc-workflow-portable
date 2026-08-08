# gpu-coloc-workflow-portable

A modular Nextflow DSL2 framework for preparing GWAS and eQTL datasets for gpu-coloc and performing large-scale Bayesian genetic colocalisation analyses using gpu-coloc on HPC systems.

This repository contains the computational framework developed as part of the Master's thesis *Development of a scalable automated computational framework for genetic colocalisation analysis* at the University of Tartu.

The framework consists of three computational workflows constructed from reusable Nextflow DSL2 modules:

- GWAS parquet preparation
- eQTL parquet preparation
- Large-scale colocalisation analysis

The framework also includes supporting software configuration and is intended for execution in a SLURM-managed HPC environment, such as such as the University of Tartu HPC Rocket cluster.

---

## Framework overview

The computational framework consists of three workflows constructed from reusable Nextflow DSL2 modules and supporting software configuration.

The GWAS and eQTL parquet preparation workflows transform compatible input datasets into gpu-coloc compatible parquet representations. These outputs can be used as input for the large-scale colocalisation analysis workflow or reused in future gpu-coloc analyses without repeating dataset preparation.

The large-scale colocalisation analysis workflow generates GWAS-eQTL dataset comparisons and executes gpu-coloc analyses. The resulting colocalisation outputs can be used for downstream exploration and biological interpretation.

![Overview of the framework and its supporting components](figures/framework_overview.png)

## Repository structure

| Path | Description |
|---|---|
| `configs/` | Nextflow execution configuration files. |
| `modules/` | Reusable Nextflow DSL2 modules used by the workflows. See [`modules/README.md`](modules/README.md) for module descriptions. |
| `params/` | Workflow parameter files. |
| `reproducibility/` | Software environment records used to support reproducibility. |
| `sbatch/` | SLURM scripts for workflow execution. |
| `scripts/` | Python scripts used by the workflows. |
| `gpu_coloc/` | gpu-coloc software used for Bayesian colocalisation analysis. |
| `main_prepare_astle_parquets_modular.nf` | GWAS parquet preparation workflow for Astle_2016. |
| `main_prepare_de_lange_parquets_modular.nf` | GWAS parquet preparation workflow for de_Lange_2017. |
| `main_prepare_adipoexpress_eqtl_parquets_modular.nf` | eQTL parquet preparation workflow for AdipoExpress. |
| `main_coloc_comparisons_modular.nf` | Large-scale colocalisation analysis workflow. |
| `environment.yml` | Conda environment specification. |
| `setup_gpucoloc.sh` | Script for creating or updating the Conda environment. |
| `env.sh` | Script for activating the Conda environment. |


---

## Workflows

The computational framework contains three workflows for dataset preparation and large-scale Bayesian genetic colocalisation analysis.

### GWAS parquet preparation workflow

Transforms compatible harmonised GWAS summary statistics into gpu-coloc compatible parquet representations.

The workflow consists of reusable modules for dataset discovery, signal generation, chromosome-level parquet generation, and final parquet assembly. Additional information about the modules is available in [`modules/README.md`](modules/README.md).

### eQTL parquet preparation workflow

Transforms compatible processed eQTL data into gpu-coloc compatible parquet representations.

The current implementation was developed for the AdipoExpress resource and consists of reusable modules for dataset discovery, signal construction, chromosome-level parquet generation, and final parquet assembly. Additional information about the modules is available in [`modules/README.md`](modules/README.md).

### Large-scale colocalisation analysis workflow

Automates Bayesian genetic colocalisation analyses using gpu-coloc compatible GWAS and eQTL parquet resources.

The workflow generates GWAS-eQTL dataset comparisons and executes gpu-coloc independently for each comparison. Additional information about the workflow modules is available in [`modules/README.md`](modules/README.md).

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

# Optional Conda environment name

By default, the setup creates and activates the Conda environment
`gpucoloc_nf`.

To use a different environment name, set `GPUCOLOC_ENV_NAME` before setup:

```bash
export GPUCOLOC_ENV_NAME=gpucoloc_nf_test
bash setup_gpucoloc.sh
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

## Running workflows

The provided SLURM submission scripts are located in `sbatch/`.

| Script | Purpose |
|---|---|
| `run_prepare_astle_36_fillminus1e6.sbatch` | Runs the GWAS parquet preparation workflow for Astle_2016. |
| `run_prepare_de_lange.sbatch` | Runs the GWAS parquet preparation workflow for de_Lange_2017. |
| `run_prepare_adipoexpress_eqtl.sbatch` | Runs the eQTL parquet preparation workflow for AdipoExpress. |
| `run_coloc_astle_m1e6_5x6.sbatch` | Runs the large-scale colocalisation analysis. |
| `run_coloc_astle_adipo_test.sbatch` | Runs a smaller Astle_2016–AdipoExpress colocalisation analysis. |

Run a workflow using:

```bash
sbatch sbatch/<script>.sbatch
```

For example, to run the GWAS parquet preparation workflow for Astle_2016, use the following command:

```bash
sbatch sbatch/run_prepare_astle_36_fillminus1e6.sbatch
```
---

# Reproducibility

The software environment used for the framework is specified in `environment.yml`.

The `reproducibility/` directory contains records of the software environment used for the final validated workflow execution:

- `software_versions.txt`
- `conda_packages.txt`
- `pip_packages.txt`

These files document the software versions used during development and validation of the framework.

---

## HPC environment

The framework was developed and tested on the University of Tartu Rocket HPC cluster.

The setup scripts use the HPC Conda module to create and activate the software environment:

```bash
module load any/python/3.8.3-conda
```
On other systems, users must have Conda or Miniconda installed and may
need to replace the HPC-specific `module load` command in
`setup_gpucoloc.sh` and `env.sh`.

---

# Notes

- The initial Conda environment creation may take several minutes.
- Input GWAS and eQTL datasets are not included in this repository.
- Dataset locations should be configured through the parameter files.
- The provided execution configurations and submission scripts target a
SLURM-managed HPC environment.
