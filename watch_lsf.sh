#!/bin/bash
# This script will continue to run until no Platform LSF jobs
# are running/pending

watch_lsf() {
  echo ##################################################
  echo $(date +"%Y%m%d-%H%M%S")
  bjobs

  RC=$(bjobs | wc -l)
  return $RC
}

trap 'exit 0' SIGTERM SIGINT # Kill process monitors if killed early
RC=1

while [ $RC -ne 0 ]
do
  watch_lsf
  sleep 10
done

echo System appears to be idle!
  
