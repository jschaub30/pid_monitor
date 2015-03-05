#!/bin/bash
COUNTER=0
DELAY=$2

[[ $# -lt "2" ]] && DELAY=1
while [ 1 ]; do
	echo '==--=='
	date
	#echo 'process cmd'
#	pgrep $1
	ps -C $1 -o pid,%cpu,%mem,cmd 
	#echo 'top 10'
	#top -b -n 1 | head -n 17 | tail -n 11
	sleep $DELAY
	#echo '--==--'
	#echo
done
