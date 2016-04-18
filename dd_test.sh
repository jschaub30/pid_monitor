#!/bin/bash
# Simple workload to write a file to disk

BS=1024k    # default block size

[ "$#" -ne "0" ] && BS=$1
I=0
mkdir -p /tmp/${USER}/pid_monitor

OUT_FN=/tmp/${USER}/pid_monitor/tmpfile.0
# Make sure that OUT_FN is unique
while [ -e $OUT_FN ]
do
    I=$((I+1))
    OUT_FN=/tmp/${USER}/pid_monitor/tmpfile.$I
done

echo Writing to $OUT_FN
dd if=/dev/zero of=$OUT_FN bs=$BS count=4096 oflag=direct
