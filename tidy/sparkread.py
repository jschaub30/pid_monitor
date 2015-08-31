#!/usr/bin/python

'''
Tidy output of spark stderr file
Jeremy Schaub
Example use from command line (will output csv to stdout):
$ ./sparkread.py [spark_stderr_file]
Input:  file
Output: stdout
'''

import sys
import measurement

def calc_stage_stats(lines, stage_num):
    task_times = []
    for line in lines:
        if 'TaskSetManager: Finished task' in line and 'stage %d' % stage_num in line:
            try:
                t = line.split(') in ')[1].split(' ms on ')[0]
                task_times.append(float(t)/1000)
            except IndexError:
                sys.stderr.write("Error parsing task time in this line:\n%s\n" % line)
    if len(task_times) > 0:
        return "(%.1f/%.1f/%.1f)" % (min(task_times),
                sum(task_times)/len(task_times), max(task_times))
    else:
        sys.stderr.write("Found no tasks in stage %d\n" % stage_num)
        return ""

class SparkMeasurement(measurement.Measurement):

    '''
    Data structure for spark measurement
    '''

    def __init__(self):
        self._stage_times = ['0']
        self.total_time_sec = -1
        self.spill_count = -1
        self._expected_length = 2
        self._num_stages = 0

    def fields(self):
        '''
        Returns a list of fields in the data structure
        This overrides the default method to deal with stage times
        '''
        num_stages = self._num_stages
        stage_header = ['stage %d [sec]' % i for i in range(num_stages)]
        header_fields = [i for i in self.__dict__.keys() if i[:1] != '_']
        header_fields.extend(stage_header)
        return header_fields

    def rowcsv(self):
        '''
        Returns a csv string with all data fields
        This overrides the default method to deal with stage times
        '''
        values = [self.spill_count]
        values.extend(self._stage_times)
        return ','.join(values)

    def htmlclass(self):
        '''Overrides default class'''
        return "warning" if int(self.spill_count) != 0 else ""

    def rowhtml(self, header_fields=None, rowclass=None):
        '''
        Returns an html formatted string with all td cells in row
        This overrides the default method to deal with stage times
        '''
        stage_times = self._stage_times
        if not header_fields:
            header_fields = self.fields()
        if not rowclass:
            rowclass = self.htmlclass()
        # new_fields = header_fields
        new_fields = []
        # Strip off individual stage times
        for field in header_fields:
            if not field.startswith('stage '):
                new_fields.append(field)
        try:
            values = [str(getattr(self, field)) for field in new_fields]
            values.extend(stage_times)
        except AttributeError as err:
            sys.stderr.write('\nProblem creating html\n%s\n' % str(err))
            sys.stderr.write('Available attributes are %s\n\n' % (self.fields()))
            assert False

        html_row = '<tr class="%s">\n<td>' % (rowclass)
        html_row += '</td>\n<td>'.join(values)
        html_row += '</td>\n</tr>\n'
        return html_row

    def set_num_stages(self, num_stages):
        self._num_stages = num_stages

    def parse(self, spark_fn):
        '''
        This parses the output of the spark stderr file
        '''
        #try:
        with open(spark_fn, 'r') as f:
            blob = f.read()
        if self._num_stages == 0:
            self._num_stages = len(blob.split('finished in ')[1:])
        stage_times = ['' for i in range(self._num_stages)]
        i = 0
        total_time_sec = 0
        for a in blob.split('finished in ')[1:]:
            stage_time = round(float(a.split(' s\n')[0]), 1)
            stats = calc_stage_stats(blob.split('\n'), i)
            stage_times[i] = '%.1f %s' % (stage_time, stats)
            #total_time_sec += stage_time
            i += 1
        total_time_sec = blob.split('Job 0 finished')[1].split('took ')[1].split(' s')[0]
        self.total_time_sec = str(round(float(total_time_sec), 1))
        self._stage_times = [str(i) for i in stage_times]
        self.spill_count = str(blob.lower().count('spill'))
        #except Exception as err:
            #sys.stderr.write('Problem parsing time file %s\n' % spark_fn)
            #sys.stderr.write(str(err) + '\n')


def main(spark_fn):
    # Wrapper to print to stdout
    m = SparkMeasurement()
    m.parse(spark_fn)
    sys.stdout.write('%s\n%s\n' % (m.headercsv(), m.rowcsv()))
    # sys.stdout.write('<table>\n%s%s</table>\n' % (m.headerhtml(), m.rowhtml()))


if __name__ == '__main__':
    main(sys.argv[1])
