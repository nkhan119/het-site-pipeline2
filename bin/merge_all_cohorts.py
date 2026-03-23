#!/usr/bin/env python3
"""
bin/merge_all_cohorts.py
------------------------
Concatenates all per-cohort parquets into one cross-cohort file.
Called by Nextflow process MERGE_ALL_COHORTS.
"""

import argparse
import sys
import pandas as pd

parser = argparse.ArgumentParser()
parser.add_argument("--input",  nargs="+", required=True)
parser.add_argument("--output", required=True)
args = parser.parse_args()

print(f"[merge_all_cohorts] Merging {len(args.input)} cohort(s)", file=sys.stderr)

frames = []
for f in args.input:
    df = pd.read_parquet(f)
    print(f"  - {f}: {len(df)} samples", file=sys.stderr)
    frames.append(df)

merged = pd.concat(frames, ignore_index=True)
merged.to_parquet(args.output, index=False)

print(f"\n[merge_all_cohorts] Total: {len(merged)} samples", file=sys.stderr)
print(merged.groupby("Cohort")[["Het_Count"]].describe().round(1).to_string(), file=sys.stderr)
print(f"\nOutput → {args.output}", file=sys.stderr)
