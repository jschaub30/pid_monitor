#!/bin/bash

export WORKLOAD_NAME=EXAMPLE-DSTAT-CPU
export DESCRIPTION="Example workload using dd command"
export WORKLOAD_DIR="."             # The workload working directory
export MEAS_DELAY_SEC=1             # Delay between each measurement
export CPU_DETAIL_FLAG=1

export WORKLOAD_CMD="taskset -c 11 ./dd_test.sh"  # The workload to run
./run-workload.sh
