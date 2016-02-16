#!/bin/bash

WORKLOAD_NAME=DATA
[[ "$#" -ne 0 ]] && WORKLOAD_NAME=$1
CWD=$(pwd)
mkdir -p $CWD/rundir/$WORKLOAD_NAME
chmod o+w $CWD/rundir/$WORKLOAD_NAME  # Other users can write to directory
RUNDIR=$CWD/rundir/$WORKLOAD_NAME/$(date +"%Y%m%d-%H%M%S")
RAWDIR=$RUNDIR/data/raw
FINALDIR=$RUNDIR/data/final
SCRIPTDIR=$RUNDIR/scripts
IMGDIR=$RUNDIR/img
HTMLDIR=$RUNDIR/html

[ -z "$VERBOSE" ] && VERBOSE=1
[ "$VERBOSE" -eq 1 ] && echo RUNDIR=$RUNDIR >&2
for DIR in data/raw data/final scripts img 
do
  mkdir -p $RUNDIR/$DIR
done

cp -R html $RUNDIR/html

cp $0 $SCRIPTDIR   # copy this script to the script directory

cd $RUNDIR/..
rm -f latest
ln -sf $(basename $RUNDIR) latest
echo $RUNDIR # DO NOT REMOVE

