#!/bin/bash

[ "$#" -lt "2" ] && echo Usage: "$0 MONITOR HOSTNAME [TARGET_FN]" && exit 1
MONITOR=$1
HOST=$2

[ $MONITOR == "ocount" ] && PREFIX="sudo"
[ $MONITOR == "perf" ] && PREFIX="sudo"
[ $MONITOR == "operf" ] && PREFIX="sudo"
[ $MONITOR == "gpu" ] && MONITOR="nvidia-smi"

if [ "$HOST" == "$(hostname)" ] || [ "$HOST" == "$(hostname -s)" ]
then
  # run locally
  PIDS=$(pgrep $MONITOR)
  PIDS=$(echo $PIDS | perl -pe "s/$$//")  # $$ is the PID of this script
  $PREFIX kill $PIDS  # killall didn't work here
else
  # use ssh.  Retrieve file from /tmp directory
  #ssh $HOST "$PREFIX killall -SIGINT $MONITOR"
  ssh $HOST "$PREFIX pkill $MONITOR"
  if [ "$#" -eq "3" ]
  then
    TARGET_FN=$3
    REMOTE_FN=/tmp/pid_monitor/$(basename $3)
    echo Copying $MONITOR data from $HOST:$REMOTE_FN to $TARGET_FN
    scp -r $HOST:$REMOTE_FN $TARGET_FN
    [ "$?" -eq 0 ] && ssh $HOST "$PREFIX rm $REMOTE_FN"
  fi
fi 
echo Successfully stopped $MONITOR on $HOST

