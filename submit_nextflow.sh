#!/bin/bash
#SBATCH --account=def-fveyrier_cpu
#SBATCH --cpus-per-task=4
#SBATCH --mem=8G
#SBATCH --time=24:00:00
#SBATCH --mail-user=nadeem.khan@inrs.ca
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --job-name=het_pipeline_nf
#SBATCH --output=logs/slurm/het_pipeline_nf.%j.out
#SBATCH --error=logs/slurm/het_pipeline_nf.%j.err

# ============================================================
# het-site-pipeline2 — Nextflow SLURM submission script
#
# Fixes:
#   - Removed -dry-run (not a valid Nextflow flag)
#   - Added NXF_DISABLE_CHECK_LATEST=true to prevent
#     Nextflow from trying to reach nextflow.io (blocked on Narval)
#
# Submit with:
#   sbatch submit_nextflow.sh
#
# Submit with custom cohorts:
#   COHORTS="Cohort_A,Cohort_B,Cohort_C" sbatch submit_nextflow.sh
# ============================================================

set -euo pipefail

# ── Load Java ─────────────────────────────────────────────────
module load java/21.0.1

# ── Disable internet check (Narval blocks outbound HTTPS) ─────
export NXF_DISABLE_CHECK_LATEST=true

cd $SLURM_SUBMIT_DIR
mkdir -p logs/slurm results

# ── Print run info ────────────────────────────────────────────
echo "============================================"
echo "Job ID     : $SLURM_JOB_ID"
echo "Node       : $SLURMD_NODENAME"
echo "Submit dir : $SLURM_SUBMIT_DIR"
echo "Start time : $(date)"
echo "Nextflow   : $(nextflow -version 2>&1 | grep version | xargs)"
echo "Python     : $(python3 --version)"
echo "bcftools   : $(bcftools --version | head -1)"
echo "Cohorts    : ${COHORTS:-Cohort_A,Cohort_B}"
echo "============================================"

# ── Run pipeline ──────────────────────────────────────────────
echo ""
echo "--- Starting pipeline ---"
nextflow run main.nf \
    -profile slurm \
    -resume \
    --cohorts "${COHORTS:-Cohort_A,Cohort_B}" \
    --results_dir results

# ── Done ──────────────────────────────────────────────────────
echo ""
echo "============================================"
echo "Pipeline finished : $(date)"
echo "Results           : $SLURM_SUBMIT_DIR/results/"
echo "Execution report  : $SLURM_SUBMIT_DIR/results/reports/execution_report.html"
echo "Timeline          : $SLURM_SUBMIT_DIR/results/reports/timeline.html"
echo "Trace             : $SLURM_SUBMIT_DIR/results/reports/trace.tsv"
echo "============================================"
