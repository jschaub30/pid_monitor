#!/bin/bash

export WORKLOAD_NAME=SPARKPI
export DESCRIPTION="Spark pi example"
export WORKLOAD_DIR="/data/spark"   # The spark home directory
export MEAS_DELAY_SEC=1  # Delay between each measurement

export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
export RUN_ID="SAMPLES=300"
export WORKLOAD_CMD="./bin/run-example SparkPi 300"  # The workload to run
./run-workload.sh

# Optionally create html table based on spark stderr
./create_spark_table.py $RUNDIR/html/config.json > $RUNDIR/html/workload.html
