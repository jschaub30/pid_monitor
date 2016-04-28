#!/usr/bin/Rscript

args = commandArgs(trailingOnly=TRUE)
pre_csv_fn <- args[1]
post_csv_fn <- args[2]
out_csv_fn <- args[3]

d1 <- read.csv(pre_csv_fn, stringsAsFactors=FALSE)
d2 <- read.csv(post_csv_fn, stringsAsFactors=FALSE)
d3 <- d1 # to copy names and labels
st <- 2
nd <- dim(d1)[2]-1
d3[,st:nd] <- d2[,st:nd] - d1[,st:nd]

write.csv(d3, file=out_csv_fn,row.names = FALSE, quote=FALSE)
