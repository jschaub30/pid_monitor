#!/usr/bin/python

'''
Input:  file
Output: stdout

Remove trailing comma at the end of a list from json file
Jeremy Schaub
$ ./tidy-json.py (json file with a ,\n] )
'''

import sys

def main(args):
    fn = args[0]
    '''
    '''
    with open (fn, 'r') as f:
        blob = f.read()
    sys.stdout.write(blob.replace(',\n]', '\n]'))

if __name__ == '__main__':
    main(sys.argv[1:])
