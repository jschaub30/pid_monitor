#!/bin/bash
# Creates JSON footer based on WORKLOAD_NAME and RUNDIR

[[ -z "$WORKLOAD_NAME" ]] && [[ -z "$RUNDIR" ]] && echo $0: WORKLOAD_NAME and/or RUNDIR not set && exit -1

TMP_FN=/tmp/$(echo whoami).config.json
cp $RUNDIR/html/config.json $TMP_FN
echo \]\} >> $TMP_FN
./tidy-json.py $TMP_FN > $RUNDIR/html/config.clean.json

