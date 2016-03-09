#!/bin/bash

[ "$#" -lt "1" ] && echo Usage: $0 AMESTER_IP FN OUT_DIR && exit 1

AMESTER_IP=$1
[ "$#" -gt 1 ] && FN=/tmp/pid_monitor/$(basename $2)
#CMD="kill $(ps -efa | grep amester | grep -v grep | awk -F ' ' '{print $2}')"
ssh $AMESTER_IP "pkill amester"

if [ "$#" -eq "3" ]
then
  OUT_DIR=$3
  echo Copying amester data from $AMESTER_IP:$FN to $OUT_DIR
  scp -r $AMESTER_IP:$FN $OUT_DIR/.
  [ "$?" -eq 0 ] && ssh $AMESTER_IP "rm -f $FN"
fi
  
