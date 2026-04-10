#!/bin/bash
#SBATCH --job-name=compress_blocks
#SBATCH --output=compress_200.out
#SBATCH --error=compress_200.err
#SBATCH --time=12:00:00
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G

set -euo pipefail

BASE="/data/complexp/aae19/PLASIM_LD"

# Function to compress a range of blocks
compress_range () {
    expname=$1
    subdir=$2
    start=$3
    end=$4

    target_dir="${BASE}/${expname}/${subdir}"

    echo "Processing ${target_dir} from block_${start} to block_${end}"

    for i in $(seq ${start} ${end}); do
        block=$(printf "block_%04d" $i)
        fullpath="${target_dir}/${block}"

        if [ -d "$fullpath" ]; then
            echo "Compressing $fullpath"

            tar -cf "${fullpath}.tar" -C "${target_dir}" "${block}" && \
            rm -rf "${fullpath}"
        else
            echo "Skipping missing $fullpath"
        fi
    done
}

# =========================
# Run jobs
# =========================

# 50k (blocks 1–520)
#compress_range "AMOC_resampling_50k" "diag" 1 520
#compress_range "AMOC_resampling_50k" "rest" 1 520

# 100k (blocks 1–560)
#compress_range "AMOC_resampling_100k" "diag" 1 812
#compress_range "AMOC_resampling_100k" "rest" 1 812

# 200k (blocks 1–642)
compress_range "AMOC_resampling_200k" "diag" 1 392
compress_range "AMOC_resampling_200k" "rest" 1 392

echo "All compression done."
