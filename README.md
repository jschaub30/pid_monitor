# pid_monitor
Linux tool that launches a workload, records process and system data using dstat, and automatically generates an html page with interactive javascript charts.

#Requires
- [dstat](http://dag.wiee.rs/home-made/dstat/)
- [python](https://www.python.org/)
- Some of the advanced monitors (like GPU) use [R scripts](https://www.r-project.org/) to parse output data

Written in bash, python, html and javascript.  

Also uses:
- [Dygraphs](http://dygraphs.com/) for javascript charts (included).
- [jquery-csv](https://code.google.com/p/jquery-csv/) for csv parsing (included).
- GNU-time /usr/bin/time

Start here:
- [example.sh](https://github.com/jschaub30/pid_monitor/blob/master/example.sh) Simple write to disk example
- [example-sweep.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-sweep.sh) Sweeping block size while writing to disk
- [example-cluster.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-sweep.sh) Shows how to monitor workload on 2 machines at once
- [example-spark.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-spark.sh) Run the SparkPi example on your spark cluster

This will create the following directories:
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/data/raw   # All config and raw data files end up here
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/script     # Measurement and analysis scripts
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/html       # For interactive charts

Try it out:
```
git clone https://github.com/jschaub30/pid_monitor
cd pid_monitor/
./example.sh
./pid_webserver.sh
```
