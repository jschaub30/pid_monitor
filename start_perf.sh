#!/bin/bash

[ "$#" -ne "1" ] && echo Usage: $0 HOSTNAME && exit 1

REMOTE_DIR=/tmp/pid_monitor/perf
PERF_CMD="mkdir -p $REMOTE_DIR; \
          cd $REMOTE_DIR; \
          sudo rm -rf $REMOTE_DIR/*; \
          sudo perf record -a \
          2>/tmp/pid_monitor/perf/perf.$1.stderr \
          1>/tmp/pid_monitor/perf/perf.$1.stdout"

$(ssh $1 $PERF_CMD) &

