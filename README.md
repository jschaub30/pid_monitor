# pid_monitor
Linux tools for monitoring processes written in bash, python and javascript

 - /rundir/[WORKLOAD-NAME]/[DATETIME]/data/raw   # All config and raw data files end up here
 - /rundir/[WORKLOAD-NAME]/[DATETIME]/data/final # Parsed CSV data
 - /rundir/[WORKLOAD-NAME]/[DATETIME]/script     # Measurement and analysis scripts
 - /rundir/[WORKLOAD-NAME]/[DATETIME]/img        # Any image files from analyzing data
 - /rundir/[WORKLOAD-NAME]/[DATETIME]/html       # For interactive charts

Example program around "sleep" command

./run_sleep.sh   # runs "sleep 2" and creates run directory in ../rundir/SLEEP/[TIMESTAMP]/latest
./tidy_all_sleep.sh  # Calls ./tidy_sleep.py against all runs to parse raw data into ../rundir/SLEEP/[TIMESTAMP]/latest/data/final/summary.csv

A summary CSV file of all the runs will be located at ../rundir/SLEEP/all.csv

The output is stored with "tidy data" principles in mind.
