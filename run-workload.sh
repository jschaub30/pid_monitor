##!/bin/bash

# To run a custom workload, define the following variables and run this script
# see example.sh and example-sweep.sh

[ -z "$WORKLOAD_NAME" ]  && WORKLOAD_NAME=dd  # No spaces!
[ -z "$WORKLOAD_CMD" ]  && WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=1M count=1024 oflag=direct"
[ -z "$WORKLOAD_DIR" ]  && WORKLOAD_DIR='.'
[ -z "$ESTIMATED_RUN_TIME_MIN" ]  && ESTIMATED_RUN_TIME_MIN=1
[ -z "$RUNDIR" ]  && export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
[ -z "$RUN_ID" ]  && export RUN_ID="RUN=1.1"
[ -z "$SLAVES" ] && export SLAVES=$(hostname)
[ -z "$VERBOSE" ] && export VERBOSE=0  # Set to 1 to turn on debug messages

WORKLOAD_NAME=$(echo $WORKLOAD_NAME | tr " " "_")  # Remove spaces
RUN_ID=$(echo $RUN_ID | tr " " "_")  # Remove spaces

###############################################################################
# Define functions
debug_message(){
  if [ "$VERBOSE" -eq 1 ]
  then
    echo "#### PID MONITOR ####: $@"
  fi
}

stop_all() {
  # function to kill PIDs of workload and process monitors
  PIDS=$(pgrep -f "$WORKLOAD_CMD")
  echo "#### PID MONITOR ####: Stopping these processes: $PIDS"
  kill $PIDS 2>/dev/null
  #kill -9 $TIME_PID 2> /dev/null  # Kill main process if ctrl-c
  stop_dstat&
  sleep 1
  exit
}

stop_dstat() {
  for SLAVE in $SLAVES
  do
    #debug_message "Stopping dstat measurement on $SLAVE"
    DSTAT_CSV=/tmp/$RUN_ID.$SLAVE.dstat.csv
    PID=$(ssh $SLAVE "ps -fea | grep dstat" | grep $DSTAT_CSV | tr -s ' ' | cut -d' ' -f2)
    ssh $SLAVE "kill -9 $PID 2> /dev/null"&
  done
}

trap 'stop_all' SIGTERM SIGINT # Kill process monitors if killed early

if [ ! -f $RUNDIR/html/config.json ]
then
    ./create-json-config.sh
else
    # Add RUN_ID to json file. Remove closing brace, closing bracket, and add comma
    cat $RUNDIR/html/config.json | sed -e '$s/\]\}/,/' > tmp.json
    echo \"$RUN_ID\"\]\} >> tmp.json
    cp tmp.json $RUNDIR/html/config.json
fi

DELAY_SEC=$ESTIMATED_RUN_TIME_MIN  # For 20min total run time, record data every 20 seconds

echo "#### PID MONITOR ####: Running this workload:"
echo "#### PID MONITOR ####: \"$WORKLOAD_CMD\""

debug_message "Putting results in $RUNDIR"
debug_message "RUN_ID=\"$RUN_ID\""
cp *sh $RUNDIR/scripts
cp *py $RUNDIR/scripts

###############################################################################
# STEP 1: CREATE OUTPUT FILENAMES
TIME_FN=$RUNDIR/data/raw/$RUN_ID.time.stdout
CONFIG_FN=$RUNDIR/data/raw/$RUN_ID.config.txt
WORKLOAD_STDOUT=$RUNDIR/data/raw/$RUN_ID.workload.stdout
WORKLOAD_STDERR=$RUNDIR/data/raw/$RUN_ID.workload.stderr


###############################################################################
# STEP 2: START DSTAT USING SSH
stop_dstat
for SLAVE in $SLAVES
do
    DSTAT_CSV=/tmp/$RUN_ID.$SLAVE.dstat.csv
    DSTAT_CMD="dstat --time -v --net --output $DSTAT_CSV $DELAY_SEC"
    ssh $SLAVE "rm -f $DSTAT_CSV; nohup $DSTAT_CMD > /dev/null &"
    [ $? -ne 0 ] && debug_message "Problem connecting to host \"$SLAVE\" using ssh"
