#!/bin/bash

[ "$#" -lt "1" ] && echo Usage: $0 [HOSTNAME] && exit 1

HOST=$1
REMOTE_DIR=/tmp/pid_monitor/oprofile_data
TARGET_DIR=$2

ssh $HOST "sudo killall -SIGINT operf"
sleep 1
if [ "$#" -eq "2" ]
then
  echo Copying oprofile data from $HOST:$REMOTE_DIR to $TARGET_DIR
  scp -r $HOST:$REMOTE_DIR $TARGET_DIR
fi
  
