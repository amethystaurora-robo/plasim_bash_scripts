#!/bin/bash
module load openmpi gcc cdo

cd /data/complexp/aae19/PLASIM_LD/AMOC_resampling_Matteo/data || exit 1

# create array (no commas)
#arr=("var178" "var179" "var203" "var146" "var147" "var176" "var177" "var204" "var205" "var-18")
arr=("var-18")
for var in "${arr[@]}"; do
    echo "Processing variable: $var"

    # select filename prefix based on variable
    if [[ $var == "var-18" ]]; then
        filename="LSG"
    else
        filename="PLA"
    fi

    outdir="combined_${var}"
    mkdir -p "$outdir"

    # loop trajectories 0001..0100
    for traj in $(seq -f "%04g" 1 100); do
        echo "  traj $traj"

        # build file list for this trajectory across blocks
        files=()
        for f in block_*/AMOC_resampling_Matteo_${filename}.year*_traj${traj}.nc; do
            [[ -f "$f" ]] || continue
            files+=("$f")
        done

        if [[ ${#files[@]} -eq 0 ]]; then
            echo "    no files found for traj${traj}, skipping"
            continue
        fi

        outtmp="${outdir}/combined_traj_${traj}.nc"
        outfinal="${outdir}/${var}_traj_${traj}.nc"
	tmp="$(mktemp --tmpdir=/tmp cdo_tmp.XXXXXX.nc)"
	# 1) merge time into one file
	cdo -O mergetime "${files[@]}" "$tmp"
	if [[ $? -ne 0 ]]; then
  		echo "    mergetime failed for traj${traj}"
  		rm -f "$tmp"
  		continue
	fi

	# 2) select variable from the merged file
	cdo -O selname,${var} "$tmp" "$outtmp"
	if [[ $? -ne 0 ]]; then
  		echo "    selname failed for traj${traj}"
  		rm -f "$tmp" "$outtmp"
  		continue
	fi

	rm -f "$tmp"
      
        # If needed, rename/move result (already selected variable) to desired name
        mv -f "$outtmp" "$outfinal"
        echo "    wrote $outfinal"
    done

    echo "Finished variable: $var (outputs in $outdir)"
done

echo "All variables processed."
