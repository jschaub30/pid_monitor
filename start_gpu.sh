#!/bin/bash

[ "$#" -ne "3" ] && echo "Usage: $0 HOSTNAME FN DELAY_SEC" && exit 1

HOST=$1
DELAY_SEC=$3

[ "$DELAY_SEC" -lt "1" ] && echo Setting DELAY_SEC to 1 instead of $DELAY_SEC && DELAY_SEC=1

if [ "$HOST" == "$(hostname)" ] || [ "$HOST" == "$(hostname -s)" ]
then
  # Run locally on this machine.  Store in path given
  echo Checking to see if nvidia-smi is running on $HOST
  RC=$(ps -efa | grep nvidia-smi | grep -v grep | grep -v $0 | grep -v vim | wc -l)
  [ $RC -ne 0 ] && echo WARNING: nvidia-smi appears to be running on $HOST. Continuing...
  FN=$2
  echo Starting nvidia-smi monitoring on $HOST
  nvidia-smi --query-gpu=timestamp,index,name,utilization.gpu,utilization.memory,power.draw \
        --format=csv --filename=$FN --loop=$DELAY_SEC 1>/dev/null &
else
  # Collect data over ssh.  Store in /tmp directory
  FN=/tmp/pid_monitor/$(basename $2)
  CMD="ps -efa | grep nvidia-smi | grep -v grep | grep -v $0 | grep -v vim | wc -l"
  RC=$(ssh $HOST $CMD)
  [ $RC -ne 0 ] && echo WARNING: nvidia-smi appears to be running on $HOST. Continuing...
  echo Starting nvidia-smi monitoring on $HOST
  
  GPU_CMD="nvidia-smi --query-gpu=timestamp,index,name,utilization.gpu,utilization.memory,power.draw \
      --format=csv --filename=$FN --loop=$DELAY_SEC"
  CMD="mkdir -p /tmp/pid_monitor/; \
             chmod -f 777 /tmp/pid_monitor; \
             rm -f $FN; \
             sleep 0.1; \
             bash -c \"$GPU_CMD &\""
  #echo $CMD

  $(ssh $HOST $CMD) 2>/dev/null &
fi
