#!/bin/bash

[ "$#" -ne "1" ] && echo Usage: $0 [HOSTNAME] && exit 1

OPERF_CMD="mkdir -p /tmp/pid_monitor/; \
           cd /tmp/pid_monitor/; \
           sudo rm -rf /tmp/pid_monitor/oprofile_data; \
           sudo operf --system-wide --events=PM_RUN_CYC:100000000:0:1:1 \
           2>/tmp/pid_monitor/operf.$1.stderr \
           1>/tmp/pid_monitor/operf.$1.stdout"

$(ssh $1 $OPERF_CMD) &

