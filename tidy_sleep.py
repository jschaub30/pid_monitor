#!/usr/bin/python

'''
Input:  run directory
Output: stdout

'''
# Tidy output of generic sleep measurement into CSV file
# Jeremy Schaub
# ./tidy_sleep.py [raw_directory]

import sys, os, glob

class Measurement:
    '''
    Data structure for _tst_ark measurement
    '''
    def __init__(self, run_directory):
        global cfg_fields
        cfg_fields = ['hostname', 'kernel']  # MUST MATCH THE CONFIG FILE
        self.run_directory = os.path.basename(run_directory.strip('/'))

        for field in cfg_fields:
            setattr(self, field, '')
        self.run_fn = ''
        self.config_fn = ''
        self.time_fn = ''
        self.timestamp = ''
        self.meas_type = ''
        self.meas_value = ''  # These are strings but each string must represent a number

        # /usr/bin/time parameters
        self.success = True
        self.exit_status = 0

        # workload specific parameters
        #self.meas_name = 0

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
    run_directory = argList[0]
    raw_directory = run_directory.rstrip('/') + '/data/raw/'
    m = Measurement(run_directory)
    fields0 = Measurement(run_directory).fields()  # expected number of fields. used in asserts below
    print(m.header())

    all_files = glob.glob(raw_directory + '*config.txt*')
    assert len(all_files)>0, "No config files found!"

    for fn in sorted(all_files):
        '''
        Parse input files:
        1. run_log.[timestamp].config.txt  <-- Config file
        2. run_log.[timestamp].time.txt    <-- /usr/bin/time file
        3. run_log.[timestamp].txt         <-- Log file (don't actually parse this one)
        '''
        # Instantiate new classes for each file
        m = Measurement(run_directory)
        m.config_fn = os.path.basename(fn)
        m.timestamp = m.config_fn.split('.')[1].replace('_', ' ')
        m.time_fn = m.config_fn.replace('.config', '.time')
        m.run_fn = m.config_fn.replace('.config', '')
        parse_config(m, fn)
        parse_time(m, fn.replace('.config', '.time'))
        fields = parse_run_log(m, fn.replace('.config', '.run'))
        assert len(fields)== len(fields0), "Different # of fields %r" % (set(fields) - set(fields0))


def parse_time(m, fn):
    '''
    This parses the output of "/usr/bin/time --verbose"
    Parsing these fields:  exit_status, user_time_sec, elapsed_time_sec, cpu_percent
    '''
    with open (fn, 'r') as f:
        blob = f.read()
    val = blob.split('Exit status: ')[1].split('\n')[0].strip()
    if val == '0':
        m.success = True
    else:
        m.success = False
    m.exit_status = val
    val = blob.split('System time (seconds): ')[1].split('\n')[0].strip()
    m.meas_type = 'system_time_sec'
    m.meas_value = val
    print(m.row())
    val = blob.split('User time (seconds): ')[1].split('\n')[0].strip()
    m.meas_type = 'user_time_sec'
    m.meas_value = val
    print(m.row())
    val = blob.split('Elapsed (wall clock) time (h:mm:ss or m:ss): ')[1].split('\n')[0].strip()
    if len(val.split(':'))==2:   # m:ss
        val = str(int(val.split(':')[0])*60 + float(val.split(':')[1].strip()))
    elif len(val.split(':'))==3:   # h:m:ss
        val = str(int(val.split(':')[0])*3600 + int(val.split(':')[1])*60 + float(val.split(':')[2].strip()))
    m.meas_type = 'elapsed_time_sec'
    m.meas_value = val
    print(m.row())
    val = blob.split('Percent of CPU this job got: ')[1].split('\n')[0].strip('%')
    m.meas_type = 'cpu_percent'
    m.meas_value = val
    print(m.row())
    return m

def parse_config(m, fn):
    '''
    Generally, this should parse any comma separated config file
    if you set the fields below correctly
    '''
    global cfg_fields
    with open (fn, 'r') as f:
        blob = f.read()
    for field in cfg_fields:
        if field in blob:
            val = blob.split(field + ',')[1].split(',')[0].strip()
            setattr(m, field, val)
    return m

def parse_run_log(m, fn):
    '''
    Custom parser for fvt_ark_perf_tool program
    '''
    with open (fn, 'r') as f:
        blob = f.read()
    #m.meas_type = 'kv_ops_per_sec'
    #m.meas_value = blob.split('op/s:')[1].split(' ')[0].strip()
    m.meas_type='example'
    m.meas_value=0
    print(m.row())
    return m.fields()

if __name__ == '__main__':
    main(sys.argv[1:])
