#!/bin/bash

export WORKLOAD_NAME=EXAMPLE-CLUSTER
export DESCRIPTION="Example workload on 2 node cluster using dd command"
export X_LABEL="Block size [ KB ]"
export MEAS_DELAY_SEC=1
export VERBOSE=0 # Turn off most messages
export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)

# Simple example--run workload on same machine twice
# Setup password-less ssh to localhost before running
export SLAVES="localhost $(hostname)"

for BLOCK_SIZE_KB in 128 256 512
do
    export RUN_ID="BLOCK_SIZE_KB=$BLOCK_SIZE_KB"
    export WORKLOAD_CMD="./dd_test.sh ${BLOCK_SIZE_KB}k"
    ./run-workload.sh
    # Optionally create new HTML table here
    # e.g. for spark workloads:
    #  ./create_spark_table.py $RUNDIR/html/config.json > $RUNDIR/html/workload.html
done
