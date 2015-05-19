#!/bin/bash
# Creates JSON footer based on WORKLOAD_NAME and RUNDIR

[[ -z "$WORKLOAD_NAME" ]] && [[ -z "$RUNDIR" ]] && echo $0: WORKLOAD_NAME and/or RUNDIR not set && exit -1

# remove trailing comma on last line
sed '$s/.$//' $RUNDIR/html/config.json > $RUNDIR/html/config.clean.json  
echo \]\} >> $RUNDIR/html/config.clean.json

