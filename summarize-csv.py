#!/usr/bin/python

'''
Input:  directory and filename suffix
Output: stdout for sucessful runs where exit_status=0
        stderr for runs where exit_status!=0

Combine many csv files into one summarized output
Jeremy Schaub
$ ./summarize-csv.py [directory] [suffix]
'''

import sys, os, glob
from datetime import datetime

def main(argList):
    csv_directory = argList[0].strip()
    fn_suffix = argList[1].strip().strip('*')

    # Get list of files and sort by creation date
    files = filter(os.path.isfile, glob.glob(os.path.join(csv_directory, '*'+fn_suffix)))
    files.sort(key=lambda x: os.path.getmtime(x))
    write_header = True
    for fn in files:
        run_id = os.path.basename(fn.strip(fn_suffix))
        with open (fn, 'r') as f:
            header = f.readline()
            lines = f.readlines()
        if write_header:
            first_header = header
            write_header = False  # Only write the header once
            if 'exit_status' in header:
                check_flag = True
                idx = header.strip().split(',').index('exit_status')
            else:
                check_flag = False
            sys.stdout.write('run_id,' + header)
            sys.stderr.write('run_id,' + header)
        if header != first_header:
            sys.stderr.write('#skipping file ' + fn)
            break
        for line in lines:
            if check_flag:
                # Parse line to determine if exit status is 0
                rc = line.strip().split(',')[idx]
                if int(rc) == 0:
                    sys.stdout.write(run_id + ',' + line)
                else:
                    sys.stderr.write(run_id + ',' + line)
            else:
                sys.stdout.write(run_id + ',' + line)

if __name__ == '__main__':
    main(sys.argv[1:])
