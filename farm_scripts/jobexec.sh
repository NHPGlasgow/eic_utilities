#!/bin/bash
#PBS -V 
#PBS -l walltime=48:00:00,file=200000000kb

echo "Job started at $(date) on $(hostname)"
cd $SIM_DIR

if [ ! -d /cvmfs/singularity.opensciencegrid.org ]; then
  echo "CVMFS not mounted, probing..."
  cvmfs_config probe
fi

#singularity exec --bind /w,/scratch /cvmfs/singularity.opensciencegrid.org/eicweb/eic_xl:nightly ./ddsim.sh

singularity exec --bind /w,/scratch /cvmfs/singularity.opensciencegrid.org/eicweb/eic_xl:25.08.0-stable ./ddsim.sh
#singularity exec --bind /w,/scratch /cvmfs/singularity.opensciencegrid.org/eicweb/eic_xl:25.07-stable ./ddsim.sh
#singularity exec --bind /w,/scratch /cvmfs/singularity.opensciencegrid.org/eicweb/eic_xl:25.06.1-stable ./ddsim.sh
