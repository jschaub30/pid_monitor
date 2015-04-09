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
colnames  <- args[2:length(args)]
 
write(sprintf("Reading input file=%s", input_csv), stderr())
write(sprintf("Splitting on column name=%s", colnames), stderr())
 
d <- read.csv(input_csv, header=TRUE)
write.csv(d[colnames],row.names=FALSE)

