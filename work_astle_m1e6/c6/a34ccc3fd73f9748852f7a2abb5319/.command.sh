#!/bin/bash -euo pipefail
set -euo pipefail

rm -rf gwas_grouped
mkdir -p gwas_grouped

for d in chr_X chr_21 chr_18 chr_13 chr_22 chr_4 chr_14 chr_15 chr_16 chr_20 chr_9 chr_11 chr_8 chr_10 chr_7 chr_19 chr_12 chr_3 chr_17 chr_5 chr_2 chr_6 chr_1; do
  [[ -d "$d" ]] || continue

  for chr_sub in "$d"/*; do
    [[ -d "$chr_sub" ]] || continue

    chr=$(basename "$chr_sub")
    mkdir -p "gwas_grouped/$chr"

    for f in "$chr_sub"/*.parquet; do
      [[ -f "$f" ]] || continue
      ln -s "$(realpath "$f")" "gwas_grouped/$chr/$(basename "$f")"
    done
  done
done

find gwas_grouped -name "*.parquet" | wc -l > grouped_file_count.txt

echo "Grouped parquet count:"
cat grouped_file_count.txt

test -d gwas_grouped
