#!/bin/bash

[ "$#" -ne "3" ] && echo "Usage: $0 HOSTNAME FN DELAY_SEC" && exit 1

ARGS=( $@ )
len=${#ARGS[@]}
HOST=${ARGS[0]}
FN=/tmp/pid_monitor/$(basename ${ARGS[1]})
DELAY_SEC=${ARGS[2]}

[ "$DELAY_SEC" -lt "1" ] && echo Setting DELAY_SEC to 1 instead of $DELAY_SEC && DELAY_SEC=1

echo Checking to see if nvidia-smi is running on $HOST
CMD="ps -efa | grep nvidia-smi | grep -v grep | grep -v $0 | grep -v vim | wc -l"
RC=$(ssh $HOST $CMD)
if [ $RC -ne 0 ]
then
  echo WARNING: nvidia-smi appears to be running on $HOST.
  echo Continuing...
fi
echo Starting nvidia-smi monitoring on $HOST

GPU_CMD="nvidia-smi --query-gpu=timestamp,index,name,utilization.gpu,utilization.memory,power.draw \
    --format=csv --filename=$FN --loop=$DELAY_SEC"
CMD="mkdir -p /tmp/pid_monitor/; \
           chmod -f 777 /tmp/pid_monitor; \
           rm -f $FN; \
           sleep 0.1; \
           bash -c \"$GPU_CMD &\""
echo $CMD

$(ssh $HOST $CMD) 2>/dev/null &

