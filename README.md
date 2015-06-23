# pid_monitor
Linux tool that launches a workload, records process and system data using dstat, and automatically generates an html page with interactive javascript charts.

#Requires
- [dstat](http://dag.wiee.rs/home-made/dstat/)
- [python](https://www.python.org/)

Written in bash, python, html and javascript.  

Also uses:
- [Dygraphs](http://dygraphs.com/) for javascript charts (included).
- [jquery-csv](https://code.google.com/p/jquery-csv/) for csv parsing

Start by viewing:
- [example.sh](https://github.com/jschaub30/pid_monitor/blob/master/example.sh) 
- [example-sweep.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-sweep.sh)

This will create the follwing directories:
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/data/raw   # All config and raw data files end up here
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/data/final # Parsed CSV data in "tidy" data format
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/script     # Measurement and analysis scripts
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/img        # Any image files from analyzing data
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/html       # For interactive charts
