#!/bin/bash
#PBS -N EPIC
#PBS -V 
#PBS -l walltime=24:00:00,file=200000000kb

echo "Job started at $(date) on $(hostname)"

cd $SIM_DIR
cvmfs_config probe
singularity exec --bind /w,/scratch /cvmfs/singularity.opensciencegrid.org/eicweb/jug_xl:nightly ./ddsim.sh
