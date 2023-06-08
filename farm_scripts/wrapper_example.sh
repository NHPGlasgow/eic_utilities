#!/bin/bash

#G. Penman 2023
#Set these as appropriate to user
#In theory these lines should be the only needed changes.
#As long as this script finds data in WORK_DATA_DIR, the rest SHOULD just about work in any scenario
export WORK_DIR=/w/work5/eic/NHP_test
export WORK_DATA_DIR=$WORK_DIR/data
export WORK_LOG_DIR=$WORK_DIR/logs
export WORK_OUT_DIR=$WORK_DIR/rootfiles
export WORK_RECON_DIR=$WORK_DIR/recon
export FARM_LOG_DIR=/home/$USER/ddsim_farm_logs

export SIM_DIR=$PWD

if [ ! -d $WORK_DATA_DIR ]
then
    echo "Data directory not valid. Check Paths"
    exit 2
fi

#makes the output directories where stuff is moved to on /work in the case that the user hasnt already
mkdir -p ${WORK_LOG_DIR}
mkdir -p ${WORK_OUT_DIR}
mkdir -p ${WORK_RECON_DIR}
mkdir -p ${FARM_LOG_DIR}

#if you need to skip a certain number of events in a file for some reason. otherwise leave to 0 and let the below for loop do its thing
nskip=0
#total number of events you want to simulate PER DATA FILE (leave small for testing scripts)
neventstotal=10
#number of events per job. recommend keep below 10000 per job.
neventsim=10

#Copy this script for yourself if you need to change the syntax of the job setup based on your file structure.
#Variable NSKIP can be used to skip a given number of events each job if all data in one file for example
for file in $WORK_DATA_DIR/EpiC_18x275_ep_0.hepmc*;
do
    export WORK_FILE=$file
    if [ neventstotal == -1 ]
    then
	export NEVENTS=$(grep -c "E " $file)
    else
	export NEVENTS=$neventstotal
    fi
    
    njobs=$(($NEVENTS / $neventsim))
    
    export BASEFILE=${file##*/}
    export BASENAME=${BASEFILE%.hepmc}

    echo "Submitting $nevents events in  $njobs jobs for MC base: $BASENAME"
    
    for (( job=0; job<$njobs; job++))
    do

	export JOBNAME="EPIC_"$BASENAME"_"$job
	export NSKIP=$(($neventsim * $job))
	export JOB=$job
	export JUGGLER_N_EVENTS=$NEVENTS
	
	echo "Job: $JOB. NSKIP: $NSKIP"
	outfile=$WORK_OUT_DIR/$BASENAME"_"$JOB".edm4hep.root"
	if [ -f $outfile ]
	then
	    echo "Output files exists already. Skipping job."
	    continue
	fi
	qsub -V -q clas12 -e $FARM_LOG_DIR -o $FARM_LOG_DIR -N $JOBNAME jobexec.sh
	#./jobexec.sh &
	#run=$(( $run+1 ))
	sleep 5
    done
done
