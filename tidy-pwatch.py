#!/usr/bin/python

'''
Input:  run_directory
Output: stdout

Tidy output of pwatch process monitor into CSV file
Jeremy Schaub
$ ./tidy_pwatch.py [raw_directory]
'''

import sys, os, glob
from datetime import datetime

class Measurement:
    '''
    Data structure for pwatch measurement
    '''
    def __init__(self):
        self.timestamp = ''
        self.elapsed_time_sec = ''
        self.pid = ''
        self.cpu_pct = ''
        self.mem_pct = ''  # These are strings but each string must represent a number/percent

    def fields(self):
        '''
        Returns a list of fields in the data structure
        '''
        fields = [i for i in self.__dict__.keys() if i[:1] != '_']
        return fields

    def header(self):
        '''
        Returns a csv string with all header fields
        '''
        return ','.join(self.fields())

    def row(self):
        '''
        Returns a csv string with all data fields
        '''
        fields = self.fields()
        values = [str(getattr(self, field)) for field in fields]
        return ','.join(values)

def main(argList):
    run_fn = argList[0]
    workload_cmd = argList[1]
    m = Measurement()
    print(m.header())

    fields = parse_pwatch(m, run_fn, workload_cmd)

def parse_time(m, fn):
    '''
    This parses the output of "/usr/bin/time --verbose"
    Parsing these fields:  exit_status, user_time_sec, elapsed_time_sec, cpu_percent
    '''
    with open (fn, 'r') as f:
        blob = f.read()
    time_fields = ['Exit status', 'User time (seconds)', 'System time (seconds)']
    val = blob.split('Exit status: ')[1].split('\n')[0].strip()
    if val == '0':
        m.success = True
    else:
        m.success = False
    meas_types = ['exit_status']
    meas_vals = [val]
    val = blob.split('User time (seconds): ')[1].split('\n')[0].strip()
    meas_types.append('user_time_sec')
    meas_vals.append(val)
    val = blob.split('Elapsed (wall clock) time (h:mm:ss or m:ss): ')[1].split('\n')[0].strip()
    if len(val.split(':'))==2:   # m:ss
        val = str(int(val.split(':')[0])*60 + float(val.split(':')[1].strip()))
    elif len(val.split(':'))==3:   # h:m:ss
        val = str(int(val.split(':')[0])*3600 + int(val.split(':')[1])*60 + float(val.split(':')[2].strip()))
    meas_types.append('elapsed_time_sec')
    meas_vals.append(val)
    val = blob.split('Percent of CPU this job got: ')[1].split('\n')[0].strip('%')
    meas_types.append('cpu_percent')
    meas_vals.append(val)
    return [meas_types, meas_vals]

    return m

def parse_pwatch(m, fn, workload_cmd):
    '''
    Custom parser for pwatch program
    '''
    with open (fn, 'r') as f:
        for line in f:
            if 'CST 201' in line:
                # Time format is "Mon Feb 16 11:38:53 CST 2015"
                if 'ts0' in locals():
                    ts = datetime.strptime(' '.join(line.split(' ')[1:]).strip(), "%b %d %H:%M:%S %Z %Y")
                    m.elapsed_time_sec = (ts-ts0).seconds
                else:
                    ts0 = datetime.strptime(' '.join(line.split(' ')[1:]).strip(), "%b %d %H:%M:%S %Z %Y")
                    m.elapsed_time_sec = 0
                m.timestamp = datetime.strptime(' '.join(line.split(' ')[1:]).strip(), "%b %d %H:%M:%S %Z %Y").strftime("%Y-%m-%d %H:%M:%S")
            if workload_cmd in line:
                vals = line.strip().replace('  ', ' ').split(' ')
                m.pid = vals[0]
                m.cpu_pct = vals[1]
                m.mem_pct = vals[2]
                print m.row()
                
    return m.fields()

if __name__ == '__main__':
    main(sys.argv[1:])
