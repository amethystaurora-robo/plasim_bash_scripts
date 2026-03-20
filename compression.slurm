#!/bin/bash
#SBATCH --job-name=compress
#SBATCH --time=02:00:00
#SBATCH --mem=4G

tar -czf AMOC_resampling_200k_part1.tar.gz /data/complexp/aae19/PLASIM_LD/AMOC_resampling_200k
