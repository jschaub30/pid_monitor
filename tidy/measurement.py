#!/usr/bin/python

'''
Generic measurement class
All common operations are defined here
Jeremy Schaub
'''

import sys


class Measurement(object):

    '''
    Abstract data type
    Concrete types should implement:
        __init__    to define fields
        parse       to parse input file
    '''

    def __init__(self):
        self._expected_length = 0

    # Concrete types need to implement 'parse'
    def parse(self): pass

    def fields(self):
        '''
        Returns a list of all possible measured fields
        '''
        fields = [i for i in self.__dict__.keys() if i[:1] != '_']
        return fields

    def headercsv(self):
        '''
        Returns a csv string with all header fields
        '''
        return ','.join(self.fields())

    def headerhtml(self, fields=None):
        '''
        Returns an HTML string all header fields
        '''
        if not fields:
            fields = self.fields()
        row = '<tr>\n<th>%s</th>\n</tr>\n' % ('</th>\n<th>'.join(fields))

        return row

    def addfield(self, name=None, value=None):
        if name not in self.fields():
            self._expected_length += 1
        setattr(self, name, value)

    def htmlclass(self):
        return ""

    def rowhtml(self, fields=None, rowclass=None):
        ''' Returns an html formatted string with all td cells in row '''
        if not fields:
            fields = self.fields()
        if not rowclass:
            rowclass = self.htmlclass()

        try:
            values = [str(getattr(self, field)) for field in fields]
        except AttributeError as err:
            sys.stderr.write('\nProblem creating html\n%s\n' % str(err))
            sys.stderr.write(
                'Available attributes are %s\n\n' % (self.fields()))
            assert False

        html_row = '<tr class="%s">\n<td>' % (rowclass)
        html_row += '</td>\n<td>'.join(values)
        html_row += '</td>\n</tr>\n'
        return html_row

    def rowcsv(self, fields=None):
        ''' Returns an CSV formatted string with all td cells in row '''
        if not fields:
            fields = self.fields()
        values = [str(getattr(self, field)) for field in fields]
        return ','.join(values) + '\n'

    def is_valid(self):
        return len(self.fields()) == self._expected_length
