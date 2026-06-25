#!/usr/bin/env python3

import argparse
import re
from pathlib import Path

import pandas as pd
import pysam


SUMMARY_COLUMNS = [
    "signal",
    "chromosome",
    "location_min",
    "location_max",
    "signal_strength",
    "lead_variant",
]


def write_empty_summary(outdir):
    pd.DataFrame(columns=SUMMARY_COLUMNS).to_csv(
        outdir / "summary.tsv",
        sep="\t",
        index=False,
    )


def parse_variant(v):
    m = re.match(r"^(chr[0-9XY]+)_([0-9]+)_([^_]+)_([^_]+)$", str(v))
    if not m:
        return None
    chrom, pos, ref, alt = m.groups()
    return chrom, int(pos), ref.upper(), alt.upper()


def ensure_chr_prefix(chrom):
    chrom = str(chrom)
    if chrom.startswith("chr"):
        return chrom
    return "chr" + chrom


def chrom_without_chr(chrom):
    return str(chrom).replace("chr", "")


def fasta_has_chr(fasta):
    return any(x.startswith("chr") for x in fasta.references)


def normalise_chrom_for_fasta(chrom, fasta_uses_chr):
    chrom = str(chrom)
    if fasta_uses_chr:
        return ensure_chr_prefix(chrom)
    return chrom_without_chr(chrom)


def allele_check_keep_hg38(df, fasta_path):
    """
    Input AdipoExpress files have already been shown to match hg38.
    Therefore:
      - do NOT LiftOver
      - validate REF/ALT against hg38
      - keep original coordinates
      - if ALT is reference, swap REF/ALT in the variant ID
    """
    fasta = pysam.FastaFile(str(fasta_path))
    fasta_uses_chr = fasta_has_chr(fasta)

    keep = []
    new_variants = []

    for _, row in df.iterrows():
        chrom_for_variant = ensure_chr_prefix(row["old_chrom"])
        chrom_for_fasta = normalise_chrom_for_fasta(row["old_chrom"], fasta_uses_chr)

        pos = int(row["old_pos"])
        ref = str(row["old_ref"]).upper()
        alt = str(row["old_alt"]).upper()

        try:
            ref_seq = fasta.fetch(chrom_for_fasta, pos - 1, pos - 1 + len(ref)).upper()
        except Exception:
            keep.append(False)
            new_variants.append(None)
            continue

        if ref_seq == ref:
            keep.append(True)
            new_variants.append(f"{chrom_for_variant}_{pos}_{ref}_{alt}")
            continue

        try:
            alt_seq = fasta.fetch(chrom_for_fasta, pos - 1, pos - 1 + len(alt)).upper()
        except Exception:
            alt_seq = None

        if alt_seq == alt:
            keep.append(True)
            new_variants.append(f"{chrom_for_variant}_{pos}_{alt}_{ref}")
            continue

        keep.append(False)
        new_variants.append(None)

    out = df.copy()
    out["keep_allele_checked"] = keep
    out["variant_hg38"] = new_variants
    out["position_hg38"] = out["old_pos"].astype(int)
    out["chromosome_hg38"] = out["old_chrom"].map(chrom_without_chr)

    return out[out["keep_allele_checked"]].copy()


def safe_signal_name(dataset, molecular_trait_id, chrom, loc_min, loc_max, lbf_col):
    lnum = lbf_col.replace("lbf_variable", "L")
    chrom = ensure_chr_prefix(chrom)
    return f"{dataset}_{molecular_trait_id}_{chrom}:{loc_min}-{loc_max}_{lnum}"


