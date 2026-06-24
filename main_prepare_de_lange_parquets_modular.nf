nextflow.enable.dsl=2

params.outdir = params.containsKey('outdir') ? params.outdir : 'nf_out_prepare_astle_parquets_modular'
params.summary_stats_root = params.containsKey('summary_stats_root') ? params.summary_stats_root : '/gpfs/space/projects/genomic_references/summary_stats'

params.gwas_limit = (params.containsKey('gwas_limit') ? params.gwas_limit : 3) as Integer
params.gwas_chr = params.containsKey('gwas_chr') ? params.gwas_chr : ''

params.gwas_window = (params.containsKey('gwas_window') ? params.gwas_window : 1000000) as Integer
params.gwas_chunksize = (params.containsKey('gwas_chunksize') ? params.gwas_chunksize : 500000) as Integer
params.gwas_min_lbf = (params.containsKey('gwas_min_lbf') ? params.gwas_min_lbf : 5.0) as Double
params.gwas_lead_p = (params.containsKey('gwas_lead_p') ? params.gwas_lead_p : 5e-8) as Double
params.gwas_effect_prior = (params.containsKey('gwas_effect_prior') ? params.gwas_effect_prior : 0.2) as Double

params.coloc_group_merge_gap = (params.containsKey('coloc_group_merge_gap') ? params.coloc_group_merge_gap : 0) as Integer
params.max_signals_per_group = (params.containsKey('max_signals_per_group') ? params.max_signals_per_group : 20) as Integer

include { DISCOVER_GWAS_GWASCATALOG } from './modules/discover_gwas_catalog'
include { BUILD_GWAS_SIGNALS } from './modules/build_gwas_signals'
include { BUILD_GWAS_GROUPED_PARQUET_CHR } from './modules/build_gwas_grouped_parquet_chr'
include { ASSEMBLE_GWAS_GROUPED_ROOT } from './modules/assemble_gwas_grouped_root'

workflow {
  gwas_paths = DISCOVER_GWAS_GWASCATALOG()

  rows = gwas_paths
    .splitCsv(header:true, sep:'\t')
    .map { row ->
      tuple(row.GWAS as String, row.GWAS_path as String)
    }

  gwas_signals = BUILD_GWAS_SIGNALS(rows)

  gwas_items = gwas_signals
    .map { id, dir -> "${id}=${dir.toAbsolutePath()}" }
    .collect()

  chroms = Channel.from((1..22).collect { it.toString() } + ['X'])

  grouped_chr = BUILD_GWAS_GROUPED_PARQUET_CHR(chroms, gwas_items)

  chr_dirs = grouped_chr
    .map { chrom, dir -> dir }
    .collect()

  ASSEMBLE_GWAS_GROUPED_ROOT(chr_dirs)
}
