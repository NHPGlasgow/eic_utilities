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

echo
echo "Using local eic-shell:"
echo "/w/work5/eic/Software//eic-shell"

echo
echo "Container image:"
ls -lh /w/work5/eic/Software/local/lib/eic_xl-nightly.sif

echo
echo "Testing local container startup..."
time /w/work5/eic/Software/eic-shell -- /bin/true

rc=$?

if [ $rc -ne 0 ]; then
    echo "ERROR: container startup test failed"
    exit $rc
fi

echo "Container startup complete at $(date)"
echo

echo "Starting DDSim workflow..."
time /w/work5/eic/Software/eic-shell -- bash -lc "./${EXEC_SCRIPT} ${EXEC_ARGS}"

rc=$?

echo
echo "${EXEC_SCRIPT} exited with code $rc"
echo "Job finished at $(date)"

exit $rc
