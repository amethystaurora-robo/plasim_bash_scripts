#!/bin/bash

expdir='/scratch/complexp/aae19/PLASIM_LD/plasim/run/output/work'
YEAR1=1
YEAR2=7

cd $expdir
OUTDIR="/scratch/complexp/aae19/amoc_results"
mkdir -p "$OUTDIR"
OUTFILE="$OUTDIR/amoc_monthly.txt"

#loop through to make files
#make column headers TrajID,Averaged Value,Year
echo -e "Monthly AMOC Index (NADW)\Year\Month\Trajectory ID" > $OUTFILE
#cd into folders based on outer and inner loops
for year in $(seq "$YEAR1" "$YEAR2"); do
    for traj in {1..99}; do
        pwd
	cd $expdir
        cd Y${year}_traj${traj}
        ls
        #fix padded zeroes for file names
        year4=$(printf "%04d" "$year")
        traj4=$(printf "%04d" "$traj")
        FILENAME="change_kleiin_DIAG.year${year4}_traj${traj4}.txt"
        echo "---- YEAR $YEAR ----"
        echo "Checking: $FILENAME"

        #does file exist
        if [[ ! -f "$FILENAME" ]]; then
            echo " File not found: $FILENAME"
            echo "" >> "$OUTFILE"
            continue
        fi

	echo "File OK"

        #Extract all ATL max (NADW) values, take first column
        VALUES=$(awk -F: '/ATL max \(NADW\)/ {gsub(/^[ \t]+/, "", $2); print $2}' "$FILENAME" | awk '{print $1}')
	MONTHS=$(awk -F'date: ' '/LSG timestep/ { gsub(/\*/, "", $2); print $2 }' "$FILENAME" | awk '{print $1}')
        echo "Found ATL max NADW values: $VALUES"

        if [[ -z "$VALUES" ]]; then
            echo " No ATL max NADW found"
            echo "" >> "$OUTFILE"
            continue
        fi

        #average
        #AVG=$(echo "$VALUES" | awk '{ total += $1; count++ } END { print total/count }')
	#append values instead
	#try pasting values instead
	paste <(echo "$VALUES") <(echo "$MONTHS") | while read val month; do
   		 echo -e "$val\t$year\t$month\t$traj" >> "$OUTFILE"
	done

	#for i in "${!VALUES[@]}"; do
	#	echo -e "${VALUES[$i]}\t$year\t${MONTHS[$i]}\t$traj" >> "$OUTFILE"
	#done
        #echo "Average for year $YEAR = $AVG"
        #add trajID and year to columns
        #echo -e "$AVG\t$year\t$traj" >> "$OUTFILE" 
    done
done
 echo "✔️Finished. Output saved to $OUTFILE"


