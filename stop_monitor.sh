#!/bin/bash

[ "$#" -lt "2" ] && echo Usage: "$0 MONITOR HOSTNAME [TARGET_FN]" && exit 1
MONITOR=$1
HOST=$2

[ $MONITOR == "ocount" ] && PREFIX="sudo"
[ $MONITOR == "perf" ] && PREFIX="sudo"
[ $MONITOR == "operf" ] && PREFIX="sudo"
[ $MONITOR == "gpu" ] && MONITOR="nvidia-smi"
[ $MONITOR == "interrupts" ] && MONITOR="record_interrupts.sh"

if [ "$HOST" == "$(hostname)" ] || [ "$HOST" == "$(hostname -s)" ]
then
  # run locally
  $PREFIX pkill -f $MONITOR 2>/dev/null
else
  # use ssh.  Retrieve file from /tmp directory
  ssh $HOST "$PREFIX pkill -f $MONITOR"
  if [ "$#" -eq "3" ]
  then
    TARGET_FN=$3
    REMOTE_FN=/tmp/${USER}/pid_monitor/$(basename $3)
    echo Copying $MONITOR data from $HOST:$REMOTE_FN to $TARGET_FN
    scp -r $HOST:$REMOTE_FN $TARGET_FN
    [ "$?" -eq 0 ] && ssh $HOST "$PREFIX rm $REMOTE_FN"
  fi
fi 
echo Successfully stopped $MONITOR on $HOST

