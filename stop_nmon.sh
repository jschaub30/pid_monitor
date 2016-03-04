#!/bin/bash

[ "$#" -lt "1" ] && echo Usage: $0 HOSTNAME NMON_FN OUT_DIR && exit 1

HOST=$1
if [ "$HOST" == "$(hostname)" ] || [ "$HOST" == "$(hostname -s)" ]
then
  NMON_FN=$2
  kill $(ps -ef | grep nmon | grep -v -E "vim|$0|grep" | awk '{ print $2 }' | tr "\n" " ")
  [ "$#" -eq "3" ] && mv $NMON_FN $3 2> /dev/null
else
  # use ssh.  Retrieve file from /tmp directory
  NMON_FN=/tmp/pid_monitor/$(basename $2)
  CMD="kill $(ps -ef | grep nmon | grep -v -E 'vim|$0|grep' | awk '{ print $2 }' | tr '\n' ' ')"
  ssh $HOST "$CMD"
  if [ "$#" -eq "3" ]
  then
    OUT_DIR=$3
    echo Copying nmon data from $HOST:$NMON_FN to $OUT_DIR
    scp -r $HOST:$NMON_FN $OUT_DIR/.
  fi
fi

