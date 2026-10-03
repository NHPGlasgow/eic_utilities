#!/bin/bash
#SBATCH --job-name="mytestscript"
#SBATCH --mail-type=FAIL
#SBATCH --mail-user="gary.penman@glasgow.ac.uk"
#SBATCH --export=ALL

set -e

echo "============================================================"
echo "Job started at $(date) on $(hostname)"
echo "============================================================"

cd "$SIM_DIR" || {
    echo "ERROR: Cannot cd to SIM_DIR=$SIM_DIR"
    exit 1
}

if [[ -z "$EXEC_SCRIPT" ]]; then
    echo "ERROR: EXEC_SCRIPT not set"
    exit 1
fi

LOCAL_SIF="/w/work6/home/gp140f/eic/local/lib/eic_xl-26.07.1-stable.sif"

echo "HOSTNAME=$(hostname)"
echo "SINGULARITY=$(/usr/bin/which singularity)"
singularity --version

echo "LOCAL_SIF=$LOCAL_SIF"

if [[ ! -f "$LOCAL_SIF" ]]; then
    echo "ERROR: Missing SIF image"
    exit 1
fi

echo "EXEC_SCRIPT=$EXEC_SCRIPT"
echo "EXEC_ARGS=$EXEC_ARGS"

echo
echo "Testing container startup..."

time singularity exec \
    --bind /cvmfs,/scratch1,/media,/w \
    "$LOCAL_SIF" \
    /bin/true

echo "Container startup complete at $(date)"
echo

echo "Starting DDSim workflow..."

time singularity exec \
    --bind /cvmfs,/scratch1,/media,/w \
    "$LOCAL_SIF" \
    "$EXEC_SCRIPT" $EXEC_ARGS

rc=$?

echo
echo "$EXEC_SCRIPT exited with code $rc"
echo "Job finished at $(date)"

exit $rc
