process MERGE_COUNTS {
    tag "${cohort}"
    label 'process_low'

    input:
    tuple val(cohort), path(count_files)

    output:
    tuple val(cohort), path("${cohort}_counts.tsv")

    script:
    """
    echo -e "SampleID\tHet_Count" > ${cohort}_counts.tsv
    cat ${count_files} >> ${cohort}_counts.tsv
    echo "[merge_counts] ${cohort}: \$(tail -n+2 ${cohort}_counts.tsv | wc -l) samples"
    """
}
