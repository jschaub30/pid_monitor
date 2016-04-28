#!/usr/bin/python
import sys
import os
import collections
import json


def main(argList):
	# Process command line args

	# read input
	if len(argList) < 1:
		usage()
		sys.exit()
	else:
		fl = open(argList[0], 'r').readlines()
	
 	# print the help menu
 	if '-h' in argList:
 		usage()
 		sys.exit()

	# interval flag adds elapsed time per capture 
	if '-interval' in argList:
 		interval = int(argList[argList.index('-interval') + 1])
 	else:
 		interval = 1

	# threshold flag filters out CPUs not handeling interrupts  
	if '-threshold' in argList:
 		threshold = int(argList[argList.index('-threshold') + 1])
	else:
		threshold = 0

	# parse input file and create records
	recordDict={}
	record = []
	samplesQueue = []
	try:
		for i in fl[1:]:
			if '~~##ARL##~~' not in i:
				record.append(i)
			else:
				samplesQueue.append(parseRecordQuque(record))
				record = []
		sampleRatesQueue = IRQperSecQuque(samplesQueue, interval)
	except:
		print 'processIRObyQUEUE Exception Interput File: can not process interupt file'

	try:	
		if threshold == 0:
			ob =  str(json.dumps(createJSON(sampleRatesQueue), sort_keys = False, indent = 1))
#			ob.replace('OrderedDict','').replace('(','{').replace(')','}')
			print ob
		else:
			ob =  str(json.dumps(createJSON(thresholdFilter(sampleRatesQueue, threshold)), sort_keys = False, indent = 1))
			print ob
	except:
		print 'processIRObyQUEUE Exception JSON: can not generate json string.'
		print 'processIRObyQUEUE Exception JSON: likely your threshold is to high resulting in no data'
	
def thresholdFilter(x, threshold):
	filtered = {}
	for i in x:
		if (reduce(lambda y,z: y+z, i[1])/ len(i[1])) > threshold:
			filtered[i[0]] = i[1]
	return filtered.items()

def createJSON(x):
	obj2ser = collections.OrderedDict()
	obj2ser['labels'] = range(len(x[0][1]))
	r = []
	for i in sorted(x, reverse = True):
		t = collections.OrderedDict()
		t['label'] = i[0]
		t['data'] = i[1]
		r.append(t)
	obj2ser['datasets'] = r	
#	print(json.dumps(obj2ser))	
	return obj2ser

def IRQperSecQuque(samples, interval):
	irqRates = {}
	for i in samples[0]:
		irqRates[i[0]] = []
	for i in samples:
		for j in i:
			v = irqRates.get(j[0])
			irqRates[j[0]].append(j[1])
	
	rates = []
	for i in irqRates.items():
		r = []
		for j in range(len(i[1])-1):
			r.append((i[1][j+1] - i[1][j])/interval)
		rates.append((i[0],r))				
	return rates		



def parseRecordQuque(record):
	d = {}
	if 'CPU' in record[0]:
		cpuCount = len(record[0].split())
	else:
		return d.items()
		
	for i in record[1:]:
		if len(i.split()) > cpuCount + 1:
			row = i.split()
			irq = '('+ row[0].strip(':') + ')'
			acc = reduce(lambda x,y: int(x) + int(y), row[1:cpuCount+1])
			irqname = " ".join(row[cpuCount+2:])
			d[irq+irqname] = acc
	
	return d.items()
		
		
	
						
				
				
def usage():
	print 'usage processIRQbyQUEUE.py <input> -options'
	print 'in put file is genarated from appending cat /proc/interupt and delimitor'
	print '-interval elapsed time in seconds per capture of /proc/interrupts default is 1'
	print '-threshold filters results that average below the threshold'


if __name__ == '__main__':
	main(sys.argv[1:])
