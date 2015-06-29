#!/usr/bin/python

'''
Input:  file
Output: stdout

Tidy output of /usr/bin/time --verbose into CSV file
Jeremy Schaub
$ ./tidy-time.py [time_output_file]
'''

import sys


class Measurement:

    '''
    Data structure for pwatch measurement
    '''

    def __init__(self):
        self.elapsed_time_sec = ''
        self.user_time_sec = ''
        self.system_time_sec = ''
        self.exit_status = ''
        self.cpu_pct = ''

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
    m = Measurement()
    header = m.header()
    expected_length = len(header.split(','))
    print(header)
    m = parse_time(m, run_fn)
    # CSV output will be incorrect if you add another field without
    # initializing
    assert len(m.fields()) == expected_length


def parse_time(m, fn):
    '''
    This parses the output of "/usr/bin/time --verbose"
    Parsing these fields:  exit_status, user_time_sec, elapsed_time_sec, cpu_percent
    '''
    with open(fn, 'r') as f:
        blob = f.read()
    m.exit_status = blob.split('Exit status: ')[1].split('\n')[0].strip()
    if m.exit_status != '0':
        sys.stderr.write("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
        sys.stderr.write(
            "WARNING! non-zero exit status = " + m.exit_status + "\n")
        sys.stderr.write("See file " + fn + "\n")
        sys.stderr.write("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n")
    m.user_time_sec = blob.split(
        'User time (seconds): ')[1].split('\n')[0].strip()
    m.system_time_sec = blob.split(
        'System time (seconds): ')[1].split('\n')[0].strip()
    val = blob.split('Elapsed (wall clock) time (h:mm:ss or m:ss): ')[
        1].split('\n')[0].strip()
    if len(val.split(':')) == 2:   # m:ss
        val = str(
            int(val.split(':')[0]) * 60 + float(val.split(':')[1].strip()))
    elif len(val.split(':')) == 3:   # h:m:ss
        val = str(int(val.split(':')[
                  0]) * 3600 + int(val.split(':')[1]) * 60 + float(val.split(':')[2].strip()))
    m.elapsed_time_sec = val
    m.cpu_pct = blob.split('Percent of CPU this job got: ')[
        1].split('\n')[0].strip('%')
    print m.row()

    return m

if __name__ == '__main__':
    main(sys.argv[1:])
