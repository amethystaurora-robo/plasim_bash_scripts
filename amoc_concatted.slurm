#!/bin/bash

#go to directory of files
file_direct=/scratch/complexp/aae19/PLASIM_LD/AMOC_resampling_Matteo/post/ctrlobs
block_one=1
block_two=100
traj_one=1
traj_two=100

#values for saving file
mkdir -p concatted
concatted_amoc=${file_direct}/concatted_Matteo.txt
save_directory=/scratch/complexp/aae19/concatted
echo "Trajectory,Block,AMOC_Index" > ${concatted_amoc}
echo "File created"

cd ${file_direct}

#loop through all files
for ((traj=$traj_one; traj<=$traj_two; traj++)); do
	for ((block=$block_one; block<=$block_two; block++)); do

		FILENAME=$(printf "AMOC_resampling_Matteo_ctrlobs.%04d.%04d.txt"  "$((10#$traj))" "$((10#$block))")	 
		echo "Into file ${FILENAME}"
		#value=$(cat ${FILENAME})
		value=$(head -n 1 "${FILENAME}")
		echo ${traj},${block},${value} >> ${concatted_amoc}		
		echo "Added block ${block} to file"
		
	done
done
