#!/bin/bash

WORKLOAD_NAME=SLEEP
RUNDIR=$(./setup_run.sh $WORKLOAD_NAME)

echo $RUNDIR

WORKLOAD="sleep 2"

CONFIG=$CONFIG,kernel,$(uname -r),
CONFIG=$CONFIG,hostname,$(hostname -s),
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
TIME_FN=$RUNDIR/data/raw/run_log.$TIMESTAMP.time.txt
LOG_FN=$RUNDIR/data/raw/run_log.$TIMESTAMP.run.txt
CONFIG_FN=$RUNDIR/data/raw/run_log.$TIMESTAMP.config.txt

echo $CONFIG > $CONFIG_FN
/usr/bin/time --verbose --output=$TIME_FN bash -c \
    "$WORKLOAD > $LOG_FN"

