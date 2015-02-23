# pid_monitor
Linux tool that launched a workload, records process and system data (like CPU and Memory usage), and automatically generates an html page with interactive javascript charts.

Written in bash, python, R and javascript.  Uses the D3js and C3js javascript libraries.

Start by editing the "run-workload.sh" script
$ ./run-workload.sh   # calls the "watch-process.py script

This will create the follwing directories:
 - ../rundir/[WORKLOAD-NAME]/[DATETIME]/data/raw   # All config and raw data files end up here
 - ../rundir/[WORKLOAD-NAME]/[DATETIME]/data/final # Parsed CSV data in "tidy" data format
 - ../rundir/[WORKLOAD-NAME]/[DATETIME]/script     # Measurement and analysis scripts
 - ../rundir/[WORKLOAD-NAME]/[DATETIME]/img        # Any image files from analyzing data
 - ../rundir/[WORKLOAD-NAME]/[DATETIME]/html       # For interactive charts

