#!/usr/bin/Rscript

args = commandArgs(trailingOnly=TRUE)
input_fn <- args[1]
all_content = readLines('/tmp/out.62821.csv')
d1 <- read.csv(textConnection(all_content[c(-1,-2,-3,-5)]), header=TRUE)
