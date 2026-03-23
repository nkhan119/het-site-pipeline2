#!/usr/bin/env python3
"""
bin/make_report.py
------------------
Merges het-site counts with sample metadata.
Produces: .parquet + .pdf report

Called by Nextflow process MAKE_REPORT.
"""

import argparse
import os
import sys
import pandas as pd
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.gridspec as gridspec
import seaborn as sns
from matplotlib.backends.backend_pdf import PdfPages

# ── Args ──────────────────────────────────────────────────────
parser = argparse.ArgumentParser()
parser.add_argument("--cohort",       required=True)
parser.add_argument("--counts",       required=True)
parser.add_argument("--metadata",     required=True)
parser.add_argument("--min-dp",       type=int, default=20)
parser.add_argument("--min-gq",       type=int, default=30)
parser.add_argument("--out-parquet",  required=True)
parser.add_argument("--out-pdf",      required=True)
args = parser.parse_args()

cohort   = args.cohort
min_dp   = args.min_dp
min_gq   = args.min_gq

print(f"[make_report] Starting {cohort}", file=sys.stderr)

# ── Load & merge ──────────────────────────────────────────────
meta   = pd.read_csv(args.metadata, sep="\t")
counts = pd.read_csv(args.counts,   sep="\t")

df = pd.merge(meta, counts, on="SampleID", how="inner")
df["Cohort"] = cohort
df = df[["SampleID", "Age", "Ancestry", "IQ", "Cohort", "Het_Count"]]

print(f"[make_report] {cohort}: {len(df)} samples", file=sys.stderr)
print(df["Het_Count"].describe().to_string(), file=sys.stderr)

# ── Parquet ───────────────────────────────────────────────────
df.to_parquet(args.out_parquet, index=False)
print(f"[make_report] Parquet → {args.out_parquet}", file=sys.stderr)

# ── PDF ───────────────────────────────────────────────────────
PALETTE = {"Age": "#5b9bd5", "Het_Count": "#ed7d31", "IQ": "#70ad47"}

with PdfPages(args.out_pdf) as pdf:

    # Page 1 — overview boxplots
    fig = plt.figure(figsize=(14, 8))
    fig.suptitle(
        f"Summary Report: {cohort}   (n={len(df)} samples)\n"
        f"QC filters: DP > {min_dp}, GQ ≥ {min_gq}",
        fontsize=14, fontweight="bold", y=0.98,
    )
    gs = gridspec.GridSpec(2, 3, figure=fig, hspace=0.45, wspace=0.35)

    ax0 = fig.add_subplot(gs[0, :2])
    sns.boxplot(data=df, x="Ancestry", y="Het_Count", palette="Set2", ax=ax0)
    ax0.set_title("Het_Count by Ancestry", fontweight="bold")
    ax0.tick_params(axis="x", rotation=30)

    ax1 = fig.add_subplot(gs[0, 2])
    ac = df["Ancestry"].value_counts()
    ax1.bar(ac.index, ac.values, color=sns.color_palette("Set2", len(ac)))
    ax1.set_title("Samples per Ancestry", fontweight="bold")
    ax1.tick_params(axis="x", rotation=30)

    ax2 = fig.add_subplot(gs[1, 0])
    sns.boxplot(data=df, y="Age", color=PALETTE["Age"], ax=ax2)
    ax2.set_title("Age Distribution", fontweight="bold")

    ax3 = fig.add_subplot(gs[1, 1])
    sns.boxplot(data=df, y="IQ", color=PALETTE["IQ"], ax=ax3)
    ax3.set_title("IQ Distribution", fontweight="bold")

    ax4 = fig.add_subplot(gs[1, 2])
    sns.boxplot(data=df, y="Het_Count", color=PALETTE["Het_Count"], ax=ax4)
    ax4.set_title("Het_Count Overall", fontweight="bold")

    pdf.savefig(fig, bbox_inches="tight")
    plt.close(fig)

    # Page 2 — scatterplots
    fig2, axes2 = plt.subplots(1, 2, figsize=(12, 5))
    fig2.suptitle(f"{cohort}: Het_Count relationships", fontsize=13, fontweight="bold")
    sns.scatterplot(data=df, x="Age", y="Het_Count", hue="Ancestry",
                    palette="Set2", alpha=0.8, ax=axes2[0])
    axes2[0].set_title("Het_Count vs Age")
    sns.scatterplot(data=df, x="IQ",  y="Het_Count", hue="Ancestry",
                    palette="Set2", alpha=0.8, ax=axes2[1])
    axes2[1].set_title("Het_Count vs IQ")
    pdf.savefig(fig2, bbox_inches="tight")
    plt.close(fig2)

    # Page 3 — summary table
    fig3, ax5 = plt.subplots(figsize=(10, 4))
    ax5.axis("off")
    summary = df.groupby("Ancestry").agg(
        N=("SampleID","count"), Age_mean=("Age","mean"),
        IQ_mean=("IQ","mean"), Het_mean=("Het_Count","mean"),
        Het_median=("Het_Count","median"), Het_std=("Het_Count","std"),
    ).round(1).reset_index()
    tbl = ax5.table(cellText=summary.values, colLabels=summary.columns,
                    cellLoc="center", loc="center")
    tbl.auto_set_font_size(False)
    tbl.set_fontsize(9)
    tbl.scale(1.2, 1.6)
    ax5.set_title(f"{cohort}: Summary by Ancestry", fontweight="bold", pad=20)
    pdf.savefig(fig3, bbox_inches="tight")
    plt.close(fig3)

    d = pdf.infodict()
    d["Title"]  = f"Het-Site Report: {cohort}"
    d["Author"] = "het-site-pipeline"

print(f"[make_report] PDF → {args.out_pdf}", file=sys.stderr)
