#!/bin/bash

FILE=$1

[[ $# -ne 1 ]] && echo USAGE: $0 csvfile && exit 1

index_csv_column(){
  INDEX=1
  for TMP_NAME in $(head -n 1 $FILE | tr ',' ' '); do
    [[ $COL_NAME == $TMP_NAME ]] && break
    INDEX=$((INDEX+1))
  done
  echo $INDEX
}

FIELDS=1
COL_NAME=PM_DATA_FROM_L3
for COL_NAME in PM_DATA_FROM_L2 PM_DATA_FROM_L3 PM_DATA_FROM_LMEM PM_DATA_FROM_RMEM PM_DATA_FROM_LL4
do
 FIELDS=$FIELDS,$(index_csv_column)
done

cat $FILE | cut -d',' -f $FIELDS
