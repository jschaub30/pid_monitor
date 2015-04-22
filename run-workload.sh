##!/bin/bash

# To run a custom workload, define the following 4 variables and run this script

[ -z "$WORKLOAD_NAME" ]  && WORKLOAD_NAME=dd && echo "dd workload"
#[ -z "$PROCESSES_TO_WATCH" ]  && PROCESSES_TO_WATCH=(dd)
[ -z "$PROCESS_TO_GREP" ]  && PROCESS_TO_GREP="dd"
[ -z "$WORKLOAD_CMD" ]  && WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=128k count=16384"
[ -z "$WORKLOAD_DIR" ]  && WORKLOAD_DIR='.'
[ -z "$ESTIMATED_RUN_TIME_MIN" ]  && ESTIMATED_RUN_TIME_MIN=1
[ -z "$RUNDIR" ]  && RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
[ -z "$RUN_ID" ]  && RUN_ID="RUN1"

if [ -z "$SWEEP_FLAG" ]
then
    echo \{\"workload\":\"$WORKLOAD_NAME\", >> $RUNDIR/html/config.json
    echo \"date\":\"$(date)\", >> $RUNDIR/html/config.json
fi
echo \"$RUN_ID\", >> $RUNDIR/html/config.json

DELAY_SEC=$ESTIMATED_RUN_TIME_MIN  # For 20min total run time, record data every 20 seconds

echo Running this workload:
echo \"$WORKLOAD_CMD\"

echo Putting results in $RUNDIR
cp *sh $RUNDIR/scripts
cp *py $RUNDIR/scripts
cp *R $RUNDIR/scripts

# STEP 1: CREATE OUTPUT FILENAMES BASED ON TIMESTAMP
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
TIME_FN=$RUNDIR/data/raw/$RUN_ID.time.stdout
CONFIG_FN=$RUNDIR/data/raw/$RUN_ID.config.txt
WORKLOAD_STDOUT=$RUNDIR/data/raw/$RUN_ID.workload.stdout
WORKLOAD_STDERR=$RUNDIR/data/raw/$RUN_ID.workload.stderr
STAT_STDOUT=$RUNDIR/data/raw/$RUN_ID.pwatch.stdout
DSTAT_CSV=$RUNDIR/data/raw/$RUN_ID.dstat.csv

# STEP 2: DEFINE COMMANDS FOR ALL SYSTEM MONITORS
STAT_CMD="./watch-process.sh $DELAY_SEC" 
$STAT_CMD > $STAT_STDOUT &
STAT_PID=$!
DSTAT_CMD="dstat --time -v --net --output $DSTAT_CSV $DELAY_SEC"
$DSTAT_CMD > /dev/null &
DSTAT_PID=$!

# STEP 3: COPY CONFIG FILES TO RAW DIRECTORY
CONFIG=$CONFIG,timestamp,$TIMESTAMP
CONFIG=$CONFIG,run_id,$RUN_ID
CONFIG=$CONFIG,kernel,$(uname -r)
CONFIG=$CONFIG,hostname,$(hostname -s)
CONFIG=$CONFIG,workload_name,$WORKLOAD_NAME
CONFIG=$CONFIG,stat_command,$STAT_CMD
CONFIG=$CONFIG,workload_command,$WORKLOAD_CMD
CONFIG=$CONFIG,workload_dir,$WORKLOAD_DIR
CONFIG=$CONFIG,  # Add trailiing comma
echo $CONFIG > $CONFIG_FN

CWD=$(pwd)
echo Working directory: $WORKLOAD_DIR
cd $WORKLOAD_DIR

# STEP 5: RUN WORKLOAD
/usr/bin/time --verbose --output=$TIME_FN bash -c \
    "$WORKLOAD_CMD 1> $WORKLOAD_STDOUT 2> $WORKLOAD_STDERR" &

MAIN_PID=$!

# Take perf snapshots periodically while workload is still running
PERF_ITER=1
PERF_DELTA=120 # seconds
sleep $PERF_DELTA
while [[ -e /proc/$MAIN_PID ]]
do
    echo Recording perf sample $PERF_ITER
    sudo perf record -a & PID=$!; echo pid is $PID; sleep 2; sudo kill $PID;
    sudo rm /tmp/perf.report
    sudo perf report --kallsyms=/proc/kallsyms 2> /dev/null 1> /tmp/perf.report
    # Only save first 1000 lines of perf report
    head -n 1000 /tmp/perf.report > $RUNDIR/data/raw/$RUN_ID.perf.$((PERF_ITER * PERF_DELTA))sec.txt
    PERF_ITER=$(( PERF_ITER + 1 ))
    sleep $PERF_DELTA
done

cd $CWD
#STEP 6: KILL STAT MONITOR
sleep 5
kill -9 $STAT_PID 2> /dev/null 1>/dev/null
kill -9 $DSTAT_PID 2> /dev/null 1>/dev/null
sleep 1

#STEP 7: ANALYZE DATA
echo Now tidying raw data into CSV files
./tidy-pwatch.py $STAT_STDOUT $PROCESS_TO_GREP $RUN_ID > $RUNDIR/data/final/$RUN_ID.pwatch.csv
./tidy-time.py $TIME_FN $RUN_ID >> $RUNDIR/data/final/$RUN_ID.time.csv
tail -n +7 $DSTAT_CSV > $RUNDIR/html/$RUN_ID.dstat.csv
./split-columns.R $RUNDIR/html/$RUN_ID.dstat.csv 1e-9 used buff cach free > $RUNDIR/html/$RUN_ID.mem.csv
./split-columns.R $RUNDIR/html/$RUN_ID.dstat.csv 1e-6 read writ > $RUNDIR/html/$RUN_ID.io.csv
./split-columns.R $RUNDIR/html/$RUN_ID.dstat.csv 1e-6 recv send > $RUNDIR/html/$RUN_ID.net.csv
./split-columns.R $RUNDIR/html/$RUN_ID.dstat.csv 1 usr sys idl wai > $RUNDIR/html/$RUN_ID.cpu.csv

# Combine CSV files from all runs into summaries
rm $RUNDIR/data/final/summary.time.csv
rm $RUNDIR/data/final/summary.pwatch.csv
./summarize-csv.py $RUNDIR/data/final .time.csv 2> $RUNDIR/data/final/errors.time.csv 1> $RUNDIR/data/final/summary.time.csv

# Copy data to plot.  Change filename so browser will render file instead of download
cp $RUNDIR/data/final/summary.time.csv $RUNDIR/html/time_summary_csv  
cp $RUNDIR/data/final/errors.time.csv $RUNDIR/html/time_errors_csv  

./summarize-csv.py $RUNDIR/data/final .pwatch.csv 2> $RUNDIR/data/final/errors.pwatch.csv 1>$RUNDIR/data/final/summary.pwatch.csv

#STEP 8: PARSE FINAL CSV DATA INTO CSV DATA FOR CHARTS/JAVASCRIPT
echo Creating html charts
cp -R html $RUNDIR/.
cd $RUNDIR/html
../scripts/split-chartdata.R ../data/final/$RUN_ID.pwatch.csv pid elapsed_time_sec cpu_pct  $RUN_ID # Parse CPU data
../scripts/split-chartdata.R ../data/final/$RUN_ID.pwatch.csv pid elapsed_time_sec mem_pct  $RUN_ID # Parse memory data
cd $CWD

if [ -z "$SWEEP_FLAG" ]
then
    echo \]\} >> $RUNDIR/html/config.json
    ./tidy-json.py $RUNDIR/html/config.json > $RUNDIR/html/config.clean.json
fi
