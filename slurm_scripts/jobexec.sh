#!/bin/bash
#SBATCH --job-name="mytestscript"
#SBATCH --mail-type=FAIL
#SBATCH --mail-user="gary.penman@glasgow.ac.uk"
#SBATCH --export=ALL

#PBS -V

echo "Job started at $(date) on $(hostname)"
cd $SIM_DIR

if [ ! -d /cvmfs/singularity.opensciencegrid.org ]; then
  echo "CVMFS not mounted, probing..."
  cvmfs_config probe
fi

#singularity exec --bind /w,/scratch /cvmfs/singularity.opensciencegrid.org/eicweb/eic_xl:nightly ./ddsim.sh

singularity exec --bind /w,/scratch /cvmfs/singularity.opensciencegrid.org/eicweb/eic_xl:26.05.0-stable ./ddsim.sh
