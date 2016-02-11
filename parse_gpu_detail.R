#!/usr/bin/Rscript

library(reshape2)
args = commandArgs(trailingOnly=TRUE)
input_fn <- args[1]
d <- read.csv(input_fn, stringsAsFactors=FALSE)

t <- as.POSIXct(d$timestamp)
d1 <- data.frame(time.sec=floor(as.numeric(t-t[1])), index=d$index)
d1$GPU <- as.numeric(sub("%","",d$utilization.gpu....))
d1$MEMORY <- as.numeric(sub("%","",d$utilization.memory....))
d2 <- dcast(d1, time.sec ~ index, value.var="GPU")
write.csv(d2, file=paste(input_fn, 'gpu.csv', sep="."), row.names = FALSE, quote=FALSE)

d2 <- dcast(d1, time.sec ~ index, value.var="MEMORY")
write.csv(d2, file=paste(input_fn, 'mem.csv', sep="."), row.names = FALSE, quote=FALSE)
