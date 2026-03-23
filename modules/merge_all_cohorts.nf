process MERGE_ALL_COHORTS {
    label 'process_medium'
    publishDir "${params.results_dir}", mode: 'copy'

    input:
    path parquets

    output:
    path "all_cohorts_merged.parquet"

    script:
    """
    merge_all_cohorts.py \\
        --input   ${parquets} \\
        --output  all_cohorts_merged.parquet
    """
}
