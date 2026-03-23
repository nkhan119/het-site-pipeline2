#!/usr/bin/env nextflow

// ============================================================
// het-site-pipeline (Nextflow DSL2)
// ============================================================
// Usage:
//   nextflow run main.nf -profile test
//   nextflow run main.nf -profile local
//   nextflow run main.nf -profile slurm
//   nextflow run main.nf -resume
// ============================================================

nextflow.enable.dsl = 2

// ── Parameters ───────────────────────────────────────────────
params.cohorts     = "Cohort_A,Cohort_B"
params.results_dir = "results"
params.min_dp      = 20
params.min_gq      = 30
params.chroms      = "chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10," +
                     "chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19," +
                     "chr20,chr21,chr22,chrX,chrY"

// ── Import modules ───────────────────────────────────────────
include { INDEX_GVCF         } from './modules/index_gvcf'
include { COUNT_HET_BY_CHROM } from './modules/count_het_by_chrom'
include { GATHER_HET_COUNTS  } from './modules/gather_het_counts'
include { MERGE_COUNTS       } from './modules/merge_counts'
include { MAKE_REPORT        } from './modules/make_report'
include { MERGE_ALL_COHORTS  } from './modules/merge_all_cohorts'

// ── Main workflow ─────────────────────────────────────────────
workflow {

    chrom_ch = Channel.from( params.chroms.split(",") )

    // ── Channel: [cohort, sample, gvcf] ──────────────────────
    gvcf_ch = Channel.from( params.cohorts.split(",") )
        .flatMap { cohort ->
            file("${cohort}/*.gvcf.gz").collect { gvcf ->
                def sample = gvcf.baseName.replace(".gvcf", "")
                tuple( cohort, sample, gvcf )
            }
        }

    // ── Channel: [cohort, metadata] ──────────────────────────
    meta_ch = Channel.from( params.cohorts.split(",") )
        .map { cohort -> tuple( cohort, file("${cohort}/metadata.tsv") ) }

    // ── Step 1: Split into needs-indexing vs already-indexed ──
    gvcf_ch.branch {
            cohort, sample, gvcf ->
            needs_index : !file("${gvcf}.tbi").exists()
            has_index   : file("${gvcf}.tbi").exists()
        }
        .set { gvcf_branched }

    // Index the ones that need it → emit [cohort, sample, gvcf, tbi]
    INDEX_GVCF( gvcf_branched.needs_index )

    // Already indexed → attach tbi manually
    already_indexed = gvcf_branched.has_index
        .map { cohort, sample, gvcf ->
            tuple( cohort, sample, gvcf, file("${gvcf}.tbi") )
        }

    // Combine both into one channel: [cohort, sample, gvcf, tbi]
    indexed_ch = INDEX_GVCF.out.mix( already_indexed )

    // ── Step 2: Scatter — combine with chromosomes ────────────
    // Result: [cohort, sample, gvcf, tbi, chrom]
    scatter_ch = indexed_ch.combine( chrom_ch )

    COUNT_HET_BY_CHROM( scatter_ch )

    // ── Step 3: Gather — group by [cohort, sample] ────────────
    // Result: [cohort, sample, [count_files...]]
    gather_input = COUNT_HET_BY_CHROM.out
        .groupTuple( by: [0, 1] )

    GATHER_HET_COUNTS( gather_input )

    // ── Step 4: Merge samples per cohort ─────────────────────
    // Result: [cohort, [het_count_files...]]
    merge_input = GATHER_HET_COUNTS.out
        .groupTuple( by: 0 )

    MERGE_COUNTS( merge_input )

    // ── Step 5: Join counts + metadata → parquet + PDF ────────
    // Result: [cohort, counts_tsv, metadata_tsv]
    report_input = MERGE_COUNTS.out.join( meta_ch, by: 0 )

    MAKE_REPORT( report_input )

    // ── Step 6: Collect all parquets → merged output ──────────
    MERGE_ALL_COHORTS(
        MAKE_REPORT.out.parquet
            .map { cohort, parquet -> parquet }
            .collect()
    )
}
