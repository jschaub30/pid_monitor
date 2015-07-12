#!/usr/bin/python

'''
Input:  file
Output: stdout
Tidy output of /usr/bin/time --verbose into CSV format
Jeremy Schaub
$ ./timeread.py [time_output_file]
'''

import sys
import measurement

class TimeMeasurement(measurement.Measurement):

    '''
    Data structure for /usr/bin/time measurement
    '''

    def __init__(self):
        self.elapsed_time_sec = ''
        self.user_time_sec = ''
        self.system_time_sec = ''
        self.exit_status = '-1'
        self.cpu_pct = ''
        self._expected_length = 5  # Change this when adding new fields

    def parse(self, time_fn):
        '''
        This parses the output of "/usr/bin/time --verbose"
        Parsing these fields:  exit_status, user_time_sec, elapsed_time_sec,
                               system_time_sec, cpu_percent
        '''
        try:
            with open(time_fn, 'r') as fid:
                blob = fid.read()
            self.exit_status = blob.split('Exit status: ')[1].split('\n')[0].strip()
            if self.exit_status != '0':
                sys.stderr.write(
                    "WARNING! non-zero exit status = %s in file \n\t%s\n" %
                    (self.exit_status, time_fn))
            self.user_time_sec = blob.split(
                'User time (seconds): ')[1].split('\n')[0].strip()
            self.system_time_sec = blob.split(
                'System time (seconds): ')[1].split('\n')[0].strip()
            val = blob.split('Elapsed (wall clock) time (h:mm:ss or m:ss): ')[
                1].split('\n')[0].strip()
            if len(val.split(':')) == 2:   # m:ss
                val = str(
                    int(val.split(':')[0]) * 60 + float(val.split(':')[1].strip()))
            elif len(val.split(':')) == 3:   # h:m:ss
                val = str(int(val.split(':')[
                          0]) * 3600 + int(val.split(':')[1]) * 60 +
                          float(val.split(':')[2].strip()))
            self.elapsed_time_sec = val
            self.cpu_pct = blob.split('Percent of CPU this job got: ')[
                1].split('\n')[0].strip('%')
        except Exception as err:
            sys.stderr.write('Problem parsing time file %s\n%s\n' %
                             (time_fn, str(err)))
    def htmlclass(self):
        return "warning" if int(self.exit_status) != 0 else ""


def main(time_fn):
    # Wrapper to write csv to stdout
    m = TimeMeasurement()
    m.parse(time_fn)
    sys.stdout.write('%s\n%s\n' % (m.headercsv(), m.rowcsv()))


if __name__ == '__main__':
    main(sys.argv[1])
