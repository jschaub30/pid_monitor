##!/bin/bash

# To run a custom workload, define the following variables and run this script
# see example.sh and example-sweep.sh

[ -z "$WORKLOAD_NAME" ]  && WORKLOAD_NAME=dd  # No spaces!
[ -z "$WORKLOAD_CMD" ]  && WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=1M count=1024 oflag=direct"
[ -z "$WORKLOAD_DIR" ]  && WORKLOAD_DIR='.'
[ -z "$ESTIMATED_RUN_TIME_MIN" ]  && ESTIMATED_RUN_TIME_MIN=1
[ -z "$RUNDIR" ]  && RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
[ -z "$RUN_ID" ]  && RUN_ID="RUN=1.1"

[ -z "$SAMPLE_PWATCH" ] && SAMPLE_PWATCH=0     # Turned off by default
[ -z "$SAMPLE_DSTAT" ] && SAMPLE_DSTAT=1        # Required for html plots
[ -z "$SAMPLE_NMON" ] && SAMPLE_NMON=1

[ -z "$PROCESS_TO_GREP" ]  && PROCESS_TO_GREP="dd"   # Only used if SAMPLE_PWATCH is set

if [ ! -f $RUNDIR/html/config.json ]
then
    ./create-json-header.sh
fi
echo \"$RUN_ID\", >> $RUNDIR/html/config.json

DELAY_SEC=$ESTIMATED_RUN_TIME_MIN  # For 20min total run time, record data every 20 seconds

echo Running this workload:
echo \"$WORKLOAD_CMD\"

echo Putting results in $RUNDIR
echo Run ID is $RUN_ID
cp *sh $RUNDIR/scripts
cp *py $RUNDIR/scripts
cp *R $RUNDIR/scripts

###############################################################################
# STEP 1: CREATE OUTPUT FILENAMES BASED ON TIMESTAMP
TIMESTAMP=$(date +"%Y-%m-%d_%H:%M:%S")
TIME_FN=$RUNDIR/data/raw/$RUN_ID.time.stdout
CONFIG_FN=$RUNDIR/data/raw/$RUN_ID.config.txt
WORKLOAD_STDOUT=$RUNDIR/data/raw/$RUN_ID.workload.stdout
WORKLOAD_STDERR=$RUNDIR/data/raw/$RUN_ID.workload.stderr

###############################################################################
# STEP 2: START SYSTEM MONITORS
# function to kill PIDs of process monitors
kill_procs() {
    echo "Stopping monitors"
    kill $MAIN_PID > /dev/null  # Kill main process if ctrl-c
    kill -USR2 $NMON_PID > /dev/null
    kill $PWATCH_PID $DSTAT_PID > /dev/null
}
trap 'kill_procs' SIGTERM SIGINT # Kill process monitors if killed early

MONITOR_CMD=""
if [[ $SAMPLE_PWATCH -eq 1 ]]
then
    PWATCH_STDOUT=$RUNDIR/data/raw/$RUN_ID.pwatch.stdout
    PWATCH_CMD="./watch-process.sh $DELAY_SEC" 
    $PWATCH_CMD > $PWATCH_STDOUT &
    PWATCH_PID=$!
    MONITOR_CMD="$MONITOR_CMD & $PWATCH_CMD > $PWATCH_STDOUT"
fi
if [[ $SAMPLE_DSTAT -eq 1 ]]
then
    DSTAT_CSV=$RUNDIR/data/raw/$RUN_ID.dstat.csv
    DSTAT_CMD="dstat --time -v --net --output $DSTAT_CSV $DELAY_SEC"
    $DSTAT_CMD > /dev/null &
    DSTAT_PID=$!
    MONITOR_CMD="$MONITOR_CMD & $DSTAT_CMD > /dev/null"
fi
if [[ $SAMPLE_NMON -eq 1 ]]
then
    NMON_FN=$RUNDIR/data/raw/$RUN_ID.nmon.txt
    NMON_CMD="nmon -s $DELAY_SEC -c 1000 -F $NMON_FN -p"
    NMON_PID=$($NMON_CMD)
    MONITOR_CMD="$MONITOR_CMD & $NMON_CMD"
fi

echo "MONITOR_CMD --> $MONITOR_CMD"

###############################################################################
# STEP 3: COPY CONFIG FILES TO RAW DIRECTORY
CONFIG=$CONFIG,timestamp,$TIMESTAMP
CONFIG=$CONFIG,run_id,$RUN_ID
CONFIG=$CONFIG,kernel,$(uname -r)
CONFIG=$CONFIG,hostname,$(hostname -s)
CONFIG=$CONFIG,workload_name,$WORKLOAD_NAME
CONFIG=$CONFIG,stat_command,$PWATCH_CMD
CONFIG=$CONFIG,workload_command,$WORKLOAD_CMD
CONFIG=$CONFIG,workload_dir,$WORKLOAD_DIR
CONFIG=$CONFIG,  # Add trailiing comma
echo $CONFIG > $CONFIG_FN

###############################################################################
# STEP 4: RUN WORKLOAD
CWD=$(pwd)
echo Working directory: $WORKLOAD_DIR
cd $WORKLOAD_DIR
/usr/bin/time --verbose --output=$TIME_FN bash -c \
    "$WORKLOAD_CMD 1> >(tee $WORKLOAD_STDOUT) 2> >(tee $WORKLOAD_STDERR) " &

