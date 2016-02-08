#!/bin/bash

[ "$#" -lt "1" ] && echo Usage: $0 HOSTNAME [GPU_FN] [OUT_DIR] && exit 1

HOST=$1
OUT_DIR=$3
ssh $HOST "sudo killall -SIGINT nvidia-smi"
sleep 1
if [ "$#" -eq "3" ]
then
  GPU_FN=/tmp/pid_monitor/$(basename $2)
  echo Copying nvidia-smi data from $HOST:$GPU_FN to $OUT_DIR
  scp -r $HOST:$GPU_FN $OUT_DIR/.
  [ "$?" -eq 0 ] && ssh $HOST "rm -f $GPU_FN"
fi
  
