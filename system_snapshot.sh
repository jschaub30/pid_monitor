#!/bin/bash

[ "$#" -ne "1" ] && echo Usage: $0 HOSTNAME && exit 1

HOST=$1
TMPDIR=/tmp/pid_monitor/$(date +"%Y%m%d-%H%M%S")

echo Collecting system snapshot on $HOST

SSH_CMD="mkdir -p $TMPDIR; \
           chmod 777 $TMPDIR; \
           cd $TMPDIR; \
           git clone https://github.com/jschaub30/linux_summary $HOST; \
           cd $HOST; \
           ./linux_summary.sh;"

$(ssh $HOST $SSH_CMD) 2>/dev/null 
scp $HOST:$TMPDIR/$HOST/index.html $HOST.html
