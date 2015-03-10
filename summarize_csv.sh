#!/bin/bash

[[ $# -lt 1 ]] && echo "Must input filename suffix (eg .time.csv)" && exit 1

SUFFIX=$1

H=1 # Header flag
for F in $(ls -tr *$SUFFIX)
do
    [[ $H -eq 1 ]] && echo run_id,$(head -n1 $F)
    H=0
    RUN_ID=$(echo $F | sed s"/$SUFFIX//")
    tail -n+2 $F | sed "s/^/$RUN_ID,/g"
done

