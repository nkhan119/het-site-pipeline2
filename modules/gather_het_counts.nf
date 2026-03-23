process GATHER_HET_COUNTS {
    tag "${cohort}/${sample}"
    label 'process_low'

    input:
    tuple val(cohort), val(sample), path(count_files)

    output:
    tuple val(cohort), path("${sample}.het_count.txt")

    script:
    """
    TOTAL=\$(awk '{sum+=\$3} END{print sum+0}' ${count_files})
    echo -e "${sample}\t\$TOTAL" > ${sample}.het_count.txt
    """
}
