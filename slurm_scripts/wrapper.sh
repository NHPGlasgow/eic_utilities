#!/usr/bin/env bash
#set -euo pipefail


# -------------------------------
# Usage function
# -------------------------------
usage() {
cat << EOF
Usage:
  $0 <batchmode> <input> [options]

Required:
  batchmode        farm | npc
  input            file or directory

Optional:
  nruns            number of files
  nseg             number of segments
  nevents          events per segment
  first_seg        starting segment
  abconfig         abconv config
  outdir           output directory
EOF
exit 1
}



# -------------------------------
# Detector Config function
# -------------------------------
extract_detector_config() {
    local ab="$1"

    # Strip prefix
    local base=${ab#ip6_*_}

    # Handle formats:
    # 130x9
    # 275_9_hiacc

    if [[ "$base" =~ ^([0-9]+)x([0-9]+)$ ]]; then
        p=${BASH_REMATCH[1]}
        e=${BASH_REMATCH[2]}
    elif [[ "$base" =~ ^([0-9]+)_([0-9]+) ]]; then
        p=${BASH_REMATCH[1]}
        e=${BASH_REMATCH[2]}
    else
        echo "ERROR: Cannot parse abconfig: $ab"
        exit 2
    fi

    echo "${e}x${p}"
}


# -------------------------------
# Args
# -------------------------------
[[ $# -lt 2 ]] && usage

batchmode=$1
input=$2
nruns=${3:--1}
nseg=${4:--1}
nevents=${5:-10000}
first_seg=${6:-0}
abconfig=${7:-"0"}
outdir=${8:-"$PWD/output"}

# -------------------------------
# Validate batch mode
# -------------------------------
if [[ "$batchmode" != "farm" && "$batchmode" != "npc" && "$batchmode" != "dry" ]]; then
    echo "ERROR: batchmode must be 'farm', 'npc', or 'dry'"
    exit 2
fi


if [[ "$batchmode" == "dry" ]]; then
    echo "======================================="
    echo " DRY RUN MODE (no jobs will be run)"
    echo "======================================="
fi

# -------------------------------
# Validate config
# -------------------------------
#VALID_CONFIGS=("5x41" "10x100" "10x130" "10x130_H2" "18x275")

#if [[ ! " ${VALID_CONFIGS[*]} " =~ " ${config} " ]]; then
#    echo "ERROR: invalid config '$config'"
#    exit 2
#fi

config=$(extract_detector_config "$abconfig")
export THIS_DETECTOR_CONFIG="epic_craterlake_${config}"
export THIS_AB_CONFIG="$abconfig"

echo "DETECTOR_CONFIG: $THIS_DETECTOR_CONFIG"
echo "AB_CONFIG:       $THIS_AB_CONFIG"

# -------------------------------
# Resolve input files
# -------------------------------
declare -a files

if [[ -f "$input" ]]; then
    files=("$input")
    #FILEBASE=$(basename "$input")
elif [[ -d "$input" ]]; then
    #FILEBASE=$(basename "$input")
    shopt -s nullglob
    files=("$input"/*.hepmc "$input"/*.root)
else
    echo "ERROR: input must be a file or directory"
    exit 2
fi

nfiles=${#files[@]}
[[ $nfiles -eq 0 ]] && { echo "ERROR: no input files found"; exit 2; }

# Limit nruns
if [[ "$nruns" == "-1" || "$nruns" -gt "$nfiles" ]]; then
    nruns=$nfiles
fi

echo "Found $nfiles files, processing $nruns"

# -------------------------------
# Directories (fully configurable)
# -------------------------------
WORK_DIR=$(realpath "$outdir")
export WORK_DIR

export WORK_OUT_DIR="$WORK_DIR/rootfiles"
export WORK_RECON_DIR="$WORK_DIR/recon"
export WORK_LOG_DIR="$WORK_DIR/logs"
export WORK_AB_LOG_DIR="$WORK_DIR/ab_logs"
export FARM_LOG_DIR="$WORK_DIR/farm_logs"

mkdir -p "$WORK_OUT_DIR" "$WORK_RECON_DIR" "$WORK_LOG_DIR" "$WORK_AB_LOG_DIR" "$FARM_LOG_DIR"

export SIM_DIR=$PWD
export STEERINGFILE="$PWD/steering.py"

# -------------------------------
# Loop over input files
# -------------------------------
run=0
for file in "${files[@]}"; do

    (( run++ ))
    [[ $run -gt $nruns ]] && break

    export WORK_FILE="$file"
    BASEFILE=$(basename "$file")
    echo "TEST"
    case "$file" in
        *.hepmc)
            echo "Processing HEPMC: $file"
            neventsfile=$(grep -c "^E " "$file")
            basefile=${BASEFILE%.hepmc}
            ;;
	
	*.hepmc3.tree.root)
            echo "Processing HEPMC3 ROOT: $file"
            neventsfile=1000000   # fallback (or replace with proper counter later)
            basefile=${BASEFILE%.hepmc3.tree.root}
            ;;
	
	*.root)
            echo "Processing ROOT: $file"
            neventsfile=1000000   # fallback
            basefile=${BASEFILE%.root}
            ;;
        *)
            echo "Skipping unsupported: $file"
            continue
            ;;
    esac

    [[ ! "$neventsfile" =~ ^[0-9]+$ ]] && {
        echo "ERROR: invalid event count"
        continue
    }

    # -------------------------------
    # Segment calculation
    # -------------------------------
    seg_calc=$(( neventsfile / nevents ))
    spill=$(( neventsfile % nevents ))

    seg_need=$seg_calc
    [[ $spill -gt 0 ]] && ((seg_need++))

    if [[ $nseg -gt 0 ]]; then
        NJOBS=$nseg
        neventsim=$nevents
    elif [[ $nevents -eq -1 ]]; then
        NJOBS=1
        neventsim=$neventsfile
    else
        NJOBS=$seg_need
        neventsim=$nevents
    fi

    echo "File: $BASEFILE ? $NJOBS jobs × $neventsim events"

    last_seg=$(( first_seg + NJOBS ))

    for (( job=first_seg; job<last_seg; job++ )); do

        if [[ $NJOBS -eq 1 && $nevents -eq -1 ]]; then
            BASENAME=$basefile
        else
            BASENAME="${basefile}_${job}"
        fi

        export BASENAME
	export JOB=$job
	export JOBNAME="DDSIM_${BASENAME}"
        export NSKIP=$(( neventsim * job ))
        export FIRSTEVENT=$NSKIP
        export LASTEVENT=$(( NSKIP + neventsim - 1 ))
        export JUGGLER_N_EVENTS=$neventsim

        outfile="$WORK_RECON_DIR/${BASENAME}_recon.root"

        echo "Job $job ? events [$FIRSTEVENT:$LASTEVENT]"

        if [[ -f "$outfile" ]]; then
            echo "Skipping (output exists)"
            continue
        fi

        if [[ "$batchmode" == "farm" ]]; then
            sbatch \
              -J "$JOBNAME" \
              -o "$FARM_LOG_DIR/${JOBNAME}_out.log" \
              -e "$FARM_LOG_DIR/${JOBNAME}_err.log" \
              jobexec.sh
        elif [[ "$batchmode" == "npc" ]]; then
	    echo "[NPC] Running $JOBNAME locally"
	    ./jobexec.sh >> "$FARM_LOG_DIR/${JOBNAME}.log" 2>&1 &
	elif [[ "$batchmode" == "dry" ]]; then
	    echo "[DRY RUN] Would execute job:"
	    echo "  JOBNAME     = $JOBNAME"
	    echo "  INPUT       = $WORK_FILE"
	    echo "  BASENAME    = $BASENAME"
	    echo "  FIRSTEVENT  = $FIRSTEVENT"
	    echo "  LASTEVENT   = $LASTEVENT"
	    echo "  NEVENTS     = $JUGGLER_N_EVENTS"
	    echo "  OUTPUT      = $WORK_RECON_DIR/${BASENAME}_recon.root"
	fi
        sleep 1
    done

done
