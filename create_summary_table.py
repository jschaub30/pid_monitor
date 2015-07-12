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
import tidy.timeread


def create_table(config_fn):
    '''
    Read run_id's from config_fn
    config_fn is a json file with these fields:
        'run_ids'  <-- a list
        'data_dir' <-- a string
        'stdout_ext' <-- a string
        'stderr_ext' <-- a string
        'time_ext' <-- a string
    Example contents of config_fn:
    {
      'data_dir': '../data/raw',
      'stdout_ext': '.workload.stdout',
      'stderr_ext': '.workload.stderr',
      'time_ext': '.time'
      'run_ids': ['RUN1', 'RUN2'],
    }
    The output of /usr/bin/time should be in:
        ../data/raw/RUN1.time
        ../data/raw/RUN2.time
    The stdout files should be in:
        ../data/raw/RUN1.workload.stdout
        ../data/raw/RUN2.workload.stdout
    and similar for stderr
    Write summary.html in same directory as config_fn
    '''
    os.chdir(os.path.dirname(config_fn))
    config_fn = os.path.basename(config_fn)

    with open(config_fn, 'r') as fid:
        blob = fid.read()
    config = json.loads(blob)

    ids = config['run_ids']
    html_rows = []
    csv_rows = []
    fields = ['run_id', 'exit_status', 'stdout', 'stderr', 'time', 'elapsed_time_sec']
    csv_fields = ['run_id', 'exit_status', 'elapsed_time_sec']
    for run_id in ids:
        meas = time_measurement(run_id, config=config)
        html_rows.append(meas.rowhtml(fields=fields))
        csv_rows.append(meas.rowcsv(fields=csv_fields))
    table = html_table(fields, html_rows)
    with open('summary.html', 'w') as fid:
        fid.write(table)
    header = meas.headercsv(fields=csv_fields)
    table = csv_table(header, csv_rows)
    with open('summary.csv', 'w') as fid:
        fid.write(table)


def html_table(fields, rows):
    header_row = '<tr>\n<th>%s</th>\n</tr>\n' % ('</th>\n<th>'.join(fields))
    table = '<table>\n' + header_row
    for row in rows:
        table += row
    table += '</table>\n'
    return table

def csv_table(header, rows):
    table = header + '\n'
    for row in rows:
        table += row + '\n'
    return table


def time_measurement(run_id, config=None):
    '''
    Create a measurement instance that summarizes the run
    Add fields that link to the time, stdout and stderr files
    '''
    data_dir = config['data_dir']
    time_fn = os.path.join(data_dir, run_id + config['time_ext'])
    meas = tidy.timeread.TimeMeasurement()
    meas.parse(time_fn)
    meas.addfield('run_id', run_id)

    time_ref = '<a href="%s">time</a>' % time_fn if os.path.isfile(
        time_fn) else ''
    meas.addfield('time', time_ref)

    stdout_fn = os.path.join(data_dir, run_id + config['stdout_ext'])
    stdout_ref = '<a href="%s">stdout</a>' % stdout_fn if os.path.isfile(
        stdout_fn) else ''
    meas.addfield('stdout', stdout_ref)

    stderr_fn = os.path.join(data_dir, run_id + config['stderr_ext'])
    stderr_ref = '<a href="%s">stderr</a>' % stderr_fn if os.path.isfile(
        stderr_fn) else ''
    meas.addfield('stderr', stderr_ref)
    return meas

if __name__ == '__main__':
    create_table(sys.argv[1])
