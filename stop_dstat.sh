#!/bin/bash

[ "$#" -lt "3" ] && echo Usage: $0 HOSTNAME DSTAT_FN OUT_DIR && exit 1

HOST=$1
DSTAT_FN=/tmp/pid_monitor/$(basename $2)
OUT_DIR=$3
#ssh $HOST "killall -SIGINT dstat"
CMD="kill $(ps -ef | grep $USER | grep -E 'python.*dstat' | grep -v grep | awk -F ' ' '{print $2}' | tr '\n' ' ')"
ssh $HOST "$CMD"
sleep 1
if [ "$#" -eq "3" ]
then
  echo Copying dstat data from $HOST:$DSTAT_FN to $OUT_DIR
  scp -r $HOST:$DSTAT_FN $OUT_DIR/.
  [ "$?" -eq 0 ] && ssh $HOST "rm -f $DSTAT_FN"
fi
  
