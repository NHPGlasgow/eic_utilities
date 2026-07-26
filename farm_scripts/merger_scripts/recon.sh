#!/bin/bash

# --- Environment setup ---
source /opt/detector/epic-main/bin/thisepic.sh
source /opt/local/bin/eicrecon-this.sh

config="9x130"
export DETECTOR_CONFIG="epic_craterlake_${config}"
export DETECTOR_PATH_NAME="${DETECTOR_PATH}/${DETECTOR_CONFIG}.xml"

JUGGLER_SIM_FILE="/w/work6/home/gp140f/tcs_bg_merge/test_merged_100k_TCS.edm4hep.root"

WORKDIR="/w/work6/home/gp140f/tcs_bg_merge/"
cd "${WORKDIR}" || exit 1

# --- Reconstruction settings ---
EVENTS_PER_SEG=10000
N_SEGMENTS=10

# --- Loop over segments ---
for ((i=0; i<${N_SEGMENTS}; i++)); do
    SKIP_EVENTS=$((i * EVENTS_PER_SEG))

    OUTFILE="reco_seg_${i}.root"
    LOGFILE="reco_seg_${i}.log"
    INPUT_FILE="/w/work6/home/gp140f/tcs_bg_merge/chunk_${i}.root"
    echo "Processing segment ${i}: nevents=${EVENTS_PER_SEG}"

    eicrecon \
        -Pjana:nevents=${EVENTS_PER_SEG} \
        -Pdd4hep:xml_files="${DETECTOR_PATH_NAME}" \
        "${INPUT_FILE}" \
        -Ppodio:output_file="${OUTFILE}" \
        >> "${LOGFILE}" 2>&1 &

done

echo "All segments processed."
