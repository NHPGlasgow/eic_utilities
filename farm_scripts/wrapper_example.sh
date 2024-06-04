#!/bin/bash

#G. Penman 2024
#new input arguments to control whether you want to use farm or local npc processing, how many runs/files/segments and then how many events per file. Default for 
if [ $# -lt 2 ]
then
    echo "Please provide a batch-mode (farm or npc) and a filebase (i.e. EpiC_18x275_ep), and optionally a number of runs/files(default = -1 for all files), and number of events per run (default = 10k)."
    exit 2
fi

batchmode=$1
filebase=$2

if [ $batchmode != "farm" ] && [ $batchmode != "npc" ]
then
    echo "Enter a valid batch option, farm or npc"
    exit 2
fi

if [ $# -gt 2 ]
then
    nruns=$3
else 
    nruns=-1
fi

if [ $# -gt 3 ]
then
    neventsim=$4
else
    neventsim=10000
fi


#Set these as appropriate to user
#In theory these lines should be the only needed changes.
#As long as this script finds data in WORK_DATA_DIR, the rest SHOULD just about work in any scenario
export WORK_DIR=/w/work5/eic/NHP_farm
export WORK_DATA_DIR=$WORK_DIR/data/$filebase
export WORK_AB_DIR=$WORK_DIR/data_afterburned/$filebase
export WORK_LOG_DIR=$WORK_DIR/logs/$filebase
export WORK_OUT_DIR=$WORK_DIR/rootfiles/$filebase
export WORK_RECON_DIR=$WORK_DIR/recon/$filebase
export WORK_RECON_LOG_DIR=$WORK_DIR/recon_logs/$filebase
export FARM_LOG_DIR=/home/$USER/ddsim_farm_logs/$filebase

export SIM_DIR=$PWD

if [[ ! -d $WORK_DATA_DIR  ||  ! -n "$(ls -A $WORK_DATA_DIR)" ]] 
then
    echo "Data directory not valid or is empty. Check filebase and paths!!"
    exit 2
fi

#makes the output directories where stuff is moved to on /work in the case that the user hasnt already
mkdir -p ${WORK_AB_DIR}
mkdir -p ${WORK_LOG_DIR}
mkdir -p ${WORK_OUT_DIR}
mkdir -p ${WORK_RECON_DIR}
mkdir -p ${WORK_RECON_LOG_DIR}
mkdir -p ${FARM_LOG_DIR}

#if you need to skip a certain number of events in a file for some reason. otherwise leave to 0 and let the below for loop do its thing
run=0
nskip=0

echo "\nSubmitting jobs for $nruns files in MC base $filebase"

#Copy this script for yourself if you need to change the syntax of the job setup based on your file structure.
#Variable NSKIP can be used to skip a given number of events each job if all data in one file for example
for file in $WORK_DATA_DIR/*.hepmc;
do
    if [[ $run -eq $nruns ]]
    then
	break;
    else
	run=$run+1
    fi
    
    #echo $file
    export WORK_FILE=$file
    
    neventsfile=$(grep -c "E " $file)
	
    if [[ $neventsim -eq -1 ]]
    then
	export NJOBS=1
	neventsim=$neventsfile
    else
	#export NJOBS=$(($neventsfile / $neventsim))
	export NJOBS=1
    fi
    
    
    export BASEFILE=${file##*/}
    export BASENAME=${BASEFILE%.hepmc}
    export STEERINGFILE=$PWD"/steering.py"

    echo "Submitting $NJOBS jobs with $neventsim events per job, for MC file: $BASEFILE"
    
    for (( job=0; job<$NJOBS; job++))
    do
	export JOBNAME="DDSIM_"$BASENAME"_"$job
	export NSKIP=$(($neventsim * $job))
	export JOB=$job
	export JUGGLER_N_EVENTS=$neventsim
	
	echo "Job: $JOB. NSKIP: $NSKIP"
	outfile=$WORK_OUT_DIR/$BASENAME"_"$JOB".edm4hep.root"
	if [ -f $outfile ]
	then
	    echo "Output files exists already. Skipping job."
	    continue
	fi

	if [ $batchmode == "farm" ]
	then
	    echo "Farming"
	    #qsub -V -q clas12 -e $FARM_LOG_DIR -o $FARM_LOG_DIR -N $JOBNAME jobexec.sh
	elif [ $batchmode == "npc" ]
	then
	    echo "npcing"
	    ./jobexec.sh &
	fi
	sleep 1
    done
done
