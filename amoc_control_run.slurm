#!/bin/bash

expdir='/data/complexp/fr120/PLASIM-1.0/plasim/run/output'
YEAR1=1001
YEAR2=2000

cd $expdir
OUTDIR="/scratch/complexp/aae19/amoc_control"
mkdir -p "$OUTDIR"
expname="AMOC_control"

OUTFILE="$OUTDIR/amoc_control.txt"
#rm -f "$OUTFILE"
#block=$1
#block=0001
#MAX=100
#YEAR=1
#TRAJEC=1
cd expdir
#echo "OUTDIR = $OUTDIR"
#echo "OUTFILE = $OUTFILE"
#echo "Full path = ${OUTDIR}/${OUTFILE}"
#for i in $(seq -w 1 "$MAX"); do
for ((YEAR=$YEAR1; YEAR<=$YEAR2; YEAR++)); do
    yearly_sum=0
    yearly_count=0

    for ((month=1; month<=12; month++)); do
    	cd ${expdir}
    	echo "Working directory" 
    	pwd
    	#ls
    	FILENAME=$(printf 'CONTROL_360ppm_DIAG.%04d.%02d.txt' "$YEAR" "$month")
    

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
    	#OUTFILE=`printf '%s_ctrlobs.%04d.%04d.txt' "$expname"  "$YEAR" "$block"`
    	echo "Found ATL max NADW values: $VALUES"

    	if [[ -z "$VALUES" ]]; then
            echo " No ATL max NADW found"
            echo "" >> "$OUTFILE"
            continue
    	fi
	echo "$VALUES" >> "$OUTFILE"
	#read sum count <<< $(echo "$VALUES" | awk '{total+=$1; n++} END {print total, n}')
	
	#read sum count <<< $(echo "$VALUES" | awk'
         #   { total += $1; n++ }
          #  END { print total, n }
        #')
        #yearly_sum=$(awk -v ys="$yearly_sum" -v s="$sum" 'BEGIN {print ys + s}')
        #yearly_count=$((yearly_count + count))
    done
    # compute yearly average
    #if [[ $yearly_count -gt 0 ]]; then
       # yearly_avg=$(awk -v sum="$yearly_sum" -v count="$yearly_count" 'BEGIN {print sum/count}')
       # echo "Yearly average for $YEAR = $yearly_avg"

        #cd ${OUTDIR}
        #echo "$yearly_avg" >> "${OUTFILE}"
    #else
        #echo "No valid data for year $YEAR"
        #echo "" >> "${OUTFILE}"
    #fi

done

    	#average
    	#AVG=$(echo "$VALUES" | awk '{ total += $1; count++ } END { print total/count }')

    	#echo "Average for year $YEAR = $AVG"
    	#cd ${OUTDIR}
    	#echo "$AVG" >> "$OUTFILE"
    	#	TRAJEC=$((TRAJEC + 1))
   	# YEAR=$((YEAR + 1))
	#done
#done
