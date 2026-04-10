#!/bin/bash 
#SBATCH --job-name=plasim_test
#SBATCH --output=k20_test.out
#SBATCH --error=k20_error.err
#SBATCH --time=160:00:00
#SBATCH --ntasks-per-node=40
#SBATCH --ntasks=40
#SBATCH --nodes=1
#SBATCH --mem=50G
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=aae19@leicester.ac.uk
#SBATCH --partition=medium
#SBATCH --account=complexp
module load gcc
module load openmpi
module load cdo

#cd /scratch/complexp/aae19/PLASIM_LD/plasim/run 
#directories
#restart files which are made during this experiment
restart=/scratch/complexp/aae19/PLASIM_LD_c/plasim/run/restart
#output directory
#output=/scratch/complexp/aae19/PLASIM_LD/plasim/run/output
#run direcotry
modeldir=/scratch/complexp/aae19/PLASIM_LD-main/plasim/run
#cd $modeldir

#ensure filenames match,if matching, count total
#if diff  <(ls $rest_dir/CONTROL_360ppm_REST.[0-9][0-9][0-9][0-9].01.nc | sed 's/.*REST\.//' | sort) \
 #        <(ls $rest_dir/CONTROL_360ppm_LSGREST.[0-9][0-9][0-9][0-9].01.nc | sed 's/.*LSGREST\.//' | sort) \
  #       >/dev/null; then
   #echo "File names match"
   #N=$(ls $rest_dir/CONTROL_360ppm_REST.[0-9][0-9][0-9][0-9].[0-9][0-9] 2>/dev/null | wc -l)
#else
 #  echo "MISMATCH: filenames differ"
#fi

#divide by 100 to get evenly spaced trajectories
ntrajs=100
#step=$(( N/ntrajs ))
#echo "Total files is $N, steps between runs is $step"

#note that the number of tasks must be chosen so that SLURM_NTASKS/NPARALLEL is an integer
nparallel=4 #cores used by PLASIM
ntrajsperbatch=$((${SLURM_NTASKS}/${nparallel})) # how many trajectories each batch (different from batch on fil>
nbatches=$((${ntrajs}/${ntrajsperbatch})) # number of times you need to integrate to finish # members
#ntrajrest=$((${ntrajs}-(${nbatches}*${ntrajsperbatch}))) # trajectories in the last batch
#echo "Number of batches $nbatches"
#echo "Number of trajs per batch $ntrajsperbatch"

#handle variables
NMonths=0     # length resampling block
NDays=10       # length resampling block
LYear=360     # 
Nyears=0
#EXP=try_resampling

#variables taken in Python script at first
homedir='/data/complexp/aae19/PLASIM_LD'
expname="AMOC_resampling_50k"
expdir=${homedir}/${expname}
nameThisFile='plasim_20k.slurm'
#block is the number of times resampling is done, for 15 day resampling periods, will have 120 blocks
init_block=1
end_block=3600
varname='amoc'
#more variables for RE sampling
k=-22
echo "K value: ${k}"
dt=`echo "scale=5;${NDays}/${LYear}" | bc`
resamplingname='resampling_amoc.py'   # file that does the resampling

#add folders for Python script to read
scriptdir=`pwd`
dataexpdir=`printf '%s/data' ${expdir}` #where outputs are moved to
runexpdir=`printf '%s/run' ${expdir}`  #where executable will be kept
restexpdir=`printf '%s/rest' ${expdir}` #where restart files are saved
initexpdir=`printf '%s/init' ${expdir}` #where resampling is saved
diagexpdir=`printf '%s/diag' ${expdir}` #where diagnostic files live
postexpdir=`printf '%s/post' ${expdir}` #where AMOC stuff is run
resamplingexpdir=`printf '%s/resampling' ${expdir}` # information on how the resampling was done: contains python file with info
scriptsexpdir=`printf '%s/scripts' ${expdir}` #use this to run everything, later copy files from current directory here 
modelexpdir=`printf '%s/model' ${expdir}`

echo "expdir: ${expdir}"
mkdir -p ${expdir}
mkdir -p ${runexpdir}
mkdir -p ${restexpdir}
mkdir -p ${initexpdir}
mkdir -p ${postexpdir}
mkdir -p ${postexpdir}/ctrlobs
mkdir -p ${postexpdir}/utils
mkdir -p ${resamplingexpdir}
mkdir -p ${scriptsexpdir}
mkdir -p ${modelexpdir}
mkdir -p ${dataexpdir}
mkdir -p ${diagexpdir}

