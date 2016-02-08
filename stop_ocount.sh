#!/bin/bash

[ "$#" -lt "1" ] && echo Usage: $0 HOSTNAME OCOUNT_FN OUT_DIR && exit 1

HOST=$1
OUT_DIR=$3
ssh $HOST "sudo killall -SIGINT ocount"
sleep 1
if [ "$#" -eq "3" ]
then
  echo Copying ocount data from $HOST:$OCOUNT_FN to $OUT_DIR
  OCOUNT_FN=/tmp/pid_monitor/$(basename $2)
  scp -r $HOST:$OCOUNT_FN $OUT_DIR/.
  [ "$?" -eq 0 ] && ssh $HOST "rm $OCOUNT_FN"
fi
  
