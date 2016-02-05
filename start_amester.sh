#!/bin/bash

[ "$#" -ne "3" ] && echo "Usage: $0 HOSTNAME FN DELAY_MS" && exit 1

ARGS=( $@ )
len=${#ARGS[@]}
HOST=${ARGS[0]}

DELAY_MS=$((${ARGS[2]}*1000))
[ $HOST == "pcloud1" ] && AM_HOST="xcloud1" && FSP_IP=9.3.158.193
[ $HOST == "pcloud2" ] && AM_HOST="xcloud1" && FSP_IP=9.3.158.195
[ $HOST == "pcloud3" ] && AM_HOST="xcloud1" && FSP_IP=9.3.158.197
[ $HOST == "pcloud4" ] && AM_HOST="xcloud1" && FSP_IP=9.3.158.199
[ -z "$AM_HOST" ] && echo Unknown host && exit 1

FN=/tmp/pid_monitor/$(basename ${ARGS[1]})

[ "$DELAY_MS" -lt "1000" ] && echo Setting DELAY_MS to 1000 instead of $DELAY_MS && DELAY_MS=1000

echo Checking to see if amester is running on $HOST
CMD="ps -efa | grep amester | grep -v grep | grep -v $0 | grep -v vim | wc -l"
RC=$(ssh $HOST $CMD)
if [ $RC -ne 0 ]
then
  echo **************************************************
  echo WARNING: amester appears to be running on $HOST.
  echo Continuing, since more than 1 copy can run...
  echo **************************************************
fi
echo Starting amester monitoring on $HOST

AM_CMD="amester --nogui /home/ubuntu/amester/watchsensors.tcl $FSP_IP ADMIN admin $FN $DELAY_MS"
CMD="mkdir -p /tmp/pid_monitor/; \
           chmod -f 777 /tmp/pid_monitor; \
           rm -f $FN; \
           bash -c \"$AM_CMD &\""
#echo $CMD
$(ssh ubuntu@$AM_HOST $CMD) 2>/dev/null &


