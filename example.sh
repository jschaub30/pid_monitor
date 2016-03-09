#!/bin/bash

export WORKLOAD_NAME=EXAMPLE
export DESCRIPTION="Example workload using dd command"
export WORKLOAD_DIR="."             # The workload working directory
export MEAS_DELAY_SEC=1             # Delay between each measurement
export WORKLOAD_CMD="./dd_test.sh"  # The workload to run

./run-workload.sh
