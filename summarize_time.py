#!/usr/bin/python

'''
Input:  config.json file
Output: CSV summary on stdout

Summarize /usr/bin/time data from all runs into CSV file
Jeremy Schaub
$ ./summarize-time.py $RUNDIR/html/config.json
'''

import sys
import os
import json

def main(args):
    '''Read config.json and create a table for all run_ids'''
    config_fn = os.path.realpath(args[0])
    os.chdir(os.path.dirname(config_fn))

    with open(config_fn, 'r') as fid:
        blob = fid.read()
    config = json.loads(blob)

    ids = config['run_ids']
    csv_rows = ['run id,exit status,elapsed time [sec]']
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
    stdout_ref = '<a href="%s">stdout</a>' % stdout_fn if os.path.isfile(stdout_fn) else ''
    stderr_ref = '<a href="%s">stderr</a>' % stderr_fn if os.path.isfile(stderr_fn) else ''
    time_ref = '<a href="%s">time</a>' % time_fn if os.path.isfile(time_fn) else ''
    exit_status, elapsed_time_sec, html_class = parse_time(time_fn)
    csv_row = ','.join([run_id, exit_status, elapsed_time_sec])
    html_row = '</td><td>'.join([run_id, exit_status, elapsed_time_sec, stdout_ref,
                     stderr_ref, time_ref])
    html_row = '<tr class="%s"><td>%s</td></tr>' % (html_class, html_row)
    return csv_row, html_row

def parse_time(time_fn):
    '''
    This parses the output of "/usr/bin/time --verbose"
    Parsing these fields:  exit_status, elapsed_time_sec
    '''
    try:
        with open(time_fn, 'r') as fid:
            blob = fid.read()
        exit_status = blob.split('Exit status: ')[1].split('\n')[0].strip()
        html_class = "success" if exit_status == 0 else "fail"
        find_str = 'Elapsed (wall clock) time (h:mm:ss or m:ss): '
        val = blob.split(find_str)[1].split('\n')[0].strip()
        if len(val.split(':')) == 2:   # m:ss
            val = str(int(val.split(':')[0])*60
                      + float(val.split(':')[1].strip()))
        elif len(val.split(':')) == 3:   # h:m:ss
            val = str(int(val.split(':')[0])*3600
                      + int(val.split(':')[1])*60
                      + float(val.split(':')[2].strip()))
        elapsed_time_sec = val

        return exit_status, elapsed_time_sec, html_class
    except Exception as err:
        html_class = "error"
        sys.stderr.write("!!! Error caught in script: %s\n" %
                         os.path.basename(__file__))
        sys.stderr.write("!!! while parsing " + time_fn + '\n')
        sys.stderr.write('!!! ' + str(err) + '\n')
        return 'NA', 'NA', html_class

if __name__ == '__main__':
    main(sys.argv[1:])