#echo "modelexpdir = '$modelexpdir'"
#echo "scriptsexpdir = '$scriptsexpdir'"

cp ${scriptdir}/${nameThisFile} ${scriptsexpdir}/${launchname}
#cp ${scriptdir}/${createinitname} ${scriptsexpdir}/${createinitname}
#cp ${scriptdir}/${organizename} ${scriptsexpdir}/${organizename}
#cp ${scriptdir}/${extractname} ${scriptsexpdir}/${extractname}
cp ${scriptdir}/${resamplingname} ${scriptsexpdir}/${resamplingname}
#find ${modeldir} -maxdepth 1 -type f | xargs -I {} cp {} ${modelexpdir}/.
launchname=`printf 'run_large_dev_%s' ${expname}`
cp ${scriptdir}/${nameThisFile} ${scriptsexpdir}/${launchname}

#I don't think this is actually necessary-would reduce number of files as well
#make folders for each trajectory
traj=1
while [ ${traj} -le ${ntrajs} ]
 do
  runtrajdir=`printf 'traj_%04d' ${traj}` 
  mkdir -p ${runexpdir}/${runtrajdir}
  cd $runexpdir/$runtrajdir
  rsync -av "${modeldir}/" .
  #cp $modeldir/mat77 .
  #cp $modeldir/kleiin1 .
  #find ${modeldir} -maxdepth 1 -type f | xargs -I {} cp {} ${runexpdir}/${runtrajdir}/. #copy everything required for run
  traj=`expr ${traj} + 1`
done

block=1
#make folders for each block (within resampling folders)
while [ ${block} -le ${end_block} ]
do
  # create folders for current block
  blockdir=`printf 'block_%04d' ${block}`
  mkdir -p ${dataexpdir}/${blockdir}
  mkdir -p ${initexpdir}/${blockdir}
  mkdir -p ${restexpdir}/${blockdir}
  mkdir -p ${diagexpdir}/${blockdir}
  mkdir -p ${resamplingexpdir}/${blockdir}
  block=`expr ${block} + 1`
done

average="-m"
srv2nc=/scratch/complexp/aae19/PLASIM-1.0_mine/scripts/srv2nc
#[ $# == 1 ] && cd $1
#rm -f plasim_restart
rm -f Abort_Message

counter_traj=1
counter_batch=1
current_batch=1

#variables for getting evenly spaced control run state variables
start_year=1001
traj=1
step=`expr 1000 / ${ntrajs}` #because 1000 years in control run, divided by number of trajs

