#!/bin/bash

[ $# -ne 2 ] && echo USAGE: $0 INPUT_DIR RUN_ID && exit 1
INPUT_DIR=$1
RUN_ID=$2

NV_BIN=$(which nvprof)
[ $? -ne 0 ] && echo ERROR: nvprof not found && exit 1

# Step 2: Convert to CSV
I=0
for FN in ${INPUT_DIR}/${RUN_ID}*nvprof
do
    CSV_FN=$(echo $FN | perl -pe "s/nvprof/gpu_bandwidth.csv/")
    $NV_BIN --csv --print-gpu-trace --import-profile $FN 2> $CSV_FN &
    I=$((I+1))
    [ $((I % 4)) -eq 0 ] && wait  # 4 at a time
done

wait

# Step 2: Pull out HtoD, DtoH and DtoD bandwidth data
I=0
for FN in ${INPUT_DIR}/${RUN_ID}*gpu_bandwidth.csv
do
    ./parse_gpu_bandwidth.py $FN &
    I=$((I+1))
    [ $((I % 4)) -eq 0 ] && wait  # 4 at a time
done
wait
