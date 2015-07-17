#!/bin/bash
# Simple workload to write 1GB file

BS=1048576
[ "$#" -ne "0" ] && BS=$1
I=0
mkdir -p /tmp/pid_monitor
OUT_FN=/tmp/pid_monitor/tmpfile.0
while [ -e $OUT_FN ]
do
    I=$((I+1))
    OUT_FN=/tmp/tmpfile.$I
done
echo Writing to $OUT_FN
dd if=/dev/zero of=$OUT_FN bs=$BS count=1024 oflag=direct
