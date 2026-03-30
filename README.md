# het-site-pipeline (Nextflow)

A reproducible Nextflow DSL2 pipeline that counts heterozygous sites across gVCF cohorts, merges with sample metadata, and generates per-cohort reports.

---

## Pipeline DAG

```
INDEX_GVCF               (skip if .tbi already exists)
      │
      ▼
COUNT_HET_BY_CHROM       (per sample × chromosome — fully parallel)
      │
      ▼
GATHER_HET_COUNTS        (sum chroms → one Het_Count per sample)
      │
      ▼
MERGE_COUNTS             (all samples → per-cohort TSV)
      │
      ▼
MAKE_REPORT              (parquet + PDF per cohort)
      │
      ▼
MERGE_ALL_COHORTS        (single cross-cohort parquet)
```

---

## Requirements

```bash
conda env create -f environment.yaml
conda activate het-site-pipeline
```

---

## Input structure

```
Cohort_A/
├── metadata.tsv          # columns: SampleID, Age, Ancestry, IQ
├── sample1.gvcf.gz
├── sample1.gvcf.gz.tbi   # auto-created if missing
└── ...
Cohort_B/
└── ...
```

---

## Usage

### Local

```bash
# Test run (chr1 + chr22 only)
nextflow run main.nf -profile test

# Full run
nextflow run main.nf -profile local

# Custom cohorts
nextflow run main.nf -profile local --cohorts "Cohort_A,Cohort_B,Cohort_C"
```

### SLURM (Narval / Compute Canada)

```bash
sbatch submit_pipeline.sh

# Or directly
nextflow run main.nf -profile slurm -resume
```

### Resume after failure

```bash
nextflow run main.nf -profile slurm -resume
```

---

## Outputs

```
results/
├── Cohort_A/
│   ├── Cohort_A_final.parquet     # SampleID, Age, Ancestry, IQ, Cohort, Het_Count
│   └── Cohort_A_Report.pdf
├── Cohort_B/
│   ├── Cohort_B_final.parquet
│   └── Cohort_B_Report.pdf
├── all_cohorts_merged.parquet
└── reports/
    ├── execution_report.html      # Resource usage per process
    ├── timeline.html              # Job timeline visualisation
    └── trace.tsv                  # Per-task CPU, RAM, runtime
```

---

## Parameters

| Parameter    | Default           | Description                      |
|--------------|-------------------|----------------------------------|
| `cohorts`    | `Cohort_A,Cohort_B` | Comma-separated cohort names   |
| `results_dir`| `results`         | Output root directory            |
| `min_dp`     | `20`              | FORMAT/DP threshold (strict >)   |
| `min_gq`     | `30`              | FORMAT/GQ threshold (>=)         |
| `chroms`     | chr1–22,X,Y       | Chromosomes for scatter          |

Override at runtime:
```bash
nextflow run main.nf -profile slurm --min_dp 30 --min_gq 40
```

---

## Key differences from Snakemake version

| Feature | Snakemake | Nextflow |
|---|---|---|
| Resume | `--rerun-incomplete` | `-resume` (automatic) |
| Scatter | wildcards | `combine()` + `groupTuple()` |
| Reports | benchmark TSV | HTML report + timeline + trace |
| Config | `config.yaml` | `nextflow.config` + profiles |
| SLURM | `--executor slurm` | `-profile slurm` |


## Citation / Reuse
If you use or adapt this pipeline, please credit the author.

## Author
Nadeem Khan, PhD Bioinformatician — INRS–Centre Armand-Frappier Santé-Biotechnologie, Laval, QC, Canada nkhan119@uottawa.ca @nkhan119
