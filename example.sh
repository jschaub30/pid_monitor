#!/bin/bash

export WORKLOAD_NAME=EXAMPLE
export PROCESS_NAME_TO_WATCH="dd"
export PROCESS_NAME_TO_GREP="dd"
export WORKLOAD_DIR="."

export WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=128k count=32768"
export ESTIMATED_RUN_TIME_MIN=1

./run-workload.sh

