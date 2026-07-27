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

echo "HOSTNAME=$(hostname)"
echo "SINGULARITY=$(/usr/bin/which singularity)"
singularity --version

SOFTWARE_DIR="/w/work5/eic/Software/"

echo
echo "Using local eic-shell:"
echo "${SOFTWARE_DIR}l"

#echo
#echo "Container image:"
#ls -lh ${SOFTARE_DIR}/local/lib/eic_xl-nightly.sif

echo
echo "Testing local container startup..."
time ${SOFTWARE_DIR}/eic-shell -- /bin/true

rc=$?

if [ $rc -ne 0 ]; then
    echo "ERROR: container startup test failed"
    exit $rc
fi

echo "Container startup complete at $(date)"
echo

echo "Starting DDSim workflow..."
time ${SOFTWARE_DIR}/eic-shell -- bash -c "./${EXEC_SCRIPT} ${EXEC_ARGS}"

rc=$?

echo
echo "${EXEC_SCRIPT} exited with code $rc"
echo "Job finished at $(date)"

exit $rc
