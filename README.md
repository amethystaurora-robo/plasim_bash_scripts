These bash scripts can be used alongside PlaSim. 
plasim_simple.slurm launches an ensemble of trajectories, optimized for parallelization, with the application of a rare event algorithm.
amoc.slurm does averaging for each diagnostic file.
amoc_control_run.slurm builds text file from control run
amoc_concatted.slurm builds a text file for amoc indices across all timepoints.
amoc_monthly.slurm builds a text file monthly from control run
compress_files.slurm can be modified but works on specific compression in /data/ folder
compression.slurm can be modified to compress anything - compression takes long so it is best to have it in a bash script.
plasim*.slurm uses different values of k to run a script
resampling_amoc.py is the rare event algorithm file

