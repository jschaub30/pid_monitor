#!/bin/bash
# This script uses the pid_monitor to capture data using the AMESTER tool
# It assumes you have:
# - installed amester (http://amester.austin.ibm.com/download.html) on AMESTER_IP
# - use the watchsensors.tcl script downloaded here (IBM internal only)
#     http://arlab093.austin.ibm.com/blog/?p=3332

export WORKLOAD_NAME=EXAMPLE-AMESTER
export DESCRIPTION="Using amester and stream to measure memory bandwidth"
export MEAS_DELAY_SEC=1  # Delay between each measurement
export AMESTER_FLAG=1
export AMESTER_IP=  # The IP of the machine where amester is installed
export BMC_IP=      # The IP of the service processor managing the power8
#export BMC_USER=              # BMC username
#export BMC_PASS=              # BMC password


# To demonstrate memory bandwidth, download and compile the stream benchmark
WD=$(pwd)
mkdir -p stream
cd stream
[ ! -e stream_5-10_posix_memalign.c ] && wget http://www.cs.virginia.edu/stream/FTP/Code/Versions/stream_5-10_posix_memalign.c
[ ! -e "stream.96M" ] && gcc -O2 -fopenmp -DNTIMES=40000 -DSTREAM_ARRAY_SIZE=$((4*1024*1024)) \
                         -O stream_5-10_posix_memalign.c -o stream.96M
[ ! -e "stream.768M" ] && gcc -O2 -fopenmp -DNTIMES=2000 -DSTREAM_ARRAY_SIZE=$((32*1024*1024)) \
                         -O stream_5-10_posix_memalign.c -o stream.768M
cd $WD

export RUNDIR=$(./setup-run.sh $WORKLOAD_NAME)
export WORKLOAD_DIR="$WD/stream"             # The workload working directory

export RUN_ID="SIZE_96M"
export WORKLOAD_CMD=./stream.96M
./run-workload.sh

export RUN_ID="SIZE_768M"
export WORKLOAD_CMD=./stream.768M
./run-workload.sh
