#!/bin/bash

export WORKLOAD_NAME=GPU
export DESCRIPTION="Nvidia host-to-device bandwidthTest example"
export WORKLOAD_DIR="."             # The workload working directory
export MEAS_DELAY_SEC=1             # Delay between each measurement
export GPU_DETAIL_FLAG=1            # Capture GPU data
export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
export RUN_ID=shmoo

export WORKLOAD_CMD="/usr/local/cuda-7.5/samples/bin/ppc64le/linux/release/bandwidthTest \
    --mode=shmoo"

./run-workload.sh

