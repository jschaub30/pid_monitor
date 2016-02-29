#!/bin/bash

[ "$#" -lt "4" ] && echo "Usage: $0 HOSTNAME OCOUNT_FN DELAY_SEC EVENT_LIST [PID]" && exit 1

ARGS=( $@ )
len=${#ARGS[@]}
HOST=${ARGS[0]}
OCOUNT_FN=/tmp/pid_monitor/$(basename ${ARGS[1]})
DELAY_SEC=${ARGS[2]}
EVENT_LIST=${ARGS[3]}
PID=${ARGS[4]}
#EVENT_LIST=${ARGS[@]:4:$len-1}

[ "$DELAY_SEC" -lt "1" ] && echo Setting DELAY_SEC to 1 instead of $DELAY_SEC; DELAY_SEC=1

echo Checking to see if ocount is running on $HOST
CMD="ps -efa | grep ocount | grep -v grep | grep -v start_ocount | grep -v vim | wc -l"
RC=$(ssh $HOST $CMD)
if [ $RC -ne 0 ]
then
  echo ocount appears to be running on $HOST.
  echo Please stop ocount. Exiting...
  exit 1
fi
echo Starting ocount monitoring on $HOST
#echo Events are $EVENT_LIST

OCOUNT_CMD="mkdir -p /tmp/pid_monitor/; \
           chmod -f 777 /tmp/pid_monitor; \
           rm -f $OCOUNT_FN; \
           sleep 0.1; \
           sudo bash -c \"ulimit -n 100000;ocount -b -i $((DELAY_SEC*1000)) --events ${EVENT_LIST} --system-wide  >> $OCOUNT_FN 2>&1 < /dev/null &\""
           #sudo ocount -i $((DELAY_SEC*1000)) --events ${EVENT_LIST} -p $PID  >> $OCOUNT_FN 2>&1 < /dev/null &"
#echo $OCOUNT_CMD

$(ssh $HOST $OCOUNT_CMD) 2>/dev/null &

