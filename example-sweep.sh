#!/bin/bash

export WORKLOAD_NAME=EXAMPLE-SWEEP
export WORKLOAD_DIR="."
export ESTIMATED_RUN_TIME_MIN=1
export X_LABEL="Block size [ KB ]"

# When sweeping, collect all files in the same run directory
export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)

for BLOCK_SIZE_KB in 128 256 512
do
    for ITER in 1 2
    do
	    export RUN_ID="BLOCK_SIZE_KB=$BLOCK_SIZE_KB.$ITER"
	    export WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=${BLOCK_SIZE_KB}k count=1024 oflag=direct"
	    ./run-workload.sh
    done
done

