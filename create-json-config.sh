#!/bin/bash
# Creates JSON header based on environment variables

[[ -z "$RUNDIR" ]] && echo $0: !!!!!!!!!! Warning!  RUNDIR not set
[[ -z "$WORKLOAD_NAME" ]] && WORKLOAD_NAME="WORKLOAD"
[[ -z "$X_LABEL" ]] && X_LABEL="RUN ID"
[[ -z "$DESCRIPTION" ]] && DESCRIPTION="DESCRIPTION"
[[ -z "$DATA_DIR" ]] && DATA_DIR="../data/raw"
[[ -z "$STDOUT_EXT" ]] && STDOUT_EXT="_workload_stdout.txt"
[[ -z "$STDERR_EXT" ]] && STDERR_EXT="_workload_stderr.txt"
[[ -z "$TIME_EXT" ]] && TIME_EXT="_time_stdout.txt"
[[ -z "$SLAVES" ]] && SLAVES=$(hostname)
[ "$GPU_DETAIL_FLAG" == "1" ] && GPU_FLAG=1

CONFIG_FN=$RUNDIR/html/config.json

echo \{\"workload\":\"$WORKLOAD_NAME\", > $CONFIG_FN
echo \"date\":\"$(date)\", >> $CONFIG_FN
echo \"hostname\":\"$(hostname -s)\", >> $CONFIG_FN
echo \"data_dir\":\"$DATA_DIR\", >> $CONFIG_FN
echo \"description\":\"$DESCRIPTION\", >> $CONFIG_FN
echo \"monitors\":[\"dstat\" >> $CONFIG_FN
[ "$CPU_DETAIL_FLAG" == "1" ] && echo ,\"cpu_detail\" >> $CONFIG_FN
[ "$GPU_FLAG" == "1" ] && echo ,\"gpu\" >> $CONFIG_FN
[ "$GPU_DETAIL_FLAG" == "1" ] && echo ,\"gpu_detail\" >> $CONFIG_FN
[ "$P8_MEMBW_FLAG" == "1" ] && echo ,\"membw\" >> $CONFIG_FN
[ "$HASWELL_MEMBW_FLAG" == "1" ] && echo ,\"membw\" >> $CONFIG_FN
[ "$PERF_FLAG" == "1" ] && echo ,\"perf\" >> $CONFIG_FN
[ "$AMESTER_FLAG" == "1" ] && echo ,\"amester\" >> $CONFIG_FN
echo ], >> $CONFIG_FN
echo \"xlabel\":\"$X_LABEL\", >> $CONFIG_FN
echo \"stdout_ext\":\"$STDOUT_EXT\", >> $CONFIG_FN
echo \"stderr_ext\":\"$STDERR_EXT\", >> $CONFIG_FN
echo \"time_ext\":\"$TIME_EXT\", >> $CONFIG_FN
ARR="\"slaves\":["
for SLAVE in $SLAVES
do
  ARR=${ARR}\"${SLAVE}\",
done
echo $ARR | sed 's/.$/],/' >> $CONFIG_FN
echo \"run_ids\":\[\"$RUN_ID\"\]\} >> $CONFIG_FN
