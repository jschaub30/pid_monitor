#!/usr/bin/python

'''
Input:  ocount file (brief -b format)
Output: csv file
'''

import sys
import os

def main(ocount_fn):
    '''
    '''
    with open(ocount_fn, 'r') as fid:
        blob = fid.read()
    lines = blob.split('\n')
    START = False
    PRINT = False
    HEADER = True
    fields = ['TIME_SEC']
    for line in lines:
        if len(line) < 2:
            START = False
            PRINT = True
            if 'vals' in locals(): # a measurement exists
                if HEADER:
                    sys.stdout.write(','.join(fields) + '\n')
                    HEADER = False
                sys.stdout.write(','.join(vals) + '\n')
        if START:
            fieldname,count,pct_time = line.split(',')
            #vals.append(str(int(int(count)/float(pct_time)*100)))
            vals.append(count)
            if HEADER:
                fields.append(fieldname)
        if line.startswith('t:'):  # start of new measurement
            t = int(line.split(':')[1])
            if HEADER:
                t0 = t
            vals = [str(t - t0)]
            PRINT = False
            START = True

if __name__ == '__main__':
    main(sys.argv[1])
