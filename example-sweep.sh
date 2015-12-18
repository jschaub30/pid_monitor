#!/bin/bash

export WORKLOAD_NAME=EXAMPLE-SWEEP
export DESCRIPTION="Example sweep using dd command"
export WORKLOAD_DIR="."
export ESTIMATED_RUN_TIME_MIN=1
export X_LABEL="Block size [ KB ]"
export VERBOSE=0  # Turn off most messages

# When sweeping, collect all files in the same run directory
export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)

for BLOCK_SIZE_KB in 128 256 512
do
  export RUN_ID="BSIZE_KB=$BLOCK_SIZE_KB"
  export WORKLOAD_CMD="./dd_test.sh ${BLOCK_SIZE_KB}k"
  ./run-workload.sh
done
