#!/usr/bin/python
import sys
import os
import glob
from datetime import datetime
from multiprocessing import Pool

def main(argList):	
	# Process command line args
	if len(argList) < 2:
		usage()
		sys.exit()
	else:
		rootDir = argList[0]
		prefix = argList[1]
		#fileList = filter(lambda x: x.startswith(prefix), next(os.walk(rootDir))[2])
		fileList = glob.glob(os.path.join(rootDir, prefix + '*'))
		print "Validating " + os.path.join(rootDir)
		
	if '-threads' in argList:
		threads = int(argList[argList.index('-threads') + 1])
		#print "len(fileList)=%d" % (len(fileList))
		#print "threads=%d" % (threads)
		if threads > len(fileList):
			threads = len(fileList)
	else:
		threads = 1

	if '-maxthreads' in argList:
		threads = max(192, len(fileList))

	pool = Pool(processes=threads)
	result = pool.map(validate, fileList)
	
	
	stitch2(result)
	errors(result)


def stitch(result):
	c = 0
	rsort = sorted(result, key=lambda x: x[1][0])
	elements = []
	for i in rsort:
		elements.append(i[1][1])
		elements.append(i[1][2])
	esort = sorted(elements)
	if esort != elements:
		print "stitch errors"
	return 
	

def stitch2(result):
	c = 0
	rsort = sorted(result, key=lambda x: x[1][0])
	outFile = open('error.stitch' , 'w')
	elements =[]
	for i in rsort:
		elements.append([i[1][0], i[1][1]])
		elements.append([i[1][0], i[1][2]])
	del elements[0]
	while len(elements) > 1:
		if (elements[0][1] > elements[1][1]): 
			outFile.write(elements[0][0].strip('\n') + ' to ' + elements[1][0].strip('\n') + '\n')
			c +=1
		del elements[0]
		del elements[1]
        if c>0:
            print "!!!!!!!!!!!!!!!!!!!! STITCHING VALIDAION ERRORS !!!!!!!!!!!!!!!!!!!!!!!\n" *4
	print 'stitch errors = ' + str(c)
	return 	
	

def errors(result):
	c = 0
	for i in result:
		c= c+ i[0]
        if c>0:
            print "!!!!!!!!!!!!!!!!!!!! NON-STITCHING VALIDATION ERRORS !!!!!!!!!!!!!!!!!!!!!!!\n" *4
	print 'non-stitching error count = ' + str(c)
	return

def validate(fileName):
	#print "Validating " + fileName
	ecount = 0
	inF = open(fileName, 'r')
	#outF = open('error.' + fileName , 'w')
	outF = open(os.path.join(os.path.dirname(fileName),  '.error' + os.path.basename(fileName)),  'w')
	first = inF.readline()
	prev = first
	for i in inF:
		if prev > i:
			outF.write(prev.strip('\r\n') + ' > ' + i.strip('\r\n') + '\n')
			prev = i
			ecount +=1
		else:
			prev = i
	return [ecount, [fileName, first, i]]	
	

	
def usage():
	print 'teraval.py <root dir> <prefix> <options>'
	print 'assumtion on postfix is leading 0'
	
	
if __name__ == '__main__':
	main(sys.argv[1:])
