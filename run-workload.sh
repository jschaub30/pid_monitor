##!/bin/bash

# To run a custom workload, define the following variables and run this script
# see example.sh and example-sweep.sh

[ -z "$WORKLOAD_NAME" ]  && WORKLOAD_NAME=dd  # No spaces!
[ -z "$WORKLOAD_CMD" ]  && WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=1048576 count=1024"
[ -z "$WORKLOAD_DIR" ]  && WORKLOAD_DIR='.'
[ -z "$ESTIMATED_RUN_TIME_MIN" ]  && ESTIMATED_RUN_TIME_MIN=1
[ "$ESTIMATED_RUN_TIME_MIN" -lt "1" ]  && ESTIMATED_RUN_TIME_MIN=1
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
  kill -9 $TIME_PID 2> /dev/null  &# Kill main process if ctrl-c
  PIDS=$(pgrep -f "$WORKLOAD_CMD")
  echo "#### PID MONITOR ####: Stopping these processes: $PIDS"
  kill $PIDS 2>/dev/null &
  stop_monitors&
  sleep 1
  exit
}

stop_monitors() {
  for SLAVE in $SLAVES
  do
    DSTAT_FN=$RUN_ID.$SLAVE.dstat.csv
    debug_message "Stopping dstat measurement on $SLAVE"
    ./stop_dstat.sh $SLAVE $DSTAT_FN $RUNDIR/data/raw/.
    OCOUNT_FN=$RUN_ID.$SLAVE.ocount
    [ "$OCOUNT_FLAG" == "1" ] && ./stop_ocount.sh $SLAVE $OCOUNT_FN $RUNDIR/data/raw/.
    [ "$OCOUNT_FLAG" == "1" ] && ./parse_ocount.py $RUNDIR/data/raw/$OCOUNT_FN > \
        $RUNDIR/data/raw/$OCOUNT_FN.csv
    #debug_message "Stopping operf measurement on $SLAVE"
    #./stop_operf.sh $SLAVE $RUNDIR/data/raw/$RUN_ID.$SLAVE.oprofile_data
    #debug_message "Stopping perf measurement on $SLAVE"
    #./stop_perf.sh $SLAVE $RUNDIR/data/raw/$RUN_ID.$SLAVE.perf.report
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
# STEP 2: START MONITORS USING SSH
CWD=$(pwd)
for SLAVE in $SLAVES
do
    DSTAT_FN=$RUN_ID.$SLAVE.dstat.csv
    ./start_dstat.sh $SLAVE $DSTAT_FN $DELAY_SEC
    [ $? -ne 0 ] && debug_message "Problem starting dstat on host \"$SLAVE\""
    if [ "$OCOUNT_FLAG" == "1" ]
    then
        OCOUNT_FN=$RUN_ID.$SLAVE.ocount
        ./start_ocount.sh $SLAVE $OCOUNT_FN $DELAY_SEC $OCOUNT_EVENTS $OCOUNT_PID
        [ $? -ne 0 ] && debug_message "Problem starting ocount on host \"$SLAVE\""
    fi
    #./start_operf.sh $SLAVE
    #[ $? -ne 0 ] && debug_message "Problem starting operf on host \"$SLAVE\""
    #./start_perf.sh $SLAVE
    #[ $? -ne 0 ] && debug_message "Problem starting perf on host \"$SLAVE\""
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
debug_message "Working directory: $WORKLOAD_DIR"
cd $WORKLOAD_DIR
# check for /usr/bin/time
TIME_PATH=/usr/bin/time
$TIME_PATH --verbose ls  2>/dev/null 1>/dev/null
if [ "$?" -ne "0" ]
then
    echo /usr/bin/time not working.  Trying gtime...
    TIME_PATH=gtime  # For OSX
    $TIME_PATH --verbose ls  2>/dev/null 1>/dev/null
    [ "$?" -ne "0" ] && echo gnu-time not found.  Exiting ... && exit 1
fi

$TIME_PATH --verbose --output=$TIME_FN bash -c \
    "$WORKLOAD_CMD 2> >(tee $WORKLOAD_STDERR) 1> >(tee $WORKLOAD_STDOUT)" &

TIME_PID=$!
debug_message "Waiting for $TIME_PID to finish"
wait $TIME_PID

cd $CWD

###############################################################################
# STEP 5: STOP_DSTAT
stop_monitors
sleep 1

###############################################################################
# STEP 6: ANALYZE DATA AND CREATE HTML CHARTS
rm -rf html/data  # For historical reasons
cp -R html $RUNDIR/.
cp html/all_files.html $RUNDIR/data/raw
# Create symlink to allows python SimpleHTTPServer to serve files
$(cd $RUNDIR/html; ln -sf ../data)

# Process data from all runs into HTML tables
./create_summary_table.py $RUNDIR/html/config.json > $RUNDIR/html/summary.html

# Create tarball of raw data
cd $RUNDIR/data
tar cfz all_raw_data.tar.gz raw
cd $CWD

echo "cd $RUNDIR/html; python -m SimpleHTTPServer 12121" > pid_webserver.sh
chmod u+x pid_webserver.sh
echo
echo "#### PID MONITOR ####: All data saved to $RUNDIR"
echo "#### PID MONITOR ####: View the html output using the following command:"
echo "#### PID MONITOR ####: $ ./pid_webserver.sh"
echo "#### PID MONITOR ####: Then navigate to http://localhost:12121"
echo
