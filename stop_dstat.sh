#!/bin/bash

[ "$#" -lt "1" ] && echo Usage: $0 HOSTNAME DSTAT_FN OUT_DIR && exit 1

HOST=$1

if [ "$HOST" == "$(hostname -s)" ] || [ "$HOST" == "$(hostname -s)" ]
then
  DSTAT_FN=$2
  unset SSH_FLAG
else
  # Will collect data over ssh.  Store in /tmp directory
  DSTAT_FN=/tmp/pid_monitor/$(basename $2)
  SSH_FLAG=1
fi

CMD="kill $(ps -ef | grep $USER | grep -E 'python.*dstat' | grep -v grep | awk -F ' ' '{print $2}' | tr '\n' ' ')"

[ $SSH_FLAG ] && ssh $HOST "$CMD"
[ ! $SSH_FLAG ] && $CMD

if [ "$#" -eq "3" ]
then
  OUT_DIR=$3
  if [ $SSH_FLAG ]
  then
    echo Copying dstat data from $HOST:$DSTAT_FN to $OUT_DIR
    scp -r $HOST:$DSTAT_FN $OUT_DIR/.
  fi
fi
  
