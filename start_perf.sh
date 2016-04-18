#!/bin/bash

[ "$#" -ne "1" ] && echo Usage: $0 HOSTNAME && exit 1

HOST=$1
echo Checking to see if perf is running on $HOST
CMD="ps -efa | grep 'perf record' | grep -v grep | grep -v $0 | grep -v vim | wc -l"
RC=$(ssh $HOST $CMD)
if [ "$RC" -ne 0 ]
then
  echo perf appears to be running on $HOST.
  echo Please stop perf. Exiting...
  exit 1
fi
echo Starting perf monitoring on $HOST

REMOTE_DIR=/tmp/${USER}/pid_monitor/perf
PERF_CMD="mkdir -p $REMOTE_DIR; \
          cd $REMOTE_DIR; \
          sudo rm -rf $REMOTE_DIR/*; \
          sudo perf record -a \
          2>/tmp/${USER}/pid_monitor/perf/perf.$1.stderr \
          1>/tmp/${USER}/pid_monitor/perf/perf.$1.stdout"

$(ssh $1 $PERF_CMD) 2>/dev/null &

