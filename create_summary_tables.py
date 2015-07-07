#!/usr/bin/python

'''
Input:  config.json file
Output: CSV summary as "summary.csv"
        HTML summary as "summary.html"

Summarize /usr/bin/time data from all runs into CSV file
Jeremy Schaub
$ ./create_summary_tables.py $RUNDIR/html/config.json
'''

import sys
import os
import json
#from tidy import timeread
import tidy.timeread

def create_tables(config_fn):
    '''
    Read run_id's from config.json
    Summarize result for each run_id
    Write summary.csv and summary.html in same directory as config.json
    '''
    os.chdir(os.path.dirname(config_fn))

    with open(config_fn, 'r') as fid:
        blob = fid.read()
    config = json.loads(blob)

    ids = config['run_ids']
    csv_rows = ['run_id,exit_status,elapsed_time_sec,']
    html_rows = '</th><th>'.join(['Run ID', 'Exit Status',
                                  'Elapsed Time [sec]', '', '', ''])
    html_rows = ['<table>\n<tr><th>%s</th></tr>' % html_rows]
    for run_id in ids:
        csv_row, html_row = create_row(run_id)
        csv_rows.append(csv_row)
        html_rows.append(html_row)
    html_rows.append('</table>')
    with open('summary.csv', 'w') as fid:
        fid.write('\n'.join(csv_rows) + '\n')
    with open('summary.html', 'w') as fid:
        fid.write('\n'.join(html_rows) + '\n')


def create_row(run_id):
    '''Return a CSV line that summarizes the run'''
    stdout_fn = os.path.join('..', 'data', 'raw', run_id + '.workload.stdout')
    stderr_fn = os.path.join('..', 'data', 'raw', run_id + '.workload.stderr')
    time_fn = os.path.join('..', 'data', 'raw', run_id + '.time.stdout')
    stdout_ref = '<a href="%s">stdout</a>' % stdout_fn if os.path.isfile(
        stdout_fn) else ''
    stderr_ref = '<a href="%s">stderr</a>' % stderr_fn if os.path.isfile(
        stderr_fn) else ''
    time_ref = '<a href="%s">time</a>' % time_fn if os.path.isfile(
        time_fn) else ''
    meas = tidy.timeread.parse(time_fn)
    html_class = "success" if int(meas.exit_status) == 0 else "fail"
    csv_row = ','.join([run_id, meas.exit_status, meas.elapsed_time_sec])
    html_row = '</td><td>'.join([run_id, meas.exit_status,
                                 meas.elapsed_time_sec, stdout_ref,
                                 stderr_ref, time_ref])
    html_row = '<tr class="%s"><td>%s</td></tr>' % (html_class, html_row)
    return csv_row, html_row

if __name__ == '__main__':
    create_tables(sys.argv[1])
