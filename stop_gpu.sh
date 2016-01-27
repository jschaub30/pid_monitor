#!/bin/bash

[ "$#" -lt "1" ] && echo Usage: $0 HOSTNAME FN OUT_DIR && exit 1

HOST=$1
FN=/tmp/pid_monitor/$(basename $2)
OUT_DIR=$3
ssh $HOST "sudo killall -SIGINT nvidia-smi"
sleep 1
if [ "$#" -eq "3" ]
then
  echo Copying nvidia-smi data from $HOST:$FN to $OUT_DIR
  scp -r $HOST:$FN $OUT_DIR/.
  [ "$?" -eq 0 ] && ssh $HOST "rm $FN"
fi
  
