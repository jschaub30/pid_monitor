#!/bin/bash

[ "$#" -ne "3" ] && echo Usage: $0 HOSTNAME DSTAT_FN DELAY_SEC && exit 1

HOST=$1
DSTAT_FN=/tmp/pid_monitor/$(basename $2)
DELAY_SEC=$3

[ "$DELAY_SEC" -lt "1" ] && echo Setting DELAY_SEC to 1 instead of $3 && DELAY_SEC=1

DSTAT_CMD="mkdir -p /tmp/pid_monitor/; \
           chmod 777 /tmp/pid_monitor; \
           rm -f $DSTAT_FN; \
           sleep 0.1; \
           dstat --time -v --net --output $DSTAT_FN $DELAY_SEC"

$(ssh $HOST $DSTAT_CMD) 2>/dev/null &

