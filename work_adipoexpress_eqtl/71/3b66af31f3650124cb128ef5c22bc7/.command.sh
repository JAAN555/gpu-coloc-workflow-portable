#!/bin/bash -euo pipefail
set -euo pipefail

rm -rf eqtl_grouped
mkdir -p eqtl_grouped

for d in chr_4 chr_3 chr_5 chr_8 chr_13 chr_21 chr_9 chr_14 chr_22 chr_20 chr_2 chr_10 chr_11 chr_15 chr_18 chr_16 chr_X chr_1 chr_6 chr_7 chr_12 chr_17 chr_19; do
  [[ -d "$d" ]] || continue

  for chr_sub in "$d"/*; do
    [[ -d "$chr_sub" ]] || continue

    chr=$(basename "$chr_sub")
    mkdir -p "eqtl_grouped/$chr"

    for f in "$chr_sub"/*.parquet; do
      [[ -f "$f" ]] || continue
      ln -s "$(realpath "$f")" "eqtl_grouped/$chr/$(basename "$f")"
    done
  done
done

find eqtl_grouped -name "*.parquet" | wc -l > grouped_file_count.txt

echo "Grouped parquet count:"
cat grouped_file_count.txt

test -d eqtl_grouped