done

###############################################################################
# STEP 3: COPY CONFIG FILES TO CONFIG FILE IN RAW DIRECTORY
CONFIG=$CONFIG,timestamp,$(date +"%Y-%m-%d_%H:%M:%S")
CONFIG=$CONFIG,run_id,$RUN_ID
CONFIG=$CONFIG,kernel,$(uname -r)
CONFIG=$CONFIG,hostname,$(hostname -s)
CONFIG=$CONFIG,workload_name,$WORKLOAD_NAME
CONFIG=$CONFIG,dstat_command,$DSTAT_CMD
CONFIG=$CONFIG,workload_command,$WORKLOAD_CMD
CONFIG=$CONFIG,workload_dir,$WORKLOAD_DIR
CONFIG=$CONFIG,  # Add trailiing comma
echo $CONFIG > $CONFIG_FN

###############################################################################
# STEP 4: RUN WORKLOAD
CWD=$(pwd)
debug_message "Working directory: $WORKLOAD_DIR"
cd $WORKLOAD_DIR
/usr/bin/time --verbose --output=$TIME_FN bash -c \
    "$WORKLOAD_CMD 2> >(tee $WORKLOAD_STDERR) 1> >(tee $WORKLOAD_STDOUT)" &

TIME_PID=$!
debug_message "Main PID is $TIME_PID"
if [[ $SAMPLE_PERF -ne 1 ]]
then
    # Don't profile using perf
    debug_message "Waiting for $TIME_PID to finish"
    wait $TIME_PID
else
    # Take perf snapshots periodically while workload is still running
    PERF_ITER=1
    [ -z "$PERF_DURATION" ] && PERF_DURATION=2    # seconds
    [ -z "$PERF_DELTA" ] && PERF_DELTA=120 # seconds
    debug_message "Perf profiling enabled.  Sleeping for $PERF_DELTA seconds"
    sleep $((PERF_DELTA - PERF_DURATION))
    while [[ -e /proc/$TIME_PID ]]
    do
        debug_message "Recording perf sample $PERF_ITER for $PERF_DURATION seconds"
        sudo perf record -a & PID=$!
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
        #   (B) the TIME_PID to finish
        I=0
        while [[ $I -le $((PERF_DELTA - PERF_DURATION)) ]]
        do 
            I=$(( I + 1 ))
            sleep 1
            [[ ! -e /proc/$TIME_PID ]] && break
        done
    done
fi

cd $CWD

###############################################################################
# STEP 5: STOP_DSTAT
stop_dstat
sleep 1

###############################################################################
# STEP 6: ANALYZE DATA AND CREATE HTML CHARTS
cp -R html $RUNDIR/.
cp html/all_files.html $RUNDIR/data/raw
# Create symlink to allows python SimpleHTTPServer to serve files
$(cd $RUNDIR/html; ln -sf ../data)
debug_message "Now collecting CSV files"
for SLAVE in $SLAVES
do
  DSTAT_CSV=/tmp/$RUN_ID.$SLAVE.dstat.csv
  scp $SLAVE:$DSTAT_CSV $RUNDIR/data/raw/.
done

# Process data from this run's /usr/bin/time command
./tidy_time.py $TIME_FN $RUN_ID >> $RUNDIR/data/final/$RUN_ID.time.csv

# Process data from all runs into CSV and HTML table
./summarize_time.py $RUNDIR/html/config.json

echo "cd $RUNDIR/html; python -m SimpleHTTPServer 12121" > pid_webserver.sh
chmod u+x pid_webserver.sh
echo
echo "#### PID MONITOR ####: All data saved to $RUNDIR"
echo "#### PID MONITOR ####: View the html output using the following command:"
echo "#### PID MONITOR ####: $ ./pid_webserver.sh"
echo "#### PID MONITOR ####: Then navigate to http://localhost:12121"
echo
