#!/bin/bash

RUNTYPE=DATA
[[ $# -gt 1 ]] && RUNTYPE=$1

CWD=$(pwd)
export RUNDIR=../rundir/$(date +"$RUNTYPE-%Y%m%d-%H%M")
export RAWDIR=$RUNDIR/data/raw
export FINALDIR=$RUNDIR/data/final
export SCRIPTDIR=$RUNDIR/scripts
export IMGDIR=$RUNDIR/img
export HTMLDIR=$RUNDIR/html
mkdir -p $RAWDIR
mkdir -p $FINALDIR
mkdir -p $SCRIPTDIR
mkdir -p $IMGDIR
rm -f ../rundir/$RUNTYPE-latest
ln -sf $RUNDIR ../rundir/$RUNTYPE-latest
cp $0 $SCRIPTDIR   # copy this script to the script directory

