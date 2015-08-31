#!/usr/bin/python

'''
Input:  config.json file
Output: HTML summary on stdout

Summarize spark stderr filess from all runs into HTML table
Jeremy Schaub
$ ./create_summary_tables.py $RUNDIR/html/config.json
'''

import sys
import os
import json
import tidy.sparkread


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
    data_dir = config['data_dir']
    table_rows = []
    header_fields = ['run_id', 'stdout', 'stderr', 'spill_count',
                     'total_time_sec', 'stage 0 [sec]', 'stage 1 [sec]',
                     'stage 2 [sec]']
    for run_id in ids:
        sys.stderr.write("Parsing %s stderr file\n" % run_id)
        meas = spark_measurement(run_id, path=data_dir, num_stages=3)
        table_rows.append(meas.rowhtml(header_fields=header_fields))
    table = html_table(header_fields, table_rows)
    #with open('spark.html', 'w') as fid:
    #    fid.write(table)
    sys.stdout.write(table)


def html_table(fields, rows):
    header_row = '<tr>\n<th>%s</th>\n</tr>\n' % ('</th>\n<th>'.join(fields))
    table = '<table>\n' + header_row
    for row in rows:
        table += row
    table += '</table>\n'
    return table


def spark_measurement(run_id, path='', num_stages=0):
    '''
    Create a measurement instance that summarizes the run
    Add fields that link to the time, stdout and stderr files
    '''

    stderr_fn = os.path.join(path, run_id + '.workload.stderr')
    stderr_ref = '<a href="%s">stderr</a>' % stderr_fn if os.path.isfile(
        stderr_fn) else ''
    meas = tidy.sparkread.SparkMeasurement()
    meas.set_num_stages(num_stages)
    meas.parse(stderr_fn)
    meas.addfield('stderr', stderr_ref)

    stdout_fn = os.path.join(path, run_id + '.workload.stdout')
    stdout_ref = '<a href="%s">stdout</a>' % stdout_fn if os.path.isfile(
        stdout_fn) else ''
    meas.addfield('stdout', stdout_ref)
    meas.addfield('run_id', run_id)

    return meas

if __name__ == '__main__':
    create_table(sys.argv[1])
