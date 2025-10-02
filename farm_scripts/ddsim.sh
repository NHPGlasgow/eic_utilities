#!/bin/bash

#echo "Job started at $(date) on $(hostname)"

source /opt/detector/epic-main/bin/thisepic.sh
#source /opt/detector/epic-25.05.0/bin/thisepic.sh
source /opt/local/bin/eicrecon-this.sh

export DETECTOR_CONFIG=$THIS_DETECTOR_CONFIG
export DETECTOR_PATH_NAME="$DETECTOR_PATH/$DETECTOR_CONFIG.xml"

tempdir=/scratch/$USER/$FILEBASE"_"$JOB
mkdir -p ${tempdir}
cd $tempdir
cp $STEERINGFILE $tempdir

datafile=$WORK_FILE
ABoutfile=$tempdir"/AB_"$BASENAME
ablogfile=$ABoutfile.log

if [[ ! -f $ABoutfile ]]
then
    #if afterburned segment doesnt exist in correct place, do it
    #echo "No afterburned datafile for Segment/Run $JOB, running afterburner" 
    abconv -p $THIS_AB_CONFIG -s $FIRSTEVENT -e $LASTEVENT --plot-off $datafile -o $ABoutfile >> $ablogfile 2>&1
fi

echo "AB complete at $(date) on $(hostname)"

outfile=$tempdir"/"$BASENAME".edm4hep.root"
logfile=$tempdir"/"$BASENAME".log"
reconfile=$tempdir"/"$BASENAME"_recon.root"
reconlogfile=$tempdir"/"$BASENAME"_recon.log"


##setup simulation input output based on AB output
export JUGGLER_MC_FILE=$ABoutfile".hepmc"
export JUGGLER_SIM_FILE=$outfile

export FULL_SIM_FILE=$WORK_OUT_DIR"/"$BASENAME".edm4hep.root"

#if [[ ! -f $FULL_SIM_FILE ]]
#then
#    echo "Simulation segment doesnt exist on workdiscs, simulating!"
    #do simulation
    ddsim --steeringFile steering.py \
	--numberOfEvents ${JUGGLER_N_EVENTS} \
	--compactFile ${DETECTOR_PATH_NAME} \
	--inputFiles ${JUGGLER_MC_FILE}  \
	--outputFile  ${JUGGLER_SIM_FILE} >> $logfile 2>&1
#else
#    echo "Simulation segment exists on workdiscs, copying!"
#    cp $FULL_SIM_FILE $tempdir
#fi
echo "Simulation complete at $(date) on $(hostname)"

#do reconstruction
eicrecon -Pdd4hep:xml_files=${DETECTOR_PATH_NAME} $JUGGLER_SIM_FILE >> $reconlogfile 2>&1

echo "Reconstruction complete at $(date) on $(hostname)"

mv podio_output.root $reconfile
mv $reconfile $WORK_RECON_DIR
mv $JUGGLER_SIM_FILE $WORK_OUT_DIR
mv $logfile $WORK_LOG_DIR
mv $reconlogfile $WORK_RECON_LOG_DIR
mv $ablogfile $WORK_AB_LOG_DIR
cd
rm -rf $tempdir

echo "Job $BASENAME $SEG complete at $(date) on $(hostname)!"
