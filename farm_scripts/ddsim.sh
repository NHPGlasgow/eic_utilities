#!/bin/bash

#echo "Job started at $(date) on $(hostname)"

source /opt/detector/epic-nightly/setup.sh
source 
tempdir=/scratch/$USER/ddsim_$BASENAME"_"$JOB
mkdir -p ${tempdir}
cd $tempdir

datadir=${tempdir}/data
logdir=${tempdir}/logs
outdir=${tempdir}/rootfiles

mkdir -p ${datadir}
mkdir -p ${logdir}
mkdir -p ${outdir}

#cp $WORK_FILE $datadir

datafile=$datadir/$BASEFILE
ABoutfile=$WORK_AB_DIR/AB_$BASENAME"_"$JOB.edm4hep.root
if [[ ! -f $ABoutfile ]]
then
    #if afterburned segment doesnt exist in correct place, do it
    abconv -p 1 -s $firstevent -l $nevent --plot-off $datafile -o $ABoutfile
fi

outfile=$outdir/$BASENAME"_"$JOB.edm4hep.root
logfile=$logdir/$BASENAME"_"$JOB.log
reconfile=$outdir/$BASENAME"_"$JOB"_recon.root"
reconlogfile=$logdir/$BASENAME"_"$JOB"_recon.log"


##setup simulation input output based on AB output
export JUGGLER_MC_FILE=$ABoutfile
export JUGGLER_SIM_FILE=$outfile

#do simulation
ddsim --steeringFile steering.py \
    --numberOfEvents ${JUGGLER_N_EVENTS} \
    --compactFile ${DETECTOR_PATH}/${DETECTOR_CONFIG}.xml \
    --inputFiles ${JUGGLER_MC_FILE}  \
    --outputFile  ${JUGGLER_SIM_FILE} \
    -v 'WARNING' \
    >> $logfile 2>&1

#do reconstruction
eicrecon $JUGGLER_SIM_FILE >> $reconlogfile 2>&1

mv podio_output.root $reconfile
mv $reconfile $WORK_RECON_DIR
mv $JUGGLER_SIM_FILE $WORK_OUT_DIR
mv $logfile $WORK_LOG_DIR
mv $reconlogfile $WORK_RECON_LOG_DIR

rm $datafile
rmdir $datadir $logdir $outdir
cd
rm -rf $tempdir

echo "Simulation job $BASENAME $SEG complete at $(date) on $(hostname)!"
