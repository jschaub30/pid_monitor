#!/bin/bash
DELAY=$1

[[ $# -lt "1" ]] && DELAY=1

while [ 1 ]; do
	echo '==--=='
	date
	ps r -o pid,%cpu,%mem,cmd,user
	sleep $DELAY
	#echo 'top 10'
	#top -b -n 1 | head -n 17 | tail -n 11
	#echo '--==--'
	#echo
done