def main():
    ap = argparse.ArgumentParser(
        description="Build gpu-coloc-style AdipoExpress eQTL signal pickles from hg38 SuSiE LBF files"
    )

    ap.add_argument("--input", required=True)
    ap.add_argument("--dataset-name", default="AdipoExpress")
    ap.add_argument("--chrom", required=True)
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--fasta", required=True)
    ap.add_argument("--min-lbf", type=float, default=5.0)

    # Kept only for backwards compatibility with old Nextflow module.
    # It is intentionally ignored because AdipoExpress files on this HPC are already hg38.
    ap.add_argument("--chain", default="")
    ap.add_argument("--liftover-bin", default="")

    args = ap.parse_args()

    outdir = Path(args.outdir)
    signals_dir = outdir / "signals"
    signals_dir.mkdir(parents=True, exist_ok=True)

    print("Reading:", args.input)
    print("Mode: no LiftOver; input coordinates are treated as hg38")

    df = pd.read_csv(args.input, sep="\t", compression="gzip", low_memory=False)

    required = [
        "molecular_trait_id",
        "region",
        "variant",
        "chromosome",
        "position",
    ]

    for c in required:
        if c not in df.columns:
            raise SystemExit(f"ERROR: missing required column: {c}")

    lbf_cols = [c for c in df.columns if c.startswith("lbf_variable")]

    if not lbf_cols:
        raise SystemExit("ERROR: no lbf_variable columns found")

    print("Rows before parsing:", len(df))
    print("LBF columns:", ",".join(lbf_cols))

    parsed = df["variant"].map(parse_variant)
    ok = parsed.notna()

    df = df.loc[ok].copy()
    parsed = parsed.loc[ok]

    df["old_chrom"] = [x[0] for x in parsed]
    df["old_pos"] = [x[1] for x in parsed]
    df["old_ref"] = [x[2] for x in parsed]
    df["old_alt"] = [x[3] for x in parsed]

    print("Rows after variant parse:", len(df))

    chrom_clean = str(args.chrom).replace("chr", "")
    df = df[df["old_chrom"].str.replace("chr", "", regex=False) == chrom_clean].copy()

    if df.empty:
        write_empty_summary(outdir)
        print("No rows for chromosome", args.chrom)
        return

    df = df.reset_index(drop=True)

    print("Checking alleles against hg38 fasta without LiftOver")
    df = allele_check_keep_hg38(df, args.fasta)

    print("Rows after allele check:", len(df))

    if df.empty:
        write_empty_summary(outdir)
        print("No rows left after allele check")
        return

    df["chromosome"] = df["chromosome_hg38"].astype(str)
    df["position"] = df["position_hg38"].astype(int)

    for c in lbf_cols:
        df[c] = pd.to_numeric(df[c], errors="coerce")

    summary_rows = []
    signals_written = 0

    print("Building signal pickles")

    for (trait, region), g in df.groupby(["molecular_trait_id", "region"], sort=False):
        g = g.dropna(subset=["variant_hg38", "position"]).copy()

        if g.empty:
            continue

        for lbf_col in lbf_cols:
            x = g[["variant_hg38", "chromosome", "position", lbf_col]].dropna().copy()

            if x.empty:
                continue

            max_lbf = float(x[lbf_col].max())

            if max_lbf < args.min_lbf:
                continue

            x = (
                x.sort_values(["variant_hg38", lbf_col], ascending=[True, False])
                 .drop_duplicates(subset=["variant_hg38"], keep="first")
                 .sort_values("position")
                 .reset_index(drop=True)
            )

            best_idx = x[lbf_col].idxmax()
            lead_variant = str(x.loc[best_idx, "variant_hg38"])
            strength = float(x.loc[best_idx, lbf_col])

            chrom = str(x["chromosome"].iloc[0])
            loc_min = int(x["position"].min())
            loc_max = int(x["position"].max())

            signal_id = safe_signal_name(
                args.dataset_name,
                str(trait),
                chrom,
                loc_min,
                loc_max,
                lbf_col,
            )

            mat = pd.DataFrame(
                [x[lbf_col].to_numpy(dtype=float)],
                columns=x["variant_hg38"].to_numpy(),
                index=[signal_id],
            )

            mat.to_pickle(signals_dir / f"{signal_id}.pickle")

            summary_rows.append({
                "signal": signal_id,
                "chromosome": chrom,
                "location_min": loc_min,
                "location_max": loc_max,
                "signal_strength": strength,
                "lead_variant": lead_variant,
            })

            signals_written += 1

    if summary_rows:
        pd.DataFrame(summary_rows).to_csv(
            outdir / "summary.tsv",
            sep="\t",
            index=False,
        )
    else:
        write_empty_summary(outdir)

    print("signals written:", signals_written)


if __name__ == "__main__":
    main()
