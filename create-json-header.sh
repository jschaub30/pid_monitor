#!/bin/bash
# Creates JSON header based on WORKLOAD_NAME and RUNDIR


[[ -z "$WORKLOAD_NAME" ]] && [[ -z "$RUNDIR" ]] && echo $0: WORKLOAD_NAME and/or RUNDIR not set && exit -1

echo \{\"workload\":\"$WORKLOAD_NAME\", >> $RUNDIR/html/config.json
echo \"date\":\"$(date)\", >> $RUNDIR/html/config.json
echo \"run_ids\":\[ >> $RUNDIR/html/config.json

