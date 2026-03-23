process INDEX_GVCF {
    tag "${cohort}/${sample}"
    label 'process_low'

    input:
    tuple val(cohort), val(sample), path(gvcf)

    output:
    tuple val(cohort), val(sample), path(gvcf), path("${gvcf}.tbi")

    script:
    """
    bcftools index --tbi ${gvcf}
    """
}
