#!/bin/bash
# This script demonstrates how to sweep a parameter
#
# Export these variables to execute a sweep
# - RUNDIR        to collect all files in 1 directory (see below)
# - X_LABEL       description of the parameter you are sweeping
# - RUN_ID        needs to be unique for each measurement
# - WORKLOAD_CMD  actual workload to call with the parameter
#

export WORKLOAD_NAME=EXAMPLE-SWEEP
export DESCRIPTION="Example sweep using dd command"
export WORKLOAD_DIR="."      # The workload working directory
export MEAS_DELAY_SEC=1      # Delay between each measurement

export X_LABEL="Block size [ KB ]"
export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)

for BLOCK_SIZE_KB in 128 256 512
do
  export RUN_ID="BSIZE_KB_$BLOCK_SIZE_KB" # A unique label to identify this measurement
  export WORKLOAD_CMD="./dd_test.sh ${BLOCK_SIZE_KB}k"
  ./run-workload.sh
done