#loop through batches
for ((block=$init_block; block<=$end_block; block++)); do
    echo "Next block ${block}"
    traj=1
    current_batch=1
    counter_batch=1
    counter_traj=1
    if [ ${block} -eq 1 ]; then
      kickres=1
    else
      kickres=1
    fi

    #make folders for blocks within resampling folders
    blockdir=`printf 'block_%04d' ${block}`
    runtrajdir=`printf 'traj_%04d' ${traj}` 
    mkdir -p ${initexpdir}/${blockdir}
    mkdir -p ${restexpdir}/${blockdir}
    mkdir -p ${resamplingexpdir}/${blockdir}
    mkdir -p ${dataexpdir}/${blockdir}
    mkdir -p ${diagexpdir}/${blockdir}

    while ((current_batch <= nbatches))
    do 
        #echo "Starting new batch..."
        #loop through ensemble
        while ((counter_traj <= ntrajsperbatch * counter_batch)); do
          #get restart file based on step size
          #idx=$(( traj * step))
	 # echo "ntrajsperbatch * counter_batch is $((ntrajsperbatch*counter_batch))"
	 # echo "counter batch is $counter_batch"
	 # echo "current batch is $current_batch"
	 #year_grabbed=$((start_year + ((counter_traj-1)*step)))
	 #echo "Year grabbed ${year_grabbed}"
         #year_fmt=$(printf "%04d" $year_grabbed)
	 # echo "traj is ${traj}"
          #get restarts from control run in first year
          if [ $block -eq $init_block ]; then
	    year_grabbed=$((start_year + ((counter_traj-1)*step)))
            echo "Year grabbed ${year_grabbed}"
            year_fmt=$(printf "%04d" $year_grabbed)
	   # echo "${block} equal to init block"
	    traj_fmt=$(printf "%04d" $traj)
            #rest_file=/data/complexp/aae19/PLASIM_LD/AMOC_resampling_200k/starters/AMOC_resampling_100k_rest.$traj_fmt.0720
	    #lsg_file=/data/complexp/aae19/PLASIM_LD/AMOC_resampling_200k/starters/AMOC_resampling_100k_lsgrest.$traj_fmt.0720
            lsg_file=$restart/CONTROL_360ppm_LSGREST.${year_fmt}.01
            rest_file=$restart/CONTROL_360ppm_REST.${year_fmt}.01
	    #echo "Kickres equal to one, first year, traj: $traj"
            echo "rest_file= '${rest_file}'"
            
          #get restarts from previous years from then on
          else
	    #echo "blockdir is ${blockdir}"
            initname=`printf '%s_init.%04d.%04d' ${expname} ${traj} ${block}` 
            lsginitname=`printf '%s_lsginit.%04d.%04d' ${expname} ${traj} ${block}` 
	    #cd $run
	    echo "Found init file called ${initname}"
            #echo "Kickres is now equal to zero"
	    
	    lsg_file=${initexpdir}/${blockdir}/${lsginitname}
	    rest_file=${initexpdir}/${blockdir}/${initname}
          fi
 	  #echo "Traj is ${traj}"
	  runtrajdir=`printf 'traj_%04d' ${traj}` 
	  cd ${runexpdir}/${runtrajdir}
	  #echo "directory is ${runtrajdir}"
          #symlink (copy restart files to working directory so PLASIM can start from them)
 
          #echo "Rest file is $rest_file"
          #echo "LSG rest file is $lsg_file" 
        
	  #cd $output/$work/$workdir
          cp "$rest_file" plasim_restart
          cp "$lsg_file" kleiin1
         
          DATANAME=`printf '%s_PLA.year%04d_traj%04d.nc' $expname $block $traj`
          OCENAME=`printf '%s_OCE.year%04d_traj%04d.nc' $expname $block $traj`
          ICENAME=`printf '%s_ICE.year%04d_traj%04d.nc' $expname $block $traj`
          LSGNAME=`printf '%s_LSG.year%04d_traj%04d.nc' $expname $block $traj`
          DIAGNAME=`printf '%s_DIAG.year%04d_traj%04d.txt' $expname $block $traj`
          RESTNAME=`printf '%s_rest.%04d.%04d' $expname $traj $block`
          LSGRESTNAME=`printf '%s_lsgrest.%04d.%04d' $expname $traj $block`
          #echo "$LSGRESTNAME created"
          #echo "$RESTNAME created"

	  # set kickres in namelist
	  #check if it matches
	  #echo "working directory:"
	  #pwd
	  #grep -n "^ *N_RUN_DAYS" plasim_namelist
	  #sed -i "s/^\( *N_DAYS_PER_YEAR *= *\).*/\1${LYear},/" plasim_namelist

          sed -i "s/^ *KICKRESTART *=.*/  KICKRESTART = ${kickres}/" plasim_namelist
	  sed -i "s/^ *N_DAYS_PER_YEAR *=.*/  N_DAYS_PER_YEAR = ${LYear}/" plasim_namelist
	  sed -i "s/^ *N_RUN_MONTHS *=.*/  N_RUN_MONTHS = ${NMonths}/" plasim_namelist
	  sed -i "s/^ *N_RUN_DAYS *=.*/  N_RUN_DAYS = ${NDays}/" plasim_namelist          
          sed -i "s/^ *N_RUN_YEARS *=.*/ N_RUN_YEARS = ${Nyears}/" plasim_namelist
	  #echo "kick parameter set"
	  #echo "kick restart = ${kickres}, days per year = ${LYear}, run days= ${NDays},run months = ${NMonths}"
          #ln -sf $modeldir/most_plasim_t21_l10_p1.x most_plasim_t21_l10_p1.x
          (mpiexec -np $nparallel ./most_plasim_t21_l10_p1.x 
          #echo "Ran model"

	  #echo "working directory:"
          #pwd
          #grep -n "^ *N_RUN_DAYS" plasim_namelist
	  
	  mv ${runexpdir}/${runtrajdir}/plasim_output ${dataexpdir}/${blockdir}/${DATANAME}
	  mv ${runexpdir}/${runtrajdir}/ice_output ${dataexpdir}/${blockdir}/${ICENAME}
	  mv ${runexpdir}/${runtrajdir}/ocean_output ${dataexpdir}/${blockdir}/${OCENAME}
	  mv ${runexpdir}/${runtrajdir}/lsg_output ${dataexpdir}/${blockdir}/${LSGNAME}
	  mv ${runexpdir}/${runtrajdir}/plasim_diag ${diagexpdir}/${blockdir}/${DIAGNAME}

	  mv ${runexpdir}/${runtrajdir}/plasim_status ${restexpdir}/${blockdir}/${RESTNAME}
	  mv ${runexpdir}/${runtrajdir}/kleiin1 ${restexpdir}/${blockdir}/${LSGRESTNAME}
	  mv ${runexpdir}/${runtrajdir}/mat77 ${restexpdir}/${blockdir}/.
	  cp ${runexpdir}/${runtrajdir}/kleiswi ${restexpdir}/${blockdir}/.) &
          #[ -e Abort_Message ] && exit 1
          #[ -e plasim_diag ] && mv plasim_diag $DIAGNAME
          #[ -e plasim_output ] && $srv2nc $average plasim_output $DATANAME
          #[ -e ocean_output ] && $srv2nc $average ocean_output $OCENAME
          #[ -e ice_output ] && $srv2nc $average ice_output $ICENAME
          #[ -e lsg_output ] && $srv2nc lsg_output $LSGNAME
          #[ -e plasim_status ] && mv plasim_status $RESTNAME
          #[ -e kleiswi ] && cp kleiswi kleiswi
          #[ -e kleiin1 ] && cp kleiin1 $LSGRESTNAME
          traj=$((traj+1))
	  counter_traj=$((counter_traj+1))
	  #echo "traj equal to ${traj}, counter traj equal to ${counter_traj}"
        done
    wait
    
    current_batch=$((current_batch+1))
    counter_batch=$((counter_batch+1))
    echo "testing if current batch updates? ${current_batch}" 
    done
