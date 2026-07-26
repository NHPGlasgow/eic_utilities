#!/bin/bash

N=100
MAX_JOBS=10

pids=()

for ((i=0; i<N; i++)); do

    echo "Launching segment $i"
    ./MergeAndRecon.sh $i &
    
    # store PID of this job
    pids+=($!)

    # --- throttle ---
    while (( ${#pids[@]} >= MAX_JOBS )); do
        # wait for any job to finish
        wait -n

        # clean up finished PIDs
        new_pids=()
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                new_pids+=($pid)
            fi
        done
        pids=("${new_pids[@]}")
    done

done

wait
echo "All segments finished."

