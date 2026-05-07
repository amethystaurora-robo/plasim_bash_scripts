#!/bin/bash

cd /data/complexp/aae19/PLASIM_LD/AMOC_resampling_Matteo/data

for tarfile in *.tar; do
    # Skip if no files match
    [ -e "$tarfile" ] || continue

    # Extract block name (e.g. block_0001)
    block="${tarfile%.tar}"

    echo "Processing $block..."

    # 1. Make directory
    mkdir -p "$block"

    # 2. Move tar file into directory
    mv "$tarfile" "$block/"

    # 3. Extract inside directory
    tar -xf "$block/$tarfile" -C "$block"

    # Optional: remove tar after extraction
    # rm "$block/$tarfile"

done

echo "Done."