#call AMOC script
 amoc_script=/scratch/complexp/aae19/amoc.slurm
 cp ${amoc_script} amoc_run.slurm
 chmod +x amoc_run.slurm
 blockdirectory=`printf '%04d' $block` 
 ./amoc_run.slurm  ${blockdirectory} ${expname}
 cd ${scriptsexpdir}
 python3 -t ${resamplingname} ${expdir} ${expname} ${ntrajs} ${block} ${varname} ${k} ${dt}
 blocklabel=`printf 'block_%04d' ${block}`
 blocknumber=`printf '%04d' ${block}`
 prevblock=`printf 'block_%04d' $((block-5))`
 #zip files to fix file limit issue
if [ $block -ge 6 ]; then
 tar -cf ${expdir}/diag/${expname}_diag_${prevblock}.tar -C ${expdir}/diag/${prevblock} .
 rm -rf ${expdir}/diag/${prevblock}
 tar -cf ${expdir}/rest/${expname}_rest_${prevblock}.tar -C ${expdir}/rest/${prevblock} .
 rm -rf ${expdir}/rest/${prevblock} 
 tar -cf ${expdir}/resampling/${expname}_resampling_${prevblock}.tar -C ${expdir}/resampling/${prevblock} .
 rm -rf ${expdir}/resampling/${prevblock}
 tar -cf ${expdir}/init/${expname}_init_${prevblock}.tar -C ${expdir}/init/${prevblock} .
 rm -rf ${expdir}/init/${prevblock}
fi
#tar -cf ${expdir}/resampling/${expname}_resampling_${blocklabel}.tar -C ${expdir}/resampling/${blocklabel} .
 #rm -rf ${expdir}/resampling/${blocklabel}
 #tar -cf ${expdir}/init/${expname}_init_${blocklabel}.tar -C ${expdir}/init/${blocklabel} .
 #rm -rf ${expdir}/init/${blocklabel}
 #tar -cf ${expdir}/rest/${expname}_rest_${blocklabel}.tar -C ${expdir}/rest/${blocklabel} .
 #rm -rf ${expdir}/rest/${blocklabel}
 tar -cf ${expdir}/data/${expname}_data_${blocklabel}.tar -C ${expdir}/data/${blocklabel} .
 #rm -rf ${expdir}/data/${blocklabel}/*.${blocknumber}
 rm -rf ${expdir}/data/${blocklabel}
done
./amoc_concatted.slurm ${expname}
tar -cf ${expdir}.tar -c ${expdir}
