#!/usr/bin/env python3


import argparse
from pathlib import Path
from bisect import bisect_left, bisect_right, insort
from collections import defaultdict


import numpy as np
import pandas as pd




SUMMARY_COLUMNS = [
    "signal",
    "chromosome",
    "location_min",
    "location_max",
    "signal_strength",
    "lead_variant",
]




def pick_col(cols, candidates):
    for c in candidates:
        if c in cols:
            return c
    raise SystemExit(f"Missing required column. Tried: {candidates}. Have: {list(cols)}")




def calc_lbf(beta, se, prior):
    beta = pd.to_numeric(beta, errors="coerce")
    se = pd.to_numeric(se, errors="coerce")


    v = se ** 2
    r = prior**2 / (prior**2 + v)
    z = beta / se


    # Same approximate Bayes factor formula as gpu-coloc-style preparation.
    # np.log1p(-r) is numerically safer than np.log(1-r).
    return 0.5 * (np.log1p(-r) + r * z**2)




def p_from_z(beta, se):
    # Two-sided normal p-value without scipy:
    # p = erfc(|z| / sqrt(2))
    import math


    z = np.abs(pd.to_numeric(beta, errors="coerce") / pd.to_numeric(se, errors="coerce"))
    return np.array([
        math.erfc(float(v) / math.sqrt(2.0)) if np.isfinite(v) else np.nan
        for v in z
    ])




def clean_chromosome(series):
    raw = series.astype(str).str.replace("^chr", "", regex=True)


    chrom_num = pd.to_numeric(raw, errors="coerce")
    chrom = chrom_num.astype("Int64").astype(str)


    chrom.loc[chrom_num.isna()] = raw.loc[chrom_num.isna()]
    chrom = chrom.replace({
        "23": "X",
        "23.0": "X",
        "<NA>": np.nan,
        "nan": np.nan,
        "None": np.nan,
    })


    return chrom




def normalise_chunk(df, cols, args):
    chr_col = pick_col(cols, ["hm_chrom", "chromosome", "CHR", "chrom", "#CHR"])
    pos_col = pick_col(cols, ["hm_pos", "base_pair_location", "BP", "POS", "pos"])
    ref_col = pick_col(cols, ["hm_other_allele", "other_allele", "REF", "ref"])
    alt_col = pick_col(cols, ["hm_effect_allele", "effect_allele", "ALT", "alt"])
    beta_col = pick_col(cols, ["hm_beta", "beta", "BETA"])
    se_col = pick_col(cols, ["standard_error", "se", "sebeta", "SE"])


    p_col = None
    for c in ["p_value", "pval", "P", "p", "hm_p_value"]:
        if c in cols:
            p_col = c
            break


    out = pd.DataFrame(index=df.index)


    out["chrom"] = clean_chromosome(df[chr_col])
    out["pos"] = pd.to_numeric(df[pos_col], errors="coerce")
    out["ref"] = df[ref_col].astype(str).str.upper()
    out["alt"] = df[alt_col].astype(str).str.upper()
    out["beta"] = pd.to_numeric(df[beta_col], errors="coerce")
    out["se"] = pd.to_numeric(df[se_col], errors="coerce")


    out = out.dropna(subset=["chrom", "pos", "beta", "se"])
    out = out[out["se"] > 0].copy()
    out["pos"] = out["pos"].astype(int)


    if args.gwas_chr:
        keep = set(str(x).replace("chr", "") for x in args.gwas_chr.split(","))
        out = out[out["chrom"].isin(keep)].copy()


    if out.empty:
        return pd.DataFrame(columns=["chrom", "pos", "variant", "lbf", "pval"])


    out["variant"] = (
        "chr" + out["chrom"].astype(str) + "_"
        + out["pos"].astype(str) + "_"
        + out["ref"].astype(str) + "_"
        + out["alt"].astype(str)
    )


    out["lbf"] = calc_lbf(out["beta"], out["se"], args.effect_prior)


    if p_col is not None:
        out["pval"] = pd.to_numeric(df.loc[out.index, p_col], errors="coerce")
    else:
        out["pval"] = p_from_z(out["beta"], out["se"])


    out = out.dropna(subset=["pval", "lbf"])


    return out[["chrom", "pos", "variant", "lbf", "pval"]]




