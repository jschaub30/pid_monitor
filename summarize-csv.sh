#!/bin/bash

[[ $# -lt 2 ]] && echo "Usage: $0 [FN_PATH] [FN_SUFFIX] (eg $0 ../rundir/dd/latest/data/final .time.csv)" && exit 1

cd $1
SUFFIX=$2

H=1 # Header flag
for F in $(ls -tr *$SUFFIX)
do
    [[ $H -eq 1 ]] && echo run_id,$(head -n1 $F)
    H=0
    RUN_ID=$(echo $F | sed s"/$SUFFIX//")
    tail -n+2 $F | sed "s/^/$RUN_ID,/g"
done

