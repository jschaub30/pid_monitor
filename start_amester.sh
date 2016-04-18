#!/bin/bash
# This script starts the amester program
# AMESTER_IP is the IP of the host where amester is installed
# BMC_IP is the address of the BMC/service processor
# export BMC_USER and BMC_PASS if different than the default

[ "$#" -ne "4" ] && echo "Usage: $0 AMESTER_IP FN DELAY_SEC BMC_IP" && exit 64

AMESTER_IP=$1
FN=/tmp/${USER}/pid_monitor/$(basename $2)
DELAY_MS=$(($3*1000))
BMC_IP=$4
[ -z "$BMC_USER" ] && BMC_USER=ADMIN
[ -z "$BMC_PASS" ] && BMC_PASS=admin

[ "$DELAY_MS" -lt "1000" ] && echo Setting DELAY_MS to 1000 instead of $DELAY_MS && DELAY_MS=1000

echo Checking to see if amester is running on $AMESTER_IP
CMD='ps -efa | grep amester | grep -v grep | grep -v vim | wc -l'
RC=$(ssh $AMESTER_IP $CMD)
if [ $RC -ne 0 ]
then
  echo "######################################################"
  echo WARNING: amester appears to be running on $AMESTER_IP.
  echo Continuing, since more than 1 copy can run...
  echo "######################################################"
fi
echo Starting amester monitoring on $AMESTER_IP

AM_CMD="amester --nogui /home/ubuntu/amester/watchsensors.tcl $BMC_IP $BMC_USER $BMC_PASS $FN $DELAY_MS"
CMD="mkdir -p /tmp/${USER}/pid_monitor/; \
           rm -f $FN; \
           bash -c \"$AM_CMD &\""
#echo $CMD
$(ssh $AMESTER_IP $CMD) 2>/dev/null &
echo Please wait for amester to start collecting data
sleep 15  # Give amester a chance to establish communication and start up
