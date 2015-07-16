#!/bin/bash
# Simple workload to write 1GB file

I=0
while [ -e $OUT_FN ]
do
    OUT_FN=/tmp/tmpfile.$I
    I=$((I+1))
done
echo Writing to $OUT_FN
dd if=/dev/zero of=$OUT_FN bs=1048576 count=1024
