#!/bin/bash

[ $# -ne 3 ] && echo USAGE: $0 INPUT_DIR RUN_ID HOST && exit 1
INPUT_DIR=$1
RUN_ID=$2
HOST=$3

# Step 1: Find the largest nvprof file for this run ID
FN=$(ls -S ${INPUT_DIR}/${RUN_ID}*${HOST}*nvprof | head -n 1)
NEW_FN=${INPUT_DIR}/${RUN_ID}_${HOST}_nvprof
mv $FN $NEW_FN

# Step 2: Convert to CSV
CSV_FN=$(echo $NEW_FN | perl -pe "s/nvprof/gpu_bandwidth.csv/")
nvprof --csv --print-gpu-trace --import-profile $NEW_FN 2> $CSV_FN

# Step 2: Pull out HtoD, DtoH and DtoD bandwidth data
./parse_gpu_bandwidth.py $CSV_FN

