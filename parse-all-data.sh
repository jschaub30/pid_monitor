##!/bin/bash

BLOB=$(<../html/config.json)
SLAVES=$(echo $BLOB | perl -pe 's/.*slaves":\["(.*)"\],.*/\1/' | tr "," " " | tr "\"" " ")
RUN_IDS=$(echo $BLOB | perl -pe 's/.*run_ids":\["(.*)"\].*/\1/' | tr "," " " | tr "\"" " ")

define_filenames() {
  RAWDIR=${RUNDIR}/data/raw
  DSTAT_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_dstat.csv
  OCOUNT_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_ocount
  NMON_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_nmon
  GPU_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_gpu
  PERF_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_perf_report
  AMESTER_FN=${RAWDIR}/${RUN_ID}_${SLAVE}_amester
}

###############################################################################
# STEP 6: ANALYZE DATA AND CREATE HTML CHARTS
CWD=$(pwd)
# Process data from all runs into HTML tables
./create_summary_table.py ../html/config.json > ../html/summary.html
for RUN_ID in $RUN_IDS
  do
  for SLAVE in $SLAVES
  do
    define_filenames
    echo Parsing ${RUN_ID}:${SLAVE}
    [ -e $OCOUNT_FN ] && ./parse_ocount.py $OCOUNT_FN > $OCOUNT_FN.csv
    [ -e $OCOUNT_FN ] && ./memory_bw.R $OCOUNT_FN.csv > $OCOUNT_FN.memory_bw.csv
    [ -e $GPU_FN ] && [ "$GPU_FLAG" == "1" ] && ./parse_gpu.R $GPU_FN
    [ -e $GPU_FN ] && ./parse_gpu_detail.R $GPU_FN
    [ -e $AMESTER_FN ] && ./parse_amester.R $AMESTER_FN
  done
done

# Create tarball of raw data
cd ../data
tar cfz all_raw_data.tar.gz raw
cd $CWD

