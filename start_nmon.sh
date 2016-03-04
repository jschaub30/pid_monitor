#!/bin/bash

[ "$#" -ne "3" ] && echo Usage: $0 HOSTNAME NMON_FN DELAY_SEC && exit 1

HOST=$1

DELAY_SEC=$3
[ "$DELAY_SEC" -lt "1" ] && echo Setting DELAY_SEC to 1 instead of $DELAY_SEC && DELAY_SEC=1

if [ "$HOST" == "$(hostname)" ] || [ "$HOST" == "$(hostname -s)" ]
then
  # Run locally on this machine.  Store in path given
  NMON_FN=$2

  # Check if nmon is installed
  nmon -h >/dev/null
  [ "$?" -ne 0 ] && echo ERROR: nmon is not installed on $HOST. Exiting... && exit 64
  
  # Checking to see if nmon is already running
  RC=$(ps -efa | grep nmon | grep -v grep | grep -v $0 | grep -v vim | wc -l)
  [ $RC -ne 0 ] && echo WARNING: nmon appears to be running on $HOST.
  
  rm -f $NMON_FN
  # Start nmon
  nmon -f -c 10000 -F $NMON_FN -s $DELAY_SEC
  RC=$?

else
  # Will collect data over ssh.  Store in /tmp directory
  NMON_FN=/tmp/pid_monitor/$(basename $2)
  
  # Checking to see if nmon is already running
  RC=$(ssh $HOST "ps -efa | grep nmon | grep -v grep | grep -v $0 | grep -v vim | wc -l")
  [ $RC -ne 0 ] && echo WARNING: nmon appears to be running on $HOST.

  # Start nmon
  NMON_CMD="mkdir -p /tmp/pid_monitor/; \
	   chmod -f 777 /tmp/pid_monitor; \
	   rm -f $NMON_FN; \
	   nmon -f -c 10000 -F $NMON_FN -s $DELAY_SEC"
  ssh $HOST $NMON_CMD
  RC=$?
fi
[ "$RC" -ne 0 ] && echo Problem starting nmon on $HOST
[ "$RC" -eq 0 ] && echo Successfully started nmon on $HOST
