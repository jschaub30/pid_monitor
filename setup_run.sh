#!/bin/bash

RUNTYPE=DATA
[[ $# -gt 1 ]] && RUNTYPE=$1

CWD=$(pwd)
RUNDIR=../rundir/$(date +"$RUNTYPE-%Y%m%d-%H%M")
RAWDIR=$RUNDIR/data/raw
FINALDIR=$RUNDIR/data/final
SCRIPTDIR=$RUNDIR/scripts
IMGDIR=$RUNDIR/img
HTMLDIR=$RUNDIR/html
mkdir -p $RAWDIR
mkdir -p $FINALDIR
mkdir -p $SCRIPTDIR
mkdir -p $IMGDIR
rm -f ../rundir/$RUNTYPE-latest
ln -sf $RUNDIR ../rundir/$RUNTYPE-latest
cp $0 $SCRIPTDIR   # copy this script to the script directory
echo $RUNDIR
