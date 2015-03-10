#!/bin/bash

export SWEEP_FLAG=1
export WORKLOAD_NAME=EXAMPLE-SWEEP
export PROCESS_TO_GREP="dd"
export WORKLOAD_DIR="."
export ESTIMATED_RUN_TIME_MIN=1

export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
echo \{\"workload\":\"$WORKLOAD_NAME\", >> $RUNDIR/html/config.json
echo \"date\":\"$(date)\", >> $RUNDIR/html/config.json
echo \"run_ids\":\[ >> $RUNDIR/html/config.json

for COUNT in 8192 16384
do
	export RUN_ID="COUNT=$COUNT"
	export WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=128k count=$COUNT"
	./run-workload.sh
done

echo \]\} >> $RUNDIR/html/config.json
./tidy-json.py $RUNDIR/html/config.json > $RUNDIR/html/config.clean.json