def choose_leads(candidates, window):
    """
    Select independent signal-defining lead candidates.


    Candidates are sorted by p-value first. If another candidate is within
    +/- window of an already selected candidate on the same chromosome, it is
    skipped. This gives one region per independent lead locus.
    """
    candidates = candidates.sort_values(["pval", "chrom", "pos"]).reset_index(drop=True)


    kept = []
    kept_pos = defaultdict(list)


    for _, row in candidates.iterrows():
        chrom = str(row["chrom"])
        pos = int(row["pos"])
        arr = kept_pos[chrom]
        j = bisect_left(arr, pos)


        too_close = False


        if j > 0 and pos - arr[j - 1] <= window:
            too_close = True


        if j < len(arr) and arr[j] - pos <= window:
            too_close = True


        if not too_close:
            kept.append(row)
            insort(arr, pos)


    if not kept:
        return pd.DataFrame(columns=candidates.columns)


    return pd.DataFrame(kept).reset_index(drop=True)




def prepare_lead_index(leads, window):
    """
    Build chromosome-specific sorted lead position arrays.


    This lets each chunk only check leads near the chunk's coordinate range,
    instead of checking every lead for every chunk.
    """
    lead_records = leads.reset_index(drop=True).to_dict("records")


    by_chrom = defaultdict(list)
    for i, lead in enumerate(lead_records):
        chrom = str(lead["chrom"])
        pos = int(lead["pos"])
        by_chrom[chrom].append((pos, i))


    lead_positions = {}
    for chrom, vals in by_chrom.items():
        vals = sorted(vals)
        lead_positions[chrom] = {
            "positions": [x[0] for x in vals],
            "indices": [x[1] for x in vals],
        }


    return lead_records, lead_positions




def append_chunk_to_regions(x, lead_positions, regions, window):
    """
    Efficiently append variants to lead regions.


    For each chromosome present in the chunk:
      - get chunk min/max position
      - only consider leads whose windows overlap the chunk range
      - append variants within each relevant lead window
    """
    for chrom, x_chr in x.groupby("chrom", sort=False):
        chrom = str(chrom)


        if chrom not in lead_positions:
            continue


        positions = lead_positions[chrom]["positions"]
        indices = lead_positions[chrom]["indices"]


        chunk_min = int(x_chr["pos"].min())
        chunk_max = int(x_chr["pos"].max())


        # Leads that could overlap this chunk:
        # lead_pos + window >= chunk_min  => lead_pos >= chunk_min - window
        # lead_pos - window <= chunk_max  => lead_pos <= chunk_max + window
        left = bisect_left(positions, chunk_min - window)
        right = bisect_right(positions, chunk_max + window)


        if left == right:
            continue


        x_chr = x_chr.sort_values("pos")


        for j in range(left, right):
            lead_idx = indices[j]
            lead_pos = positions[j]


            m = x_chr["pos"].between(lead_pos - window, lead_pos + window)
            if m.any():
                regions[lead_idx].append(
                    x_chr.loc[m, ["chrom", "pos", "variant", "lbf"]].copy()
                )




def write_empty_summary(outdir):
    pd.DataFrame(columns=SUMMARY_COLUMNS).to_csv(
        outdir / "summary.tsv",
        sep="\t",
        index=False,
    )




