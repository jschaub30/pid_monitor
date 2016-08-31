#!/bin/bash

[ $# -ne 1 ] && echo USAGE: $0 INTERRUPTS_FN && exit 1

FN=$1
NUM_CPU=$(cat /proc/cpuinfo | grep processor | wc -l)

head -n 1 $FN | perl -pe "s/^/queue/" | perl -pe "s/\h+/,/g" | perl -pe "s/$/label/" > ${FN}.csv
grep "[0-9]:" $FN | perl -pe "s/ *([0-9]+):\s+/\1,/" | perl -pe "s/\h+/,/g" > ${FN}.tmp
cut -d',' -f1-$((NUM_CPU+1)) ${FN}.tmp > ${FN}.tmp1
cut -d',' -f$((NUM_CPU+2))- ${FN}.tmp | perl -pe "s/,/_/g" > ${FN}.tmp2
paste -d',' ${FN}.tmp1 ${FN}.tmp2 >> ${FN}.csv
rm ${FN}.tmp ${FN}.tmp1 ${FN}.tmp2
