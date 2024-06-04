#!/bin/bash

#echo "Job started at $(date) on $(hostname)"

source /opt/detector/epic-main/bin/thisepic.sh
source /opt/local/bin/eicrecon-this.sh

tempdir=/scratch/$USER/ddsim_$BASENAME"_"$JOB
mkdir -p ${tempdir}
cd $tempdir
cp $STEERINGFILE $tempdir

#datadir=${tempdir}/data
#logdir=${tempdir}/logs
#outdir=${tempdir}/rootfiles

#mkdir -p ${datadir}
#mkdir -p ${logdir}
#mkdir -p ${outdir}

#cp $WORK_FILE $datadir

#datafile=$datadir/$BASEFILE
datafile=$WORK_FILE
ABoutfile=$WORK_AB_DIR/AB_$BASENAME"_"$JOB.hepmc
if [[ ! -f $ABoutfile ]]
then
    #if afterburned segment doesnt exist in correct place, do it
    echo "No afterburned datafile for Segment/Run $JOB, running afterburner" 
    abconv -p 1 -s 0 -l -1 --plot-off $datafile -o $ABoutfile
fi

outfile=$tempdir/$BASENAME"_"$JOB.edm4hep.root
logfile=$tempdir/$BASENAME"_"$JOB.log
reconfile=$tempdir/$BASENAME"_"$JOB"_recon.root"
reconlogfile=$tempdir/$BASENAME"_"$JOB"_recon.log"


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

#rm $datafile
#rmdir $datadir $logdir $outdir
cd
#rm -rf $tempdir

echo "Simulation job $BASENAME $SEG complete at $(date) on $(hostname)!"
