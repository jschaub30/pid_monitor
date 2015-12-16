#!/bin/bash

[ "$#" -lt "2" ] && echo Usage: $0 HOSTNAME DATETIME && exit 1

echo Collecting system snapshot on $HOST

HOST=$1
TMPDIR=/tmp/pid_monitor/$2

SSH_CMD="mkdir -p $TMPDIR; \
           chmod 777 $TMPDIR; \
           cd $TMPDIR; \
           git clone https://github.com/jschaub30/linux_summary; \
           cd linux_summary; \
           ./linux_summary.sh"

$(ssh $HOST $SSH_CMD) 2>/dev/null 
scp $HOST:$TMPDIR/linux_summary/index.html $HOST.html
