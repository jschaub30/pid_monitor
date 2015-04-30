#!/usr/bin/python

'''
Input:  config.json file
Output: stdout

Summarize /usr/bin/time data from all runs into CSV file
Jeremy Schaub
$ ./summarize-time.py $RUNDIR/html/config.clean.json
'''

import sys
import os
import json

# time fn -> RC, elapsed
# validate fn -> valid
# workload stderr -> stage 0/1/2 times


def main(argList):
    # JSON --> ID list
    config_fn = os.path.realpath(argList[0])

    with open (config_fn, 'r') as f:
        blob = f.read()
    config =  json.loads(blob)

    ids = config['run_ids']
    header = 'run id,exit status,elapsed time [sec]'
    rows = ''
    for run_id in ids:
        raw_directory = os.path.join(os.path.dirname(config_fn),
                                '..', 'data', 'raw')
        fn = os.path.join(raw_directory, run_id + '.time.stdout')
        exit_status, elapsed_time_sec = parse_time(fn)
        rows += ','.join([run_id, exit_status, elapsed_time_sec]) + '\n'
    sys.stdout.write(header + '\n' + rows)

def parse_time(fn):
    '''
    This parses the output of "/usr/bin/time --verbose"
    Parsing these fields:  exit_status, user_time_sec, elapsed_time_sec, cpu_percent
    '''
    try:
        with open (fn, 'r') as f:
            blob = f.read()
        exit_status = blob.split('Exit status: ')[1].split('\n')[0].strip()
        val = blob.split('Elapsed (wall clock) time (h:mm:ss or m:ss): ')[1].split('\n')[0].strip()
        if len(val.split(':'))==2:   # m:ss
            val = str(int(val.split(':')[0])*60 + float(val.split(':')[1].strip()))
        elif len(val.split(':'))==3:   # h:m:ss
            val = str(int(val.split(':')[0])*3600 + int(val.split(':')[1])*60 + float(val.split(':')[2].strip()))
        elapsed_time_sec = val
    
        return exit_status, elapsed_time_sec
    except Exception as e:
        sys.stderr.write("Error caught parsing " + fn + '\n')
        sys.stderr.write(str(e) + '\n')
    return '-1'

if __name__ == '__main__':
    main(sys.argv[1:])
