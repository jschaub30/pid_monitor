#!/usr/bin/Rscript
# Input:  CSV file with headers
#   x,y,z
#   1,2,3
#   4,5,6
# Output: CSV file
# Usage:   
#  ./split-columns.R [IN_CSV] [COLUMN NAMES]
# Example: ./split-columns.R in.csv x z

args <- commandArgs(TRUE)

input_csv <- args[1]       # Input filename
scale     <- as.numeric(args[2])
colnames  <- args[3:length(args)]

write(sprintf("Reading input file=%s", input_csv), stderr())
write(sprintf("Splitting on column name=%s", colnames), stderr())

d <- read.csv(input_csv, header=TRUE)
d1 <- round(d[colnames]*scale, 1)
try(t0 <- strptime(d$time[1], "%m-%d %H:%M:%OS"), silent = TRUE)
try(d1$elapsed_time_sec <- as.numeric(strptime(d$time, "%m-%d %H:%M:%OS")-t0), silent = TRUE)

write.csv(d1,row.names=FALSE)

