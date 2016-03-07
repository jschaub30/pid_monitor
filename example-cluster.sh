#!/bin/bash
# This example shows how to run a workload across 2 nodes in a 
# cluster.  We also sweep a parameter similar to "example-sweep.sh"
# It's recommended that you setup password-less ssh between all
# machines in your cluster prior to running this script.

export WORKLOAD_NAME=EXAMPLE-CLUSTER
export DESCRIPTION="Example workload on 2 node cluster using dd command"
export X_LABEL="Block size [ KB ]"
export MEAS_DELAY_SEC=1
export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)

# Simple example--fake 2 nodes by calling both hostname and localhost
export SLAVES="localhost $(hostname)"

for BLOCK_SIZE_KB in 128 256 512
do
    export RUN_ID="BLOCK_SIZE_KB=$BLOCK_SIZE_KB" # A unique label to identify this measurement
    export WORKLOAD_CMD="./dd_test.sh ${BLOCK_SIZE_KB}k"
    ./run-workload.sh
done
