#!/bin/bash

[ "$#" -ne "3" ] && echo Usage: $0 HOSTNAME DSTAT_FN DELAY_SEC && exit 1

HOST=$1
DSTAT_FN=/tmp/pid_monitor/$(basename $2)
DELAY_SEC=$3

[ "$DELAY_SEC" -lt "1" ] && echo Setting DELAY_SEC to 1 instead of $3 && DELAY_SEC=1

echo Checking to see if dstat is running on $HOST
CMD="ps -efa | grep dstat | grep -v grep | grep -v $0 | grep -v vim | wc -l"
RC=$(ssh $HOST $CMD)
if [ $RC -ne 0 ]
then
  echo dstat appears to be running on $HOST.
  echo Please stop dstat. Exiting...
  exit 1
fi

DSTAT_CMD="mkdir -p /tmp/pid_monitor/; \
           chmod 777 /tmp/pid_monitor; \
           rm -f $DSTAT_FN; \
           sleep 0.1; \
           dstat --time -v --net --output $DSTAT_FN $DELAY_SEC"

$(ssh $HOST $DSTAT_CMD) 2>/dev/null &

