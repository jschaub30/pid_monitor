#!/bin/bash
COUNTER=0
while [ 1 ]; do
	echo '==--=='
	date
	echo 'process cmd'
#	pgrep $1
	ps -C $1 -o pid,%cpu,%mem,cmd 
	echo 'top 10'
	top -b -n 1 | head -n 17 | tail -n 11
	sleep 1 
	echo '--==--'
	echo
done
