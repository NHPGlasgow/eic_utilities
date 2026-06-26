#!/bin/bash

source /opt/detector/epic-main/bin/thisepic.sh
source /opt/local/bin/eicrecon-this.sh

export DETECTOR_CONFIG=$THIS_DETECTOR_CONFIG
export DETECTOR_PATH_NAME="$DETECTOR_PATH/$DETECTOR_CONFIG.xml"


# Default behaviour if not set
RUN_SIM=${RUN_SIM:-1}
RUN_RECON=${RUN_RECON:-1}

echo "ddsim.sh configuration:"
echo "  RUN_SIM   = $RUN_SIM"
echo "  RUN_RECON = $RUN_RECON"

tempdir=/scratch/$USER/$JOBNAME
mkdir -p ${tempdir}
cd $tempdir
cp $STEERINGFILE $tempdir

datafile=$WORK_FILE
ABoutfile=$tempdir"/AB_"$BASENAME
ablogfile=$ABoutfile.log

outfile=$tempdir"/"$BASENAME".edm4hep.root"
logfile=$tempdir"/"$BASENAME".log"
reconfile=$tempdir"/"$BASENAME"_recon.root"
reconlogfile=$tempdir"/"$BASENAME"_recon.log"

# Setup simulation input output based on AB output
export JUGGLER_MC_FILE=$ABoutfile".hepmc3.tree.root"
export JUGGLER_SIM_FILE=$outfile
export FULL_SIM_FILE=$WORK_OUT_DIR"/"$BASENAME".edm4hep.root"

if [[ "$RUN_SIM" -eq 1 ]]; then

    if [[ ! -f $ABoutfile ]]
    then
	abconv -p $THIS_AB_CONFIG -s $FIRSTEVENT -e $LASTEVENT --plot-off $datafile -o $ABoutfile >> $ablogfile 2>&1
	echo "AB complete at $(date) on $(hostname)"
    fi
    
    echo "Running simulation stage"
    ddsim --steeringFile steering.py \
	  --numberOfEvents ${JUGGLER_N_EVENTS} \
	--compactFile ${DETECTOR_PATH_NAME} \
	--inputFiles ${JUGGLER_MC_FILE}  \
	--outputFile  ${JUGGLER_SIM_FILE} >> $logfile 2>&1

    echo "Simulation complete at $(date) on $(hostname)"
else
    echo "Skipping simulation stage"
fi


if [[ "$RUN_RECON" -eq 1 ]]; then
    if [[ "$RUN_SIM" -eq 0 ]]; then
	if [[ -f "$FULL_SIM_FILE" ]]; then
	    echo "Recon-only mode, copying sim file from disk"
	    cp $FULL_SIM_FILE $JUGGLER_SIM_FILE
	elif [[ -f "$JUGGLER_SIM_FILE" ]]; then
	    echo "Sim file missing on disk, using local version"
	else
	    echo "Sim file missing from temp working dir AND disk, aborting recon!"
	    
	fi
    fi
    echo "Running reconstruction stage"
    eicrecon -Pdd4hep:xml_files=${DETECTOR_PATH_NAME} $JUGGLER_SIM_FILE >> $reconlogfile 2>&1

    echo "Reconstruction complete at $(date) on $(hostname)"
else
    echo "Skipping reconstruction stage"
fi


# --- Move outputs safely ---

if [[ -f "podio_output.root" ]]; then
    mv "podio_output.root" "$reconfile"
else
    echo "WARNING: podio_output.root not found"
fi

if [[ -f "$reconfile" ]]; then
    mv "$reconfile" "$WORK_RECON_DIR"
else
    echo "WARNING: recon file missing, not moving"
fi

if [[ -f "$JUGGLER_SIM_FILE" ]]; then
    mv "$JUGGLER_SIM_FILE" "$WORK_OUT_DIR"
else
    echo "INFO: no sim file to move (might be recon-only)"
fi

if [[ -f "$logfile" ]]; then
    mv "$logfile" "$WORK_LOG_DIR"
fi

if [[ -f "$reconlogfile" ]]; then
    mv "$reconlogfile" "$WORK_RECON_LOG_DIR"
fi

if [[ -f "$ablogfile" ]]; then
    mv "$ablogfile" "$WORK_AB_LOG_DIR"
fi

# --- Cleanup ---
cd /
rm -rf "$tempdir"

echo "Job $BASENAME (job $JOB) complete at $(date) on $(hostname)!"
echo "Job $BASENAME $JOB complete at $(date) on $(hostname)!"
