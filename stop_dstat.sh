#!/bin/bash

[ "$#" -lt "1" ] && echo Usage: $0 HOSTNAME DSTAT_FN OUT_DIR && exit 1

HOST=$1

if [ "$HOST" == "$(hostname)" ] || [ "$HOST" == "$(hostname -s)" ]
then
  DSTAT_FN=$2
  kill $(ps -ef | grep $USER | grep -E 'python.*dstat' | grep -v grep | awk -F ' ' '{print $2}' | tr '\n' ' ')
  [ "$#" -eq "3" ] && mv $DSTAT_FN $3 2> /dev/null
else
  # use ssh.  Retrieve file from /tmp directory
  DSTAT_FN=/tmp/pid_monitor/$(basename $2)
  CMD="kill $(ps -ef | grep $USER | grep -E 'python.*dstat' | grep -v grep | awk -F ' ' '{print $2}' | tr '\n' ' ')"
  ssh $HOST "$CMD"
  if [ "$#" -eq "3" ]
  then
    OUT_DIR=$3
    echo Copying dstat data from $HOST:$DSTAT_FN to $OUT_DIR
    scp -r $HOST:$DSTAT_FN $OUT_DIR/.
  fi
fi

