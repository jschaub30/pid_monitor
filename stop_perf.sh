#!/bin/bash

[ "$#" -lt "1" ] && echo Usage: $0 HOSTNAME [TARGET_FN] && exit 1

HOST=$1
REMOTE_DIR=/tmp/${USER}/pid_monitor/perf
TARGET_FN=$2
KILL_CMD="sudo killall -SIGINT perf;
          sudo rm -f $REMOTE_DIR/perf.report;
          sudo perf report -i $REMOTE_DIR/perf.data \
            --kallsyms=/proc/kallsyms \
            2> /dev/null \
            1>$REMOTE_DIR/perf.report"
ssh $HOST "$KILL_CMD"
if [ "$#" -eq "2" ]
then
  echo Copying perf data from $HOST:$REMOTE_DIR to $TARGET_FN
  scp -r $HOST:$REMOTE_DIR/perf.report $TARGET_FN
fi
 
