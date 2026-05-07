#!/bin/bash
set -euo pipefail

expname=AMOC_resampling_Matteo
srv2nc=/scratch/complexp/aae19/PLASIM_LD-main/scripts/srv2nc
average=    # e.g. "-a" if you used an averaging option before, else leave empty

cd /data/complexp/aae19/PLASIM_LD/AMOC_resampling_Matteo/data

# loop over all block directories
for blockdir in AMOC_resampling_Matteo_data_block_*; do
    [ -d "$blockdir" ] || continue
    echo "Processing block dir: $blockdir"

    cd "$blockdir"

    # loop over all .nc files in this block dir
    for raw in *.nc; do
        # skip if there are no .nc files
        [ -e "$raw" ] || continue

        # choose a temporary output name
        tmp="${raw%.nc}_tmp.nc"

        echo "  Converting $raw -> $tmp"
        # run srv2nc on the raw file; add $average if needed
        "$srv2nc" $average "$raw" "$tmp"

        # sanity check: make sure tmp is non‑empty
        if [ ! -s "$tmp" ]; then
            echo "    WARNING: $tmp is empty, not replacing $raw"
            rm -f "$tmp"
            continue
        fi

        # replace raw file with converted NetCDF
        mv -f "$tmp" "$raw"
    done

    cd ..
done

echo "Done converting all *.nc files with srv2nc."
