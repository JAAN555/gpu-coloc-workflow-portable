nextflow.enable.dsl=2

params.outdir = params.containsKey('outdir') ? params.outdir : 'nf_out_coloc_comparisons_modular'

params.gwas_roots = params.containsKey('gwas_roots') ? params.gwas_roots : ''
params.eqtl_roots = params.containsKey('eqtl_roots') ? params.eqtl_roots : ''

params.p12 = params.containsKey('p12') ? params.p12 : '1e-6'
params.H4 = params.containsKey('H4') ? params.H4 : '0.8'

include { CREATE_COMPARISONS_TSV } from './modules/create_comparisons_tsv'
include { RUN_GPU_COLOC_COMPARISON } from './modules/run_gpu_coloc_comparison'

workflow {
  comparisons_file = CREATE_COMPARISONS_TSV()

  comparisons = comparisons_file
    .splitCsv(header:true, sep:'\t')
    .map { row ->
      tuple(
        row.comparison_id as String,
        row.gwas_name as String,
        row.eqtl_name as String,
        row.dir1 as String,
        row.dir2 as String,
        row.p12 as String,
        row.H4 as String
      )
    }

  RUN_GPU_COLOC_COMPARISON(comparisons)
}
