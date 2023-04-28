#!/bin/bash

#Set these as appropriate to user
#In theory these lines should be the only needed changes.
export WORK_DIR=/w/work5/eic/NHP_test
export WORK_DATA_DIR=$WORK_DIR/data
export WORK_LOG_DIR=$WORK_DIR/logs
export WORK_OUT_DIR=$WORK_DIR/rootfiles
export NEVENTS=10

export FARM_LOG_DIR=/home/$USER/ddsim_farm_logs

export SIM_DIR=$PWD

if [ ! -d $WORK_DATA_DIR ];
then
    echo "Data directory not valid. Check Paths"
    exit 2
fi

mkdir -p ${WORK_LOG_DIR}
mkdir -p ${WORK_OUT_DIR}
mkdir -p ${FARM_LOG_DIR}

run=0

#Copy this script for yourself if you need to change the syntax of the job setup based on your file structure.
#Variable NSKIP can be used to skip a given number of events each job if all data in one file for example
for file in $WORK_DATA_DIR/*;
do
    #echo $file
    export WORK_FILE=$file

    basefile=${file##*/}
    export BASEFILE=$basefile
    base=${basefile%.hepmc}
    export BASENAME=$base

    jobName="EPIC_"$base"_"$run
    export JOBNAME=$jobName

    export RUN=$run
    export JUGGLER_N_EVENTS=$NEVENTS
    
    echo "Submitting simulation job $RUN. File: $basefile"
    qsub -V -q clas12 -e $FARM_LOG_DIR -o $FARM_LOG_DIR -N $jobName jobexec.sh
    #./jobexec.sh &
    run=$(( $run+1 ))
    sleep 2
done