MAIN_PID=$!
echo Main PID is $MAIN_PID
if [[ $SAMPLE_PERF -ne 1 ]]
then
    # Don't profile using perf
    echo Waiting for $MAIN_PID to finish
    wait $MAIN_PID
else
    # Take perf snapshots periodically while workload is still running
    PERF_ITER=1
    [ -z "$PERF_DURATION" ] && PERF_DURATION=2    # seconds
    [ -z "$PERF_DELTA" ] && PERF_DELTA=120 # seconds
    echo Perf profiling enabled.  Sleeping for $PERF_DELTA seconds
    sleep $((PERF_DELTA - PERF_DURATION))
    while [[ -e /proc/$MAIN_PID ]]
    do
        echo Recording perf sample $PERF_ITER for $PERF_DURATION seconds
        sudo perf record -a & PID=$!
        echo pid is $PID
        sleep $PERF_DURATION
        sudo kill $PID
        sudo rm -f /tmp/perf.report
        sudo perf report --kallsyms=/proc/kallsyms 2> /dev/null 1> /tmp/perf.report
        # Only save first 1000 lines of perf report
        head -n 1000 /tmp/perf.report \
            > $RUNDIR/data/raw/$RUN_ID.perf.$((PERF_ITER * PERF_DELTA))sec.txt
        PERF_ITER=$(( PERF_ITER + 1 ))
        #sleep $((PERF_DELTA - PERF_DURATION))

        # This loop will wait for either:
        #   (A) the delay between PERF runs or 
        #   (B) the MAIN_PID to finish
        I=0
        while [[ $I -le $((PERF_DELTA - PERF_DURATION)) ]]
        do 
            I=$(( I + 1 ))
            sleep 1
            [[ ! -e /proc/$MAIN_PID ]] && break
        done
    done
fi

cd $CWD

###############################################################################
# STEP 5: KILL SYSTEM MONITORS
kill_procs
sleep 1

###############################################################################
# STEP 6: ANALYZE DATA AND CREATE HTML CHARTS
cp -R html $RUNDIR/.
cp html/all_files.html $RUNDIR/data/raw

# Combine CSV files from all runs into summaries
echo Now tidying raw data into CSV files

# Always process data from /usr/bin/time
./tidy-time.py $TIME_FN $RUN_ID >> $RUNDIR/data/final/$RUN_ID.time.csv
rm -f $RUNDIR/data/final/summary.time.csv
./summarize-csv.py $RUNDIR/data/final .time.csv \
    2> $RUNDIR/data/final/errors.time.csv 1> $RUNDIR/data/final/summary.time.csv
# Copy summary data. Change filename so browser will render file instead of download
cp $RUNDIR/data/final/summary.time.csv $RUNDIR/html/time_summary_csv  
cp $RUNDIR/data/final/errors.time.csv $RUNDIR/html/time_errors_csv  

if [[ $SAMPLE_PWATCH -eq 1 ]]
then
    ./tidy-pwatch.py $PWATCH_STDOUT $PROCESS_TO_GREP $RUN_ID \
        > $RUNDIR/data/final/$RUN_ID.pwatch.csv
    rm -f $RUNDIR/data/final/summary.pwatch.csv
    ./summarize-csv.py $RUNDIR/data/final .pwatch.csv \
        2> $RUNDIR/data/final/errors.pwatch.csv \
        1>$RUNDIR/data/final/summary.pwatch.csv
    cd $RUNDIR/html/data
    ../../scripts/split-chartdata.R ../../data/final/$RUN_ID.pwatch.csv \
        pid elapsed_time_sec cpu_pct  $RUN_ID # Parse CPU data
    ../../scripts/split-chartdata.R ../../data/final/$RUN_ID.pwatch.csv \
        pid elapsed_time_sec mem_pct  $RUN_ID # Parse memory data
    cd $CWD
fi

if [[ $SAMPLE_DSTAT -eq 1 ]]
then
    tail -n +7 $DSTAT_CSV > $RUNDIR/html/data/$RUN_ID.dstat.csv
    ./split-columns.R $RUNDIR/html/data/$RUN_ID.dstat.csv 1e-9 used buff cach free \
        > $RUNDIR/html/data/$RUN_ID.mem.csv
    ./split-columns.R $RUNDIR/html/data/$RUN_ID.dstat.csv 1e-6 read writ \
        > $RUNDIR/html/data/$RUN_ID.io.csv
    ./split-columns.R $RUNDIR/html/data/$RUN_ID.dstat.csv 1e-6 recv send \
        > $RUNDIR/html/data/$RUN_ID.net.csv
    ./split-columns.R $RUNDIR/html/data/$RUN_ID.dstat.csv 1 usr sys idl wai \
        > $RUNDIR/html/data/$RUN_ID.cpu.csv
fi

#if [[ $SAMPLE_NMON -eq 1 ]]
#then
    # TODO Write NMON parser
#fi

./create-json-footer.sh
./summarize-time.py $RUNDIR/html/config.clean.json > $RUNDIR/html/summary.csv
./csv2html.sh $RUNDIR/html/summary.csv > $RUNDIR/html/summary.html


