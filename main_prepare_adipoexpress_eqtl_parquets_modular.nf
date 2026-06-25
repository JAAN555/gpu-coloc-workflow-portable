nextflow.enable.dsl=2

params.outdir = params.containsKey('outdir') ? params.outdir : 'nf_out_prepare_adipoexpress_eqtl_parquets'
params.summary_stats_root = params.containsKey('summary_stats_root') ? params.summary_stats_root : '/gpfs/space/projects/genomic_references/summary_stats/AdipoExpress/labfs'

params.eqtl_dataset_name = params.containsKey('eqtl_dataset_name') ? params.eqtl_dataset_name : 'AdipoExpress'
params.eqtl_pattern = params.containsKey('eqtl_pattern') ? params.eqtl_pattern : 'EURonly_AB1_local_eQTL_meta_chr*.labf_variable.txt.gz'
params.eqtl_limit = (params.containsKey('eqtl_limit') ? params.eqtl_limit : 0) as Integer

params.reference_fasta = params.containsKey('reference_fasta') ? params.reference_fasta : '/gpfs/space/projects/genomic_references/annotations/hg38/hg38.fa'

params.eqtl_min_lbf = (params.containsKey('eqtl_min_lbf') ? params.eqtl_min_lbf : 5.0) as Double

params.coloc_group_merge_gap = (params.containsKey('coloc_group_merge_gap') ? params.coloc_group_merge_gap : 0) as Integer
params.max_signals_per_group = (params.containsKey('max_signals_per_group') ? params.max_signals_per_group : 20) as Integer

include { DISCOVER_ADIPOEXPRESS } from './modules/discover_adipoexpress'
include { BUILD_ADIPOEXPRESS_SIGNALS } from './modules/build_adipoexpress_signals'
include { BUILD_EQTL_GROUPED_PARQUET_CHR } from './modules/build_eqtl_grouped_parquet_chr'
include { ASSEMBLE_EQTL_GROUPED_ROOT } from './modules/assemble_eqtl_grouped_root'

workflow {
  eqtl_paths = DISCOVER_ADIPOEXPRESS()

  rows = eqtl_paths
    .splitCsv(header:true, sep:'\t')
    .map { row ->
      tuple(row.dataset as String, row.chrom as String, row.path as String)
    }

  eqtl_signals = BUILD_ADIPOEXPRESS_SIGNALS(rows)

  eqtl_items = eqtl_signals
    .map { dataset, chrom, dir -> "${dataset}_chr${chrom}=${dir.toAbsolutePath()}" }
    .collect()

  chroms = Channel.from((1..22).collect { it.toString() } + ['X'])

  grouped_chr = BUILD_EQTL_GROUPED_PARQUET_CHR(chroms, eqtl_items)

  chr_dirs = grouped_chr
    .map { chrom, dir -> dir }
    .collect()

  ASSEMBLE_EQTL_GROUPED_ROOT(chr_dirs)
}