def main():
    ap = argparse.ArgumentParser(description="Build official-style GWAS signal pickles from harmonised summary statistics.")
    ap.add_argument("--gwas", required=True)
    ap.add_argument("--trait", required=True)
    ap.add_argument("--outdir", required=True)
    ap.add_argument("--window", type=int, default=1_000_000)
    ap.add_argument("--lead-p", type=float, default=5e-8)
    ap.add_argument("--min-lbf", type=float, default=5.0)
    ap.add_argument("--effect-prior", type=float, default=0.2)
    ap.add_argument("--chunksize", type=int, default=500000)
    ap.add_argument("--gwas-chr", default="")
    args = ap.parse_args()


    outdir = Path(args.outdir)
    signals_dir = outdir / "signals"
    signals_dir.mkdir(parents=True, exist_ok=True)


    header = pd.read_csv(args.gwas, sep="\t", nrows=0).columns


    all_candidates = []


    print("Pass 1: finding lead candidates")


    for chunk in pd.read_csv(args.gwas, sep="\t", chunksize=args.chunksize, low_memory=False):
        x = normalise_chunk(chunk, header, args)


        if x.empty:
            continue


        cand = x[(x["pval"] <= args.lead_p) & (x["lbf"] >= args.min_lbf)].copy()


        if not cand.empty:
            all_candidates.append(cand)


    if not all_candidates:
        write_empty_summary(outdir)
        print("lead candidates: 0")
        print("dedup leads: 0")
        print("signals written: 0")
        return


    candidates = pd.concat(all_candidates, ignore_index=True)


    # If the same variant appears more than once, keep the strongest row.
    candidates = (
        candidates
        .sort_values(["pval", "lbf"], ascending=[True, False])
        .drop_duplicates(subset=["variant"], keep="first")
        .reset_index(drop=True)
    )


    leads = choose_leads(candidates, args.window)


    print("lead candidates:", len(candidates))
    print("dedup leads:", len(leads))


    if leads.empty:
        write_empty_summary(outdir)
        print("signals written: 0")
        return


    regions = {i: [] for i in range(len(leads))}
    lead_records, lead_positions = prepare_lead_index(leads, args.window)


    print("Pass 2: collecting variants around selected leads")


    for chunk in pd.read_csv(args.gwas, sep="\t", chunksize=args.chunksize, low_memory=False):
        x = normalise_chunk(chunk, header, args)


        if x.empty:
            continue


        append_chunk_to_regions(x, lead_positions, regions, args.window)


    summary_rows = []


    print("Writing signal pickles")


    for i, lead in enumerate(lead_records):
        if not regions[i]:
            continue


        region = pd.concat(regions[i], ignore_index=True)


        # Keep the strongest lbf value if duplicate variant IDs exist.
        region = (
            region
            .sort_values(["variant", "lbf"], ascending=[True, False])
            .drop_duplicates(subset=["variant"], keep="first")
            .sort_values("pos")
            .reset_index(drop=True)
        )


        if region.empty:
            continue


        chrom = str(lead["chrom"])
        loc_min = int(region["pos"].min())
        loc_max = int(region["pos"].max())
        signal_id = f"{args.trait}_chr{chrom}:{loc_min}-{loc_max}"


        # Official-style choice:
        # lead_variant and signal_strength both correspond to the strongest
        # variant in the final region matrix.
        best_idx = region["lbf"].idxmax()
        lead_variant = str(region.loc[best_idx, "variant"])
        strength = float(region.loc[best_idx, "lbf"])


        if strength < args.min_lbf:
            continue


        summary_rows.append({
            "signal": signal_id,
            "chromosome": chrom,
            "location_min": loc_min,
            "location_max": loc_max,
            "signal_strength": strength,
            "lead_variant": lead_variant,
        })


        mat = pd.DataFrame(
            [region["lbf"].to_numpy()],
            columns=region["variant"].to_numpy(),
            index=[signal_id],
        )


        mat.to_pickle(signals_dir / f"{signal_id}.pickle")


    if summary_rows:
        pd.DataFrame(summary_rows).to_csv(outdir / "summary.tsv", sep="\t", index=False)
    else:
        write_empty_summary(outdir)


    print("signals written:", len(summary_rows))




if __name__ == "__main__":
    main()
