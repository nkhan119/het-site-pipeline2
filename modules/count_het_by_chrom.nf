process COUNT_HET_BY_CHROM {
    tag "${cohort}/${sample}:${chrom}"
    label 'process_low'

    input:
    // tuple order: [cohort, sample, gvcf, tbi, chrom]
    tuple val(cohort), val(sample), path(gvcf), path(tbi), val(chrom)

    output:
    // emit: [cohort, sample, count_file]
    tuple val(cohort), val(sample), path("${sample}.${chrom}.het_count.txt")

    script:
    """
    COUNT=\$(bcftools view \\
                --genotype het \\
                --include 'FORMAT/DP>${params.min_dp} && FORMAT/GQ>=${params.min_gq}' \\
                --regions ${chrom} \\
                --output-type u \\
                ${gvcf} \\
            | bcftools view -H \\
            | wc -l)
    echo -e "${sample}\t${chrom}\t\$COUNT" > ${sample}.${chrom}.het_count.txt
    """
}
