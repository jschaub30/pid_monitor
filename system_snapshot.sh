#!/bin/bash

[ "$#" -ne "1" ] && echo Usage: $0 HOSTNAME && exit 1

HOST=$1
if [ "$HOST" == "$(hostname -s)" ] || [ "$HOST" == "$(hostname -s)" ]
then
  unset SSH_FLAG
else
  SSH_FLAG=1
fi

TMPDIR=/tmp/${USER}/pid_monitor/$(date +"%Y%m%d-%H%M%S")

echo Collecting system snapshot on $HOST

CMD="mkdir -p $TMPDIR; \
    chmod -fR 777 $TMPDIR; \
    cd $TMPDIR; \
    git clone https://github.com/jschaub30/linux_summary $HOST; \
    cd $HOST; \
    ./linux_summary.sh;"

if [ $SSH_FLAG ]
then

    $(ssh $HOST $CMD) 2>/dev/null 
    scp $HOST:$TMPDIR/$HOST/index.html $HOST.html
else
    bash -c "$CMD" 2>&1 > /dev/null
    cp $TMPDIR/$HOST/index.html $HOST.html
fi

