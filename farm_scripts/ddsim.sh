#!/bin/bash

source /opt/detector/epic-nightly/setup.sh

tempdir=/scratch/$USER/ddsim_$RUN
mkdir -p ${tempdir}

datadir=${tempdir}/data
logdir=${tempdir}/logs
outdir=${tempdir}/rootfiles

mkdir -p ${datadir}
mkdir -p ${logdir}
mkdir -p ${outdir}

cp $WORK_FILE $datadir

datafile=$datadir/$BASEFILE
outfile=$outdir/$BASENAME.edm4hep.root
logfile=$logdir/$BASENAME.log

export JUGGLER_MC_FILE=$datafile
export JUGGLER_SIM_FILE=$outfile
    
nohup ddsim --steeringFile steering.py \
    --numberOfEvents ${JUGGLER_N_EVENTS} \
    --compactFile ${DETECTOR_PATH}/${DETECTOR_CONFIG}.xml \
    --inputFiles ${JUGGLER_MC_FILE}  \
    --outputFile  ${JUGGLER_SIM_FILE} \
    >> $logfile 2>&1

#clean up
mv $JUGGLER_SIM_FILE $WORK_OUT_DIR
mv $logfile $WORK_LOG_DIR
rm $datafile
rmdir $datadir $logdir $outdir
rmdir $tempdir

echo "Simulation $RUN $SEG complete!"
