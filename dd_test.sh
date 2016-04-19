#!/bin/bash
# Simple workload to write a file to disk

BS=512k    # default block size

[ "$#" -ne "0" ] && BS=$1
mkdir -p /tmp/${USER}
I=0
OUT_FN=/tmp/${USER}tmpfile.$I
# Make sure that OUT_FN is unique
while [ -e $OUT_FN ]
do
    I=$((I+1))
    OUT_FN=/tmp/${USER}/tmpfile.$I
done

echo Writing to $OUT_FN
dd if=/dev/zero of=$OUT_FN bs=$BS count=4096 oflag=direct
