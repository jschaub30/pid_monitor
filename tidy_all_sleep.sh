#!/bin/bash

for RUNDIR in ../rundir/SLEEP/2*  # all directories but skip 'latest' link
do
    echo Creating $RUNDIR/data/final/summary.csv
    ./tidy_sleep.py $RUNDIR > $RUNDIR/data/final/summary.csv
done
./combine_csv.sh SLEEP

