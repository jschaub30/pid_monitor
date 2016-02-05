#!/bin/bash

[ "$#" -lt "1" ] && echo Usage: $0 HOSTNAME FN OUT_DIR && exit 1

HOST=$1
[ "$#" -gt 1 ] && FN=/tmp/pid_monitor/$(basename $2)
OUT_DIR=$3
[ $HOST == "pcloud1" ] && AM_HOST="xcloud1" && FSP_IP=9.3.158.193
[ -z "$AM_HOST" ] && echo Unknown host && exit 1
ssh ubuntu@$AM_HOST "sudo killall -SIGKILL amester"
sleep 1
if [ "$#" -eq "3" ]
then
  echo Copying amester data from ubuntu@$AM_HOST:$FN to $OUT_DIR
  scp -r ubuntu@$AM_HOST:$FN $OUT_DIR/.
  [ "$?" -eq 0 ] && ssh ubuntu@$AM_HOST "rm -f $FN"
fi
  
