#!/bin/bash
# This script starts the amester program
# AM_HOST is the host where the amester program is installed
# BMC_IP is the address of the BMC/service processor
# export BMC_USER and BMC_PASS if different than the default

[ "$#" -ne "5" ] && echo "Usage: $0 HOSTNAME FN DELAY_MS AMESTER_IP BMC_IP" && exit 64

HOST=$1
FN=/tmp/pid_monitor/$(basename $2)
DELAY_MS=$(($3*1000))
AM_HOST=$4
BMC_IP=$5
[ -z "$BMC_USER" ] && BMC_USER=ADMIN
[ -z "$BMC_PASS" ] && BMC_PASS=admin

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

AM_CMD="amester --nogui /home/ubuntu/amester/watchsensors.tcl $BMC_IP $BMC_USER $BMC_PASS $FN $DELAY_MS"
CMD="mkdir -p /tmp/pid_monitor/; \
           chmod -f 777 /tmp/pid_monitor; \
           rm -f $FN; \
           bash -c \"$AM_CMD &\""
#echo $CMD
$(ssh ubuntu@$AM_HOST $CMD) 2>/dev/null &
sleep 15  # Give amester a chance to establish communication and start up

