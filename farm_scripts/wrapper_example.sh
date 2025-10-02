#!/bin/bash

#G. Penman 2025 (updated)
#new input arguments to control whether you want to use farm or local npc processing, how many runs/files/segments and then how many events per file. Default for 
if [ $# -lt 2 ]
then
    printf "Please provide:\n1. a batch-mode (farm or npc)\n2. a filebase (i.e. EpIC_ep_DVCS_18x275).\nOptionally:\n3. a number of runs/files (default = -1 for all files)\n4. segments to split each file into (default = -1 for file total ev / 10k)\n5. number of events per segment (default=10k)\n6. first segment (default=0)\n7. config (default=18x275)\n"
    exit 2
fi

batchmode=$1
export FILEBASE=$2

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
    nseg=$4
else
    nseg=-1
fi

if [ $# -gt 4 ]
then
    nevents=$5
else
    nevents=10000
fi

if [ $# -gt 5 ]
then
    first_seg=$6
else
    first_seg=0
fi

if [ $# -gt 6 ]
then 
    config=$7
else
    config="18x275"
fi

config_list={"5x41","10x100","10x130","10x130_H2","18x275"}
if [[ !($config_list =~ $config) ]];
then
    echo "Invalid energy config"
    exit 2
fi

if [[ $config == "10x130_H2" ]]
then
    abconfig="ip6_eD_130x10"
else
    abconfig=0
fi

##need to set a temp variable here
##source setup script in container
##then set DETECTOR_CONFIG to the temp variable
export THIS_DETECTOR_CONFIG="epic_craterlake_"$config
export THIS_AB_CONFIG=$abconfig
echo "DETECTOR_CONFIG is $THIS_DETECTOR_CONFIG"
echo "AB_CONFIG is $THIS_AB_CONFIG"

#Set these as appropriate to user
#In theory these lines should be the only needed changes.
#As long as this script finds data in WORK_DATA_DIR, the rest SHOULD just about work in any scenario
export WORK_DIR=/w/work5/home/garyp/eic/Farm

export WORK_DATA_DIR=$WORK_DIR/data/$FILEBASE
export WORK_FARM_DIR=$WORK_DIR/$FILEBASE

export WORK_AB_LOG_DIR=$WORK_FARM_DIR/ab_logs
export WORK_LOG_DIR=$WORK_FARM_DIR/logs
export WORK_OUT_DIR=$WORK_FARM_DIR/rootfiles
export WORK_RECON_DIR=$WORK_FARM_DIR/recon
export WORK_RECON_LOG_DIR=$WORK_FARM_DIR/recon_logs
export FARM_LOG_DIR=/home/$USER/ddsim_farm_logs/$FILEBASE

export SIM_DIR=$PWD

if [[ ! -d $WORK_DATA_DIR  ||  ! -n "$(ls -A $WORK_DATA_DIR)" ]] 
then
    echo "Data directory not valid or is empty. Check FILEBASE and paths!!"
    exit 2
fi

#makes the output directories where stuff is moved to on /work in the case that the user hasnt already
mkdir -p ${WORK_DIR}
#mkdir -p ${WORK_AB_DIR}
mkdir -p ${WORK_AB_LOG_DIR}
mkdir -p ${WORK_OUT_DIR}
mkdir -p ${WORK_LOG_DIR}
mkdir -p ${WORK_RECON_DIR}
mkdir -p ${WORK_RECON_LOG_DIR}
mkdir -p ${FARM_LOG_DIR}


shopt -s nullglob  # Prevents unexpanded globs from being passed as literal strings

files=($WORK_DATA_DIR/*.hepmc $WORK_DATA_DIR/*.root)
nfiles=${#files[@]}
if [[ "$nruns" == "-1" || "$nruns" == "$nfiles" ]]; then
    nruns="all"
fi

echo "$nfiles file(s) exist(s) in filebase. Submitting jobs for $nruns file(s) in MC filebase $FILEBASE."

if [[ "$nruns" == "all" ]]; then
    nruns=$nfiles
fi

run=0
for file in "${files[@]}"; do
    if [[ $run -eq $nruns ]]; then
	break;
    fi
    
    run=$((run + 1))
    export WORK_FILE=$file
    export BASEFILE=${file##*/}
	    
    case "$file" in
        *.hepmc)
            echo "Processing HEPMC file: $file"
            neventsfile=$(grep -c "E " "$file")
	    basefile=${BASEFILE%.hepmc}
	    ;;
        *.root)
            echo "Processing ROOT file: $file"
            neventsfile=1000000
	    #neventsfile=$(root -l -b -q "GetEntries.C(\"$file\", \"hepmc3_tree\")" | tail -1)
	    basefile=${BASEFILE%.root}
	    ;;
        *)
            echo "Unsupported file type: $file"
            continue
            ;;
    esac

    
    # Validate that neventsfile is a number
    if ! [[ "$neventsfile" =~ ^[0-9]+$ ]]; then
        echo "Error: Could not determine number of events in $file"
        continue
    fi
    
    seg_calc=$(($neventsfile / $nevents))
    spillover=$(($neventsfile - $seg_calc * $nevents))
    seg_need=$seg_calc
    if [ $spillover -gt 0 ]
    then
	seg_need=$(($seg_need+1))
    fi
    echo "$neventsfile events in file means $seg_calc segments calculated. Remainder is $spillover therefore segments needed is $seg_need."

    #give the user exactly how many segments and events per segment 
    #that they specify
    if [[ $nseg -gt 0 ]]
    then
	echo "Doing exactly as many jobs as im told"
	export NJOBS=$nseg
	neventsim=$nevents
    #unless they set nev=-1, in which case reset njobs back to 1
    #and number events to simulate equal to total in that file
    elif [[ $nevents -eq -1 ]]
    then
	export NJOBS=1
	neventsim=$neventsfile
    #if they 
    else
	export NJOBS=$seg_need
	neventsim=$nevents
	#for testing
	#export NJOBS=1
    fi
    
    
    export STEERINGFILE=$PWD"/steering.py"

    echo "Submitting $NJOBS jobs with $neventsim events per job, for MC file: $BASEFILE"
    
    last_seg=$(($first_seg+$NJOBS))
    for (( job=$first_seg; job<$last_seg; job++))
    do
	if [ $NJOBS -eq 1 ] && [ $nevents -eq -1 ]  
	then
	    export BASENAME=$basefile
	else
	    export BASENAME=$basefile"_"$job
	fi
	
	export JOBNAME="DDSIM_"$BASENAME
	export NSKIP=$(($neventsim * $job))
	export FIRSTEVENT=$NSKIP
	export LASTEVENT=$(($NSKIP + $neventsim - 1))
	export JOB=$job
	export JUGGLER_N_EVENTS=$neventsim
	echo ""
	echo "Job: $JOB.    FIRSTEV: $FIRSTEVENT. LASTEV:  $LASTEVENT    BASENAME: $BASENAME"
	testoutfile=$WORK_RECON_DIR/$BASENAME"_recon.root"
	if [ -f $testoutfile ]
	then
	    echo "Reconstruction output file exists already. Skipping job."
	    continue
	fi

	if [ $batchmode == "farm" ]
	then
	    echo "Farming"
	    whoami
	    qsub -V -q clas12 -e $FARM_LOG_DIR -o $FARM_LOG_DIR -N $JOBNAME jobexec.sh
	elif [ $batchmode == "npc" ]
	then
	    npc_logfile=$FARM_LOG_DIR"/"$JOBNAME".log"
	    echo "npcing"
	    ./jobexec.sh 2>&1 >> $npc_logfile & 
	fi
	sleep 2
    done
done
