These bash scripts can be used alongside PlaSim. 
- `plasim_simple.slurm` — launches an ensemble of trajectories, optimized for parallelization, with a rare event algorithm  
- `amoc.slurm` — performs averaging for each diagnostic file  
- `amoc_control_run.slurm` — builds a text file from control run  
- `amoc_concatted.slurm` — builds a text file for AMOC indices across all timepoints  
- `amoc_monthly.slurm` — builds a monthly text file from control run  
- `compress_files.slurm` — compresses specific files in `/data/` (modifiable)  
- `compression.slurm` — general-purpose compression script (recommended for long jobs)  
- `plasim*.slurm` — runs scripts with different values of *k*  
- `resampling_amoc.py` — implementation of the rare event algorithm
- `unpack_files.slurm`- de-compress files for binary output
- `make_outputs.slurm`- fix problem with binary output in plasim_* scripts
-  `traj_updated.slurm`- make variable selections using cdo

