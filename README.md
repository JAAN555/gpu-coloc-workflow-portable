# gpu-coloc-workflow-portable

## First-time setup

Clone the repository and create the conda environment:

```bash
git clone https://github.com/JAAN555/gpu-coloc-workflow-portable.git
cd gpu-coloc-workflow-portable

bash setup_gpucoloc.sh
source env.sh
```

## Subsequent sessions

If the environment has already been created, only activate it:

```bash
cd gpu-coloc-workflow-portable
source env.sh
```

## Workflow configuration

Before running the workflows, review the parameter files in the `params/` directory.

In particular, users will typically need to update:

- `gwas_roots`
- `eqtl_roots`
- `outdir`

to match the locations of their GWAS and eQTL parquet datasets.

Configuration files located in the `configs/` directory can also be modified if different workflow settings are required.

### Example parameter modification

```yaml
gwas_roots: "Astle_2016=/path/to/gwas_parquets"
eqtl_roots: "exon=/path/to/exon_parquets|gene=/path/to/gene_parquets"
```

Replace `/path/to/...` with the actual dataset locations on your system before running the workflow.

## Running the Astle parquet preparation workflow

```bash
sbatch sbatch/run_prepare_astle_36_fillminus1e6.sbatch
```

## Running the gpu-coloc comparison workflow

```bash
sbatch sbatch/run_coloc_astle_m1e6_1x2.sbatch
```

## Notes


- The first-time setup may take several minutes because Conda must download and install all required software packages.
- Subsequent sessions only require running `source env.sh` and are significantly faster.
- Users may need to update dataset paths in the parameter files before running the workflows.
- This workflow is intended to be run on the University HPC environment. The setup script assumes that Conda is available through the HPC module system using `module load any/python/3.8.3-conda`. Users running the workflow on another system may need to install Conda manually or modify `setup_gpucoloc.sh` and `env.sh` according to their local environment.
- PyTorch is pinned to 2.5.1 because newer default PyPI builds may not support the Tesla V100 GPUs used on the HPC cluster.
