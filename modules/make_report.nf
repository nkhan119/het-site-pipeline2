process MAKE_REPORT {
    tag "${cohort}"
    label 'process_medium'
    publishDir "${params.results_dir}/${cohort}", mode: 'copy'

    input:
    tuple val(cohort), path(counts_tsv), path(metadata_tsv)

    output:
    tuple val(cohort), path("${cohort}_final.parquet"), emit: parquet
    tuple val(cohort), path("${cohort}_Report.pdf"),    emit: pdf

    script:
    """
    make_report.py \\
        --cohort    ${cohort} \\
        --counts    ${counts_tsv} \\
        --metadata  ${metadata_tsv} \\
        --min-dp    ${params.min_dp} \\
        --min-gq    ${params.min_gq} \\
        --out-parquet ${cohort}_final.parquet \\
        --out-pdf     ${cohort}_Report.pdf
    """
}
