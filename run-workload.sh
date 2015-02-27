#!/bin/bash

# To run a custom workload, define the following 4 variables and run this script
[ -z "$WORKLOAD_NAME" ]  && WORKLOAD_NAME=dd && echo "Default workload"
[ -z "$PROCESS_NAME_TO_WATCH" ]  && PROCESS_NAME_TO_WATCH="dd"
[ -z "$PROCESS_NAME_TO_GREP" ]  && PROCESS_NAME_TO_GREP="dd"
[ -z "$WORKLOAD_CMD" ]  && WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=128k count=8192"
[ -z "$WORKLOAD_DIR" ]  && WORKLOAD_DIR='.'

echo Running this workload:
echo \"$WORKLOAD_CMD\"

RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
echo Putting results in $RUNDIR
cp $0 $RUNDIR/scripts
cp *py $RUNDIR/scripts
cp *R $RUNDIR/scripts

# STEP 1: CREATE OUTPUT FILENAMES BASED ON TIMESTAMP
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
TIME_FN=$RUNDIR/data/raw/log.time.txt
CONFIG_FN=$RUNDIR/data/raw/log.config.txt
WORKLOAD_STDOUT=$RUNDIR/data/raw/log.workload.stdout
WORKLOAD_STDERR=$RUNDIR/data/raw/log.workload.stderr
STAT_STDOUT=$RUNDIR/data/raw/log.pwatch.stdout

# STEP 2: DEFINE COMMANDS FOR WORKLOAD AND ALL MONITORS
STAT_CMD="./watch-process.sh $PROCESS_NAME_TO_WATCH" # could use dstat here too

# STEP 3: COPY CONFIG FILES TO RAW DIRECTORY
CONFIG=$CONFIG,timestamp,$TIMESTAMP
CONFIG=$CONFIG,kernel,$(uname -r)
CONFIG=$CONFIG,hostname,$(hostname -s)
CONFIG=$CONFIG,workload_name,$WORKLOAD_NAME
CONFIG=$CONFIG,stat_command,$STAT_CMD
CONFIG=$CONFIG,workload_command,$WORKLOAD_CMD
CONFIG=$CONFIG,workload_dir,$WORKLOAD_DIR
CONFIG=$CONFIG,  # Add trailiing comma
echo $CONFIG > $CONFIG_FN

# STEP 4: START PROCESS MONITOR
$STAT_CMD > $STAT_STDOUT &
STAT_PID=$!

CWD=$(pwd)
cd $WORKLOAD_DIR
echo Working directory: $WORKLOAD_DIR

# STEP 5: RUN WORKLOAD
/usr/bin/time --verbose --output=$TIME_FN bash -c \
    "$WORKLOAD_CMD 1> $WORKLOAD_STDOUT 2> $WORKLOAD_STDERR"

cd $CWD
#STEP 6: KILL STAT MONITOR
sleep 5
kill -9 $STAT_PID 2> /dev/null 1>/dev/null
sleep 1

#STEP 7: ANALYZE DATA
./tidy-pwatch.py $STAT_STDOUT $PROCESS_NAME_TO_GREP > $RUNDIR/data/final/pwatch.csv

#STEP 8: PARSE FINAL CSV DATA INTO CSV DATA FOR CHARTS/JAVASCRIPT
cp -R html $RUNDIR/.
cd $RUNDIR/html
./split-chartdata.R ../data/final/pwatch.csv pid elapsed_time_sec cpu_pct  # Parse CPU data
./split-chartdata.R ../data/final/pwatch.csv pid elapsed_time_sec mem_pct  # Parse memory data
cd $CWD

