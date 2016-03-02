#!/bin/bash
# Simple workload to write 1GB file

BS=1024k  # default block size

[ "$#" -ne "0" ] && BS=$1
I=0
mkdir -p /tmp/pid_monitor
chmod -f a+w /tmp/pid_monitor # allow other users to write to this directory

OUT_FN=/tmp/pid_monitor/tmpfile.0
# Make sure that OUT_FN is unique
while [ -e $OUT_FN ]
do
    I=$((I+1))
    OUT_FN=/tmp/tmpfile.$I
done

echo Writing to $OUT_FN
dd if=/dev/zero of=$OUT_FN bs=$BS count=1024 oflag=direct
