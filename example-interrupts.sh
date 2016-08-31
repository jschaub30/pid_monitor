#!/bin/bash
# Create an unsorted ascii file, then sort using 1/2/4 threads
# using the 'taskset' command
# Assumes that your server has at least 8 threads

export WORKLOAD_NAME=EXAMPLE-INTERRUPTS
export DESCRIPTION="Example interrupts heatmap: sorting a random ascii file"
export WORKLOAD_DIR="."     # The workload working directory
export MEAS_DELAY_SEC=1     # Delay between each measurement
export INTERRUPTS_FLAG=1    # Flag that enables the interrupts heatmap measurement

NUM_LINES=10000000
if [ $(cat file.unsorted | wc -l) -ne $NUM_LINES ]
then
    echo Creating random text file with $NUM_LINES lines to sort.  Please wait...
    base64 /dev/urandom | head -n $NUM_LINES > file.unsorted
fi

export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)

export RUN_ID="4_threads"
export WORKLOAD_CMD="taskset -c 1,3,5,7 bash -c 'sort file.unsorted > /dev/null'"
./run-workload.sh
