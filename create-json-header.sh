#!/bin/bash
# Creates JSON header based on these workspace variables
# $WORKLOAD_NAME 
# $RUNDIR
# $X_LABEL
# $DESCRIPTION


[[ -z "$RUNDIR" ]] && echo $0: !!!!!!!!!! Warning!  RUNDIR not set 
[[ -z "$WORKLOAD_NAME" ]] && WORKLOAD_NAME="WORKLOAD"
[[ -z "$X_LABEL" ]] && X_LABEL="X label"
[[ -z "$DESCRIPTION" ]] && DESCRIPTION="DESCRIPTION"

echo \{\"workload\":\"$WORKLOAD_NAME\", >> $RUNDIR/html/config.json
echo \"date\":\"$(date)\", >> $RUNDIR/html/config.json
echo \"hostname\":\"$(hostname -s)\", >> $RUNDIR/html/config.json
echo \"description\":\"$DESCRIPTION\", >> $RUNDIR/html/config.json
echo \"xlabel\":\"$X_LABEL\", >> $RUNDIR/html/config.json
echo \"run_ids\":\[ >> $RUNDIR/html/config.json

