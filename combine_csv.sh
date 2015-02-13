#!/bin/bash

WORKLOAD_NAME=DATA
[[ "$#" -ne 0 ]] && WORKLOAD_NAME=$1

CSV_FILE=../rundir/$WORKLOAD_NAME/total.csv
HEADER_FLAG=true
for DIR in ../rundir/$WORKLOAD_NAME/2*
do
    echo $DIR
    if [ -s $DIR/data/final/summary.csv ]
    then
        if $HEADER_FLAG
        then
            cat $DIR/data/final/summary.csv > $CSV_FILE
            HEADER_FLAG=false
        else
            tail -n +2 $DIR/data/final/summary.csv >> $CSV_FILE  #skip header row
        fi
    fi
done
echo Finished writing $CSV_FILE
