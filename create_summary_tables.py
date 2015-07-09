#!/usr/bin/python

'''
Input:  config.json file
Output: HTML summary as "summary.html" in same directory as config.json

Summarize /usr/bin/time data from all runs into HTML table
Jeremy Schaub
$ ./create_summary_tables.py $RUNDIR/html/config.json
'''

import sys
import os
import json
#from tidy import timeread
import tidy.timeread

def create_table(config_fn):
    '''
    Read run_id's from config.json
    Summarize result for each run_id
    Write summary.html in same directory as config.json
    '''
    os.chdir(os.path.dirname(config_fn))
    config_fn = os.path.basename(config_fn)

    with open(config_fn, 'r') as fid:
        blob = fid.read()
    config = json.loads(blob)

    ids = config['run_ids']
    if 'data_dir' in config.keys():
        data_dir = config['data_dir']
    else:
        data_dir = os.path.join('..', 'data', 'raw')
    html_rows = []
    fields = ['exit_status', 'stdout', 'stderr', 'time', 'elapsed_time_sec']
    for run_id in ids:
        meas = time_measurement(run_id, path=data_dir)
        html_rows.append(meas.rowhtml(fields=fields))
    table = html_table(fields, html_rows)
    with open('summary.html', 'w') as fid:
        fid.write(table)


def html_table(fields, rows):
    table = '<table>\n<tr>\n<th>%s</th>\n</tr>\n' % ('</th>\n<th>'.join(fields))
    for row in rows:
        table += row
    table += '</table>\n'
    return table

def time_measurement(run_id, path=''):
    '''
    Create a measurement instance that summarizes the run
    Add fields that link to the time, stdout and stderr files
    '''

    time_fn = os.path.join(path, run_id + '.time.stdout')
    time_ref = '<a href="%s">time</a>' % time_fn if os.path.isfile(
        time_fn) else ''
    meas = tidy.timeread.Measurement()
    meas.parse(time_fn)
    meas.addfield('time', time_ref)

    stdout_fn = os.path.join(path, run_id + '.workload.stdout')
    stdout_ref = '<a href="%s">stdout</a>' % stdout_fn if os.path.isfile(
        stdout_fn) else ''
    meas.addfield('stdout', stdout_ref)

    stderr_fn = os.path.join(path, run_id + '.workload.stderr')
    stderr_ref = '<a href="%s">stderr</a>' % stderr_fn if os.path.isfile(
        stderr_fn) else ''
    meas.addfield('stderr', stderr_ref)
    return meas

if __name__ == '__main__':
    create_table(sys.argv[1])
