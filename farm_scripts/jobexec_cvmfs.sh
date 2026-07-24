#!/bin/bash
#SBATCH --job-name="mytestscript"
#SBATCH --mail-type=FAIL
#SBATCH --mail-user="gary.penman@glasgow.ac.uk"
#SBATCH --export=ALL

echo "Job started at $(date) on $(hostname)"
cd "$SIM_DIR" || exit 1

echo "HOSTNAME=$(hostname)"
echo "SINGULARITY=$(which singularity)"
singularity --version

if [ ! -d /cvmfs/singularity.opensciencegrid.org ]; then
    echo "CVMFS not mounted, probing..."
    cvmfs_config probe
fi

ls /cvmfs/singularity.opensciencegrid.org/eicweb >/dev/null || {
    echo "ERROR: singularity CVMFS repo unavailable"
    exit 1
}

echo "Testing container startup..."
time singularity exec \
    --bind /w,/scratch,/home \
    /cvmfs/singularity.opensciencegrid.org/eicweb/eic_xl:26.05.0-stable \
    /bin/echo "container OK"

rc=$?

if [ $rc -ne 0 ]; then
    echo "ERROR: container startup test failed"
    exit $rc
fi

echo "Container startup complete at $(date)"

time singularity exec \
    --bind /w,/scratch \
    /cvmfs/singularity.opensciencegrid.org/eicweb/eic_xl:26.05.0-stable \
    ./ddsim.sh

rc=$?

echo "ddsim.sh exited with status $rc at $(date)"
exit $rc
