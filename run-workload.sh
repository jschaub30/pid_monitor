##!/bin/bash

# To run a custom workload, define the following variables and run this script
# see example.sh and example-sweep.sh

[ -z "$WORKLOAD_NAME" ]  && WORKLOAD_NAME=dd  # No spaces!
[ -z "$WORKLOAD_CMD" ]  && WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=1048576 count=1024"
[ -z "$WORKLOAD_DIR" ]  && WORKLOAD_DIR='.'
[ -z "$MEAS_DELAY_SEC" ]  && MEAS_DELAY_SEC=1
[ "$MEAS_DELAY_SEC" -lt "1" ]  && MEAS_DELAY_SEC=1
[ -z "$RUNDIR" ]  && export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
[ -z "$RUN_ID" ]  && export RUN_ID="RUN=1.1"
[ -z "$SLAVES" ] && export SLAVES=$(hostname)
[ -z "$VERBOSE" ] && export VERBOSE=0  # Set to 1 to turn on debug messages
if [ "$P8_MEMBW_FLAG" == "1" ]
then
    OCOUNT_FLAG=1
    OCOUNT_EVENTS=$(cat counters.p8.mem.in | cut -d' ' -f1 | \
        perl -pe "s/\n/,/g" | sed s/,$//    )
fi
if [ "$HASWELL_MEMBW_FLAG" == "1" ]
then
    OCOUNT_FLAG=1
    OCOUNT_EVENTS=$(cat counters.haswell.mem.in | cut -d' ' -f1 | \
        perl -pe "s/\n/,/g" | sed s/,$//    )
fi
[ "$GPU_DETAIL_FLAG" == "1" ] && GPU_FLAG=1 

WORKLOAD_NAME=$(echo $WORKLOAD_NAME | tr " " "_")  # Remove spaces
RUN_ID=$(echo $RUN_ID | tr " " "_")  # Remove spaces

###############################################################################
# Define functions
fatal_message(){
  echo "#### PID MONITOR - FATAL ####: $@"
  stop_monitors
  exit 1
}
debug_message(){
  if [ "$VERBOSE" -eq 1 ]
  then
    echo "#### PID MONITOR ####: $@"
  fi
}

stop_all() {
  cd $CWD
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
    # Stop all monitors first, then parse them
    DSTAT_FN=$RUN_ID.$SLAVE.dstat.csv
    OCOUNT_FN=$RUN_ID.$SLAVE.ocount
    [ "$GPU_FLAG" == "1" ] && GPU_FN=$RUN_ID.$SLAVE.gpu
    PERF_FN=$RUN_ID.$SLAVE.perf.report
    AMESTER_FN=$RUN_ID.$SLAVE.amester
    debug_message "Stopping dstat measurement on $SLAVE"
    ./stop_dstat.sh $SLAVE $DSTAT_FN $RUNDIR/data/raw/.
    [ "$OCOUNT_FLAG" == "1" ] && ./stop_ocount.sh $SLAVE $OCOUNT_FN $RUNDIR/data/raw/.
    [ "$GPU_FLAG" == "1" ] && ./stop_gpu.sh $SLAVE $GPU_FN $RUNDIR/data/raw/.
    [ "$PERF_FLAG" == "1" ] && ./stop_perf.sh $SLAVE $RUNDIR/data/raw/$PERF_FN
    [ "$AMESTER_FLAG" == "1" ] && ./stop_amester.sh $SLAVE $AMESTER_FN $RUNDIR/data/raw/.
 
    # Now parse monitor output files
    # dstat data is parsed directly in webpage by javascript
    if [ "$OCOUNT_FLAG" == "1" ]
    then
        ./parse_ocount.py $RUNDIR/data/raw/$OCOUNT_FN > \
            $RUNDIR/data/raw/$OCOUNT_FN.csv
        ./memory_bw.R $RUNDIR/data/raw/$OCOUNT_FN.csv > \
            $RUNDIR/data/raw/$OCOUNT_FN.memory_bw.csv
    fi
    [ "$GPU_FLAG" == "1" ] && ./parse_gpu.R $RUNDIR/data/raw/$GPU_FN
    [ "$GPU_DETAIL_FLAG" == "1" ] && ./parse_gpu_detail.R $RUNDIR/data/raw/$GPU_FN
    [ "$AMESTER_FLAG" == "1" ] && ./parse_amester.R $RUNDIR/data/raw/$AMESTER_FN

    #debug_message "Stopping operf measurement on $SLAVE"
    #./stop_operf.sh $SLAVE $RUNDIR/data/raw/$RUN_ID.$SLAVE.oprofile_data
  done
  ###############################################################################
  # STEP 6: ANALYZE DATA AND CREATE HTML CHARTS
  rm -rf html/data  # For historical reasons
  cp -R html $RUNDIR/.
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
  IP=$(hostname -I | cut -d' ' -f1)
  echo
  echo "#### PID MONITOR ####: All data saved to $RUNDIR"
  echo "#### PID MONITOR ####: View the html output using the following command:"
  echo "#### PID MONITOR ####: $ ./pid_webserver.sh"
  echo "#### PID MONITOR ####: Then navigate to http://${IP}:12121"
  echo
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

cp *sh $RUNDIR/scripts
cp *R $RUNDIR/scripts
cp *py $RUNDIR/scripts
cp html/all_files.html $RUNDIR/data/raw

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
    debug_message "Collecting system snapshot on $SLAVE"
    # Gather system summary
    ./system_snapshot.sh $SLAVE
    mv ${SLAVE}.html $RUNDIR/html/.
done

for SLAVE in $SLAVES
do
    debug_message "Starting monitors on $SLAVE"
    # Start amester first, since it takes a long time to start up
    if [ "$AMESTER_FLAG" == "1" ]
    then
        AMESTER_FN=$RUN_ID.$SLAVE.amester
        ./start_amester.sh $SLAVE $AMESTER_FN $MEAS_DELAY_SEC
        if [ $? -ne 0 ] 
        then
          fatal_message "Problem starting amester on host \"$SLAVE\""
        fi
    fi
    # Start dstat monitor
    DSTAT_FN=$RUN_ID.$SLAVE.dstat.csv
    ./start_dstat.sh $SLAVE $DSTAT_FN $MEAS_DELAY_SEC
    [ $? -ne 0 ] && fatal_message "Problem starting dstat on host \"$SLAVE\""
    if [ "$OCOUNT_FLAG" == "1" ]
    then
        OCOUNT_FN=$RUN_ID.$SLAVE.ocount
        ./start_ocount.sh $SLAVE $OCOUNT_FN $MEAS_DELAY_SEC $OCOUNT_EVENTS $OCOUNT_PID
        if [ $? -ne 0 ] 
        then
          fatal_message "Problem starting ocount on host \"$SLAVE\""
        fi
    fi
    if [ "$GPU_FLAG" == "1" ]
    then
        GPU_FN=$RUN_ID.$SLAVE.gpu
        ./start_gpu.sh $SLAVE $GPU_FN $MEAS_DELAY_SEC
        if [ $? -ne 0 ] 
        then
          fatal_message "Problem starting nvidia-smi on host \"$SLAVE\""
        fi
    fi
    #./start_operf.sh $SLAVE
    #[ $? -ne 0 ] && debug_message "Problem starting operf on host \"$SLAVE\""
    [ "$PERF_FLAG" == "1" ] && ./start_perf.sh $SLAVE
    [ $? -ne 0 ] && debug_message "Problem starting perf on host \"$SLAVE\""
done

echo "#### PID MONITOR ####: Running this workload:"
echo "#### PID MONITOR ####: \"$WORKLOAD_CMD\""

debug_message "Putting results in $RUNDIR"
debug_message "RUN_ID=\"$RUN_ID\""

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
# STEP 5: STOP MONITORS
stop_monitors

