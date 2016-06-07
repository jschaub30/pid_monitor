# pid_monitor
Profile your workload and share the results in data-rich, interactive charts

Version 1.01

#Requires
- Linux
- [dstat](http://dag.wiee.rs/home-made/dstat/)
- [python](https://www.python.org/)
- (Optional) Some of the advanced monitors (like GPU) use [R scripts](https://www.r-project.org/) to parse output data

Start here:
- [example.sh](https://github.com/jschaub30/pid_monitor/blob/master/example.sh) Simple write to disk example
- [example-sweep.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-sweep.sh) Sweeping block size while writing to disk
- [example-cluster.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-sweep.sh) Run workload on 2 machines at once
- [example-spark.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-spark.sh) Run the SparkPi example on your spark cluster
- [example-amester.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-amester.sh) Collect measurements on Power8 systems using the AMESTER tool
- TODO [example-gpu.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-gpu.sh) Record GPU profiles on systems with nvidia GPUs
- TODO [example-perf.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-oprofile.sh) Record perf data
- TODO [example-oprofile.sh](https://github.com/jschaub30/pid_monitor/blob/master/example-oprofile.sh) Record oprofile data

This repository also makes use of:
- [Dygraphs](http://dygraphs.com/) for javascript charts (included).
- [c3.js](http://c3js.org/) for javascript charts (included).
- [jquery-csv](https://code.google.com/p/jquery-csv/) for csv parsing (included).
- GNU-time /usr/bin/time

Try it out:
```
sudo apt-get install -y dstat time
git clone https://github.com/jschaub30/pid_monitor
cd pid_monitor/
cp example.sh your_workload.sh
[ Edit your_workload.sh ]
./your_workload.sh
./pid_webserver.sh
[ (Optional) copy the run directory to your web server ]
```
When run, these examples will create the following directories:
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/data/raw   # All config and raw data files end up here
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/scripts    # Measurement and analysis scripts
 - ./rundir/[WORKLOAD-NAME]/[DATETIME]/html       # For interactive charts

To permanently share all the measurements on your server, you need to enable a web server.
On Ubuntu, this is as simple as
```
sudo apt-get install apache2
cd /var/www/html
sudo ln -sf [location of rundir in pid_monitor directory]
```
