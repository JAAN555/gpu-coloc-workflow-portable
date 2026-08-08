# Workflow modules

This directory contains the reusable Nextflow DSL2 modules used by the computational workflows.

## GWAS parquet preparation

| Module | Description |
|---|---|
| `DISCOVER_GWAS_GWASCATALOG` | Finds compatible GWAS input datasets and creates a dataset manifest. |
| `BUILD_GWAS_SIGNALS` | Generates GWAS association signals and corresponding signal matrices. |
| `BUILD_GWAS_GROUPED_PARQUET_CHR` | Groups GWAS signals and creates chromosome-level parquet files. |
| `ASSEMBLE_GWAS_GROUPED_ROOT` | Assembles chromosome-level parquet files into the final GWAS parquet root. |

The same modules are used for both Astle_2016 and de_Lange_2017. Dataset-specific settings are provided through workflow parameters.

## eQTL parquet preparation

| Module | Description |
|---|---|
| `DISCOVER_ADIPOEXPRESS` | Finds chromosome-specific AdipoExpress input files and creates a dataset manifest. |
| `BUILD_ADIPOEXPRESS_SIGNALS` | Generates eQTL signals and corresponding signal matrices from processed AdipoExpress data. |
| `BUILD_EQTL_GROUPED_PARQUET_CHR` | Groups eQTL signals and creates chromosome-level parquet files. |
| `ASSEMBLE_EQTL_GROUPED_ROOT` | Assembles chromosome-level parquet files into the final eQTL parquet root. |

## Large-scale colocalisation analysis

| Module | Description |
|---|---|
| `CREATE_COMPARISONS_TSV` | Generates GWAS-eQTL dataset comparisons from the configured parquet resources. |
| `RUN_GPU_COLOC_COMPARISON` | Executes gpu-coloc independently for each GWAS-eQTL dataset comparison. |
