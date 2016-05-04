#!/bin/bash

export WORKLOAD_NAME=GPU-BANDWIDTH
export DESCRIPTION="Nvidia host-to-device bandwidthTest example with nvprof"
export WORKLOAD_DIR="."             # The workload working directory
export MEAS_DELAY_SEC=1             # Delay between each measurement
export GPU_DETAIL_FLAG=1            # Capture GPU data
export GPU_BANDWIDTH_FLAG=1         # Capture throughput data
export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
export RUN_ID=shmoo

NVPROF_FN=${RUNDIR}/data/raw/${RUN_ID}_$(hostname -s)_%p.nvprof
export WORKLOAD_CMD="/usr/local/cuda-7.5/bin/nvprof \
    --profile-child-processes -o $NVPROF_FN \
    /usr/local/cuda-7.5/samples/bin/ppc64le/linux/release/bandwidthTest \
    --mode=shmoo"

./run-workload.sh

