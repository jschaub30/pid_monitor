#!/bin/bash

[ "$#" -ne "4" ] && echo Usage: $0 MONITOR HOSTNAME TARGET_FN DELAY_SEC && exit 1

MONITOR=$1
HOST=$2
DELAY_SEC=$4
[ "$DELAY_SEC" -lt "1" ] && echo Setting DELAY_SEC to 1 instead of $DELAY_SEC && DELAY_SEC=1

if [ "$HOST" == "$(hostname)" ] || [ "$HOST" == "$(hostname -s)" ]
then
  TARGET_FN=$3
else
  TARGET_FN=/tmp/${USER}/pid_monitor/$(basename $3)
fi

[ "$MONITOR" == "dstat" ] && \
  RUN_CMD="dstat --time -v --net --output $TARGET_FN $DELAY_SEC"

[ "$MONITOR" == "nmon" ] && \
  RUN_CMD="nmon -f -c 10000 -F $TARGET_FN -s $DELAY_SEC"

if [ "$MONITOR" == "cpu_detail" ]
then
    NUM_CPU=$(cat /proc/cpuinfo | grep processor | wc -l)
    CPU_LIST=$(seq 0 $NUM_CPU | perl -pe "s/\n/,/" | perl -pe "s/,$//")
    RUN_CMD="dstat --time --cpu -C $CPU_LIST --output $TARGET_FN $DELAY_SEC"
    # redefine MONITOR for test below
    MONITOR="dstat"
fi

if [ "$MONITOR" == "gpu" ]
then
  MONITOR="nvidia-smi"
  RUN_CMD="nvidia-smi \
    --query-gpu=timestamp,index,name,utilization.gpu,utilization.memory,power.draw \
    --format=csv --filename=$TARGET_FN --loop=$DELAY_SEC"
fi

if [ "$HOST" == "$(hostname)" ] || [ "$HOST" == "$(hostname -s)" ]
then
  # Run locally on this machine.  Store in path given

  # Check if $MONITOR is installed
  which $MONITOR >/dev/null
  [ "$?" -ne 0 ] && echo ERROR: $MONITOR is not installed on $HOST. Exiting... && exit 64
  
  # Checking to see if $MONITOR is already running
  RC=$(ps -efa | grep $MONITOR | grep -v grep | grep -v $0 | grep -v vim | wc -l)
  [ $RC -ne 0 ] && echo WARNING: $MONITOR appears to be running on $HOST.
  
  rm -f $TARGET_FN
  # Start $MONITOR
  $RUN_CMD 1>/dev/null &
  RC=$?

else
  # Will collect data over ssh.  Store in /tmp directory
  # Check if monitor is installed
  ssh $HOST "which $MONITOR" > /dev/null
  [ "$?" -ne 0 ] && echo ERROR: $MONITOR is not installed on $HOST. Exiting... && exit 64
  
  # Checking to see if monitor is already running
  RC=$(ssh $HOST "ps -efa | grep $MONITOR | grep -v grep | grep -v vim | wc -l")
  [ $RC -ne 0 ] && echo WARNING: $MONITOR appears to be running on $HOST.

  # Start $MONITOR
  REMOTE_CMD="mkdir -p /tmp/${USER}/pid_monitor/; \
	   rm -f $TARGET_FN; \
	   $RUN_CMD "
  $(ssh $HOST $REMOTE_CMD) 2>/dev/null &
  RC=$?
fi
[ "$RC" -ne 0 ] && echo Problem starting $MONITOR on $HOST
[ "$RC" -eq 0 ] && echo Successfully started $MONITOR on $HOST
