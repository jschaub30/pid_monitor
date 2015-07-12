#!/bin/bash
# Creates JSON header based on environment variables

[[ -z "$RUNDIR" ]] && echo $0: !!!!!!!!!! Warning!  RUNDIR not set
[[ -z "$WORKLOAD_NAME" ]] && WORKLOAD_NAME="WORKLOAD"
[[ -z "$X_LABEL" ]] && X_LABEL="X label"
[[ -z "$DESCRIPTION" ]] && DESCRIPTION="DESCRIPTION"
[[ -z "$DATA_DIR" ]] && DATA_DIR="../data/raw"
[[ -z "$STDOUT_EXT" ]] && STDOUT_EXT=".workload.stdout"
[[ -z "$STDERR_EXT" ]] && STDERR_EXT=".workload.stderr"
[[ -z "$TIME_EXT" ]] && TIME_EXT=".time.stdout"
[[ -z "$SLAVES" ]] && SLAVES=$(hostname)

CONFIG_FH=$RUNDIR/html/config.json

echo \{\"workload\":\"$WORKLOAD_NAME\", > $CONFIG_FN
echo \"date\":\"$(date)\", >> $CONFIG_FN
echo \"hostname\":\"$(hostname -s)\", >> $CONFIG_FN
echo \"data_dir\":\"$DATA_DIR\", >> $CONFIG_FN
echo \"description\":\"$DESCRIPTION\", >> $CONFIG_FN
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
