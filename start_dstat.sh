#!/bin/bash

[ "$#" -ne "3" ] && echo Usage: $0 HOSTNAME DSTAT_FN DELAY_SEC && exit 1

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
DELAY_SEC=$3

[ "$DELAY_SEC" -lt "1" ] && echo Setting DELAY_SEC to 1 instead of $DELAY_SEC && DELAY_SEC=1

# Check if dstat is installed
CMD="dstat --version >/dev/null &"
if [ $SSH_FLAG ]
then
  ssh pgpu1 "dstat --version" > /dev/null
  RC=$?
else
  dstat --version >/dev/null
  RC=$?
fi
[ "$RC" -ne 0 ] && echo ERROR: dstat is not installed on $HOST. Exiting... && exit 64

# Checking to see if dstat is already running
CMD="ps -efa | grep dstat | grep -v grep | grep -v $0 | grep -v vim | wc -l"
[ $SSH_FLAG ] && RC=$(ssh $HOST $CMD)
[ ! $SSH_FLAG ] &&  RC=$(ps -efa | grep dstat | grep -v grep | grep -v $0 | grep -v vim | wc -l)

[ $RC -ne 0 ] && echo WARNING: dstat appears to be running on $HOST.

if [ $SSH_FLAG ]
then
  DSTAT_CMD="mkdir -p /tmp/pid_monitor/; \
           chmod -f 777 /tmp/pid_monitor; \
           rm -f $DSTAT_FN; \
           sleep 0.1; \
           dstat --time -v --net --output $DSTAT_FN $DELAY_SEC"
  $(ssh $HOST $DSTAT_CMD) 2>/dev/null &
else
  dstat --time -v --net --output $DSTAT_FN $DELAY_SEC 1>/dev/null &
fi 

