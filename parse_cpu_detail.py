#!/usr/bin/python

'''
Input:  dstat cpu data (e.g. "dstat -t --cpu -C 0,1 --output dstat_fn 1"
Output: csv file
'''

import sys
import os
from datetime import datetime

def main(dstat_fn):
    '''
    '''
    with open(dstat_fn, 'r') as fid:
        blob = fid.read()
    fid.close()
    blob = "system" + blob.split('"system"')[1].strip()
    lines = blob.split('\n')
    num_cpu = (len(lines[0].split(',')) - 1)/6 # subtract 1 for time vector
    val_array = [[] for i in range(num_cpu)]
    START = True
    PRINT = False
    HEADER = True
    fields = ['TIME_SEC']
    lines = lines[2:]  # skip 2 header rows
    td_array = []
    for line in lines:
        vals = line.split(',')
        t = datetime.strptime(vals[0], '%d-%m %H:%M:%S')
        if START:
            t0 = t
            START = False
        td_array.append((t - t0).total_seconds())
        for cpu in range(num_cpu):
            cpu_usr = float(vals[cpu*6 + 1])
            cpu_sys = float(vals[cpu*6 + 2])
            val = cpu_usr + cpu_sys
            val_array[cpu].append(val)
            #js_string += '[%d,%d,%0.1f],' % (int(td), cpu, val)
    js_string = '{\n  "labels": [' + ','.join(['"%.0f' % i + '"' for i in td_array]) + '],\n'
    js_string += '  "datasets": [\n'
    for cpu in range(num_cpu - 1, -1, -1):
        js_string += '  {\n    "label": "%d",\n' % cpu
        js_string += '    "data": [' + ','.join([str(i) for i in val_array[cpu]]) + ']\n  }'
        if cpu == 0:
            js_string += ']\n}'
        else:
            js_string += ' ,'
    sys.stdout.write(js_string)

if __name__ == '__main__':
    main(sys.argv[1])
