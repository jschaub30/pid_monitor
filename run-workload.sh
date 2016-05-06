##!/bin/bash

# To run a custom workload, define the following variables and run this script
# see example.sh and example-sweep.sh

[ -z "$WORKLOAD_NAME" ]  && WORKLOAD_NAME=dd  # No spaces!
[ -z "$WORKLOAD_CMD" ]  && WORKLOAD_CMD="dd if=/dev/zero of=/tmp/tmpfile bs=1048576 count=1024"
[ -z "$WORKLOAD_DIR" ]  && WORKLOAD_DIR='.'
[ -z "$MEAS_DELAY_SEC" ]  && MEAS_DELAY_SEC=1
[ "$MEAS_DELAY_SEC" -lt "1" ]  && MEAS_DELAY_SEC=1
[ -z "$RUNDIR" ]  && export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
[ -z "$RUN_ID" ]  && export RUN_ID="RUN_1"
[ -z "$SLAVES" ] && export SLAVES=$(hostname -s)
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
  if [ "$PIDS" != "" ]
  then
    echo "#### PID MONITOR ####: Stopping these processes: $PIDS"
    kill -9 $PIDS 2>/dev/null &
    sleep 1
  fi
  stop_monitors&
  exit
}

define_filenames() {
  RAWDIR=${RUNDIR}/data/raw
  DSTAT_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_dstat.csv
  OCOUNT_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_ocount
  NMON_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_nmon
  GPU_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_gpu
  PERF_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_perf_report
  AMESTER_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_amester
}

stop_monitors() {
  sleep 2
  for SLAVE in $SLAVES
  do
    # Stop all monitors first, then parse them
    define_filenames
    debug_message "Stopping dstat measurement on $SLAVE"
    ./stop_monitor.sh dstat $SLAVE $DSTAT_FN
    [ "$OCOUNT_FLAG" == "1" ] && ./stop_monitor.sh ocount $SLAVE $OCOUNT_FN
    [ "$GPU_FLAG" == "1" ] && ./stop_monitor.sh gpu $SLAVE $GPU_FN
    [ "$NMON_FLAG" == "1" ] && ./stop_monitor.sh nmon $SLAVE $NMON_FN
    [ "$PERF_FLAG" == "1" ] && ./stop_perf.sh $SLAVE $PERF_FN
    [ "$AMESTER_FLAG" == "1" ] && ./stop_monitor.sh amester $AMESTER_IP $AMESTER_FN
 
    # Now parse monitor output files
    # dstat data is parsed directly in webpage by javascript
    if [ "$OCOUNT_FLAG" == "1" ]
    then
        ./parse_ocount.py $OCOUNT_FN > $OCOUNT_FN.csv
        ./memory_bw.R $OCOUNT_FN.csv > $OCOUNT_FN.memory_bw.csv
    fi
    [ "$GPU_FLAG" == "1" ] && ./parse_gpu.R $GPU_FN
    [ "$GPU_DETAIL_FLAG" == "1" ] && ./parse_gpu_detail.R $GPU_FN
    [ "$GPU_BANDWIDTH_FLAG" == "1" ] && ./tidy_nvprof.sh $RUNDIR/data/raw \
        $RUN_ID $SLAVE
    [ "$AMESTER_FLAG" == "1" ] && ./parse_amester.R $AMESTER_FN

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
cp -r tidy $RUNDIR/scripts/.
cp *R $RUNDIR/scripts
cp *py $RUNDIR/scripts
cp html/all_files.html $RUNDIR/data/raw
env > $RUNDIR/data/raw/${RUN_ID}_env.txt

###############################################################################
# STEP 1: CREATE OUTPUT FILENAMES
TIME_FN=$RUNDIR/data/raw/${RUN_ID}_time_stdout.txt
CONFIG_FN=$RUNDIR/data/raw/${RUN_ID}_config_txt.txt
WORKLOAD_STDOUT=$RUNDIR/data/raw/${RUN_ID}_workload_stdout.txt
WORKLOAD_STDERR=$RUNDIR/data/raw/${RUN_ID}_workload_stderr.txt


###############################################################################
# STEP 2: START MONITORS USING SSH
CWD=$(pwd)
for SLAVE in $SLAVES
do
    debug_message "Collecting system snapshot on $SLAVE"
    # Gather system summary
    bash -c "./system_snapshot.sh $SLAVE && mv ${SLAVE}.html $RUNDIR/html/." &
    sleep 0.1
done
wait

for SLAVE in $SLAVES
do
    debug_message "Starting monitors on $SLAVE"
    define_filenames
    # Start amester first, since it takes a long time to start up
    if [ "$AMESTER_FLAG" == "1" ]
    then
        [ -z "$AMESTER_IP" ] && fatal_message "Need to export AMESTER_IP and BMC_IP when using AMESTER_FLAG"
        [ -z "$BMC_IP" ] && fatal_message "Need to export AMESTER_IP and BMC_IP when using AMESTER_FLAG"
        ./start_amester.sh $AMESTER_IP $AMESTER_FN $MEAS_DELAY_SEC $BMC_IP $AMESTER_USER $AMESTER_PASS
        if [ $? -ne 0 ] 
        then
          fatal_message "Problem starting amester on host \"$SLAVE\""
        fi
    fi
    # Start dstat monitor
    ./start_monitor.sh dstat $SLAVE $DSTAT_FN $MEAS_DELAY_SEC
    [ $? -ne 0 ] && fatal_message "Problem starting dstat on host \"$SLAVE\""
    if [ "$OCOUNT_FLAG" == "1" ]
    then
        ./start_ocount.sh $SLAVE $OCOUNT_FN $MEAS_DELAY_SEC $OCOUNT_EVENTS $OCOUNT_PID
        if [ $? -ne 0 ] 
        then
          fatal_message "Problem starting ocount on host \"$SLAVE\""
        fi
    fi
    if [ "$GPU_FLAG" == "1" ]
    then
        ./start_monitor.sh gpu $SLAVE $GPU_FN $MEAS_DELAY_SEC
        if [ $? -ne 0 ] 
        then
          fatal_message "Problem starting nvidia-smi on host \"$SLAVE\""
        fi
    fi
    if [ "$NMON_FLAG" == "1" ]
    then
        ./start_monitor.sh nmon $SLAVE $NMON_FN $MEAS_DELAY_SEC
        if [ $? -ne 0 ] 
        then
          fatal_message "Problem starting nmon on host \"$SLAVE\""
        fi
    fi
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
    echo gnu-time not found.  Exiting ... && exit 1
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

