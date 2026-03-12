#!/bin/bash

#change for different experiment
expname=$2
expdir="/data/complexp/aae19/PLASIM_LD/${expname}/diag"
#YEAR1=1
#YEAR2=120
echo "Argument is $1"
cd $expdir
#change for different experiment
OUTDIR="/data/complexp/aae19/PLASIM_LD/${expname}/post/ctrlobs"
#mkdir -p "$OUTDIR"
#expname="AMOC_try_resampling"

#OUTFILE="$OUTDIR/amoc_averaged.txt"
#rm -f "$OUTFILE"
block=$1
expname=$2
echo "Block: ${block}"
#block=0001
MAX=100
YEAR=1
TRAJEC=1
for i in $(seq -w 1 "$MAX"); do
   # for ((YEAR=$YEAR1; YEAR<=$YEAR2; YEAR++)); do
    cd ${expdir}/block_${block}
    echo "Working directory" 
    pwd
    #ls
    FILENAME=$(printf '%s_DIAG.year%04d_traj%04d.txt' "$expname" "$((10#$block))" "$((10#$i))")
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
    OUTFILE=`printf '%s_ctrlobs.%04d.%04d.txt' "$expname"  "$TRAJEC" "$((10#$block))"`
    echo "Found ATL max NADW values: $VALUES"

    if [[ -z "$VALUES" ]]; then
        echo " No ATL max NADW found"
        echo "" >> "$OUTFILE"
        continue
    fi

    #average
    AVG=$(echo "$VALUES" | awk '{ total += $1; count++ } END { print total/count }')

    echo "Average for year $YEAR = $AVG"
    cd ${OUTDIR}
    echo "$AVG" > "$OUTFILE"
    TRAJEC=$((TRAJEC + 1))
   # YEAR=$((YEAR + 1))
done
#done
