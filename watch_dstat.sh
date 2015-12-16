#!/bin/bash

#"procs",,,"memory usage",,,,"paging",,"dsk/total",,"system",,"total cpu usage",,,,,,"system","net/total",
VARS=( run  blk  new  used  buff  cach  free  in  out  read  writ  int  csw  usr  sys  idl  wai  hiq  siq  time  recv  send )

THRESH[10]=2000 #read
THRESH[11]=2000 #write
THRESH[12]=100 #int
THRESH[13]=100 #csw
THRESH[14]=2   #usr
THRESH[15]=2   #sys
THRESH[17]=2   #wai
THRESH[21]=2000 #recv
THRESH[22]=2000 #send

watch_dstat () {
  echo ##################################################
  echo $(date +"%Y%m%d-%H%M%S")
  dstat -v --time --net --output tmp.csv 1 1 >/dev/null
  VALS=$(tail -n 1 tmp.csv)

  RC=0
  I=1
  for VAR in ${VARS[*]}
  do
    VAL=$(echo $VALS | cut -d, -f $I)
    #echo $VAR=$VAL
    if [ ! -z ${THRESH[$I]} ]
    then
      VAL=$( printf "%.0f" $VAL )  # Convert to integer
      if [ $VAL -gt ${THRESH[$I]} ] 
      then
        echo "LIMIT exceeded for $VAR: $VAL > ${THRESH[$I]}"
        RC=$((RC+1))
      fi
    fi
    I=$((I+1))
  done
  ps aux  --sort=-pcpu | head -5

  return $RC
}

trap 'exit 0' SIGTERM SIGINT # Kill process monitors if killed early
RC=1

while [ $RC -ne 0 ]
do
  watch_dstat
  sleep 10
done

echo System appears to be idle!
  
