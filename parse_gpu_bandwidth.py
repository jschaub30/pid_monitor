#!/usr/bin/python

'''
Input:  raw csv file from nvprof (data/raw directory)
Output: gpu_bw csv file (data/final directory)
'''

import sys
from datetime import datetime
import numpy as np

def main(input_fn):
    '''
    Read nvprof csv file and write individual csv files with HtoD, DtoH and 
    DtoD bandwidth
    '''
    with open(input_fn, 'r') as fid:
        blob = fid.read()
    lines = blob.split('\n')

    out_string = "time,HtoD,DtoH,DtoD\n"

    start = False
    for line in lines:
        if start and len(line) > 10:
            HtoD, DtoH, DtoD = "","",""
            write_flag = False
            fields = line.split(',')
            startTime = fields[0]
            throughput = fields[idx]
            if 'memcpy HtoD' in line:
                write_flag = True
                HtoD = throughput
            if 'memcpy DtoH' in line:
                write_flag = True
                DtoH = throughput
            if 'memcpy DtoD' in line:
                write_flag = True
                DtoD = throughput
            if write_flag:
                out_string += ','.join([startTime, HtoD, DtoH, DtoD]) + '\n'

        if '"Start","Duration"' in line:
            start = True
            fields = line.replace('"', '').split(',')
            idx = fields.index('Throughput')

    # Now write output csv files
    out_fn = input_fn.replace('gpu_bandwidth.csv', 
            'gpu_bandwidth.timeseries.csv')
    if (out_fn == input_fn)
        out_fn = out_fn + '1'
    # write data to data/final directory
    #out_fn = out_fn.replace('data/raw', 'data/final')
    with open(out_fn, 'w') as fid:
        fid.write(out_string)
    #print 'Created file ' + out_fn

if __name__ == '__main__':
    main(sys.argv[1])

