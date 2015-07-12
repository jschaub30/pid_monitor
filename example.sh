#!/bin/bash

export WORKLOAD_NAME=EXAMPLE
export DESCRIPTION="Example workload using dd command"
export WORKLOAD_DIR="."
export WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=1M count=1024 oflag=direct"
export ESTIMATED_RUN_TIME_MIN=1
export VERBOSE=0 # Turn off most messages
export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)

./run-workload.sh
# Optionally create new HTML table here
# e.g. for spark workloads:
#  ./create_spark_table.py $RUNDIR/html/config.json
