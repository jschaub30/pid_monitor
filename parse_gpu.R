#!/usr/bin/Rscript

#library(reshape2)
args = commandArgs(trailingOnly=TRUE)
input_fn <- args[1]
d <- read.csv(input_fn, stringsAsFactors=FALSE)

t <- as.POSIXct(d$timestamp)
d1 <- data.frame(time.sec=floor(as.numeric(t-t[1])), index=d$index)
d1$gpu_pct <- as.numeric(sub("%","",d$utilization.gpu....))
d1$mem_pct <- as.numeric(sub("%","",d$utilization.memory....))
#d2 <- dcast(d1, time.sec ~ index, value.var="gpu")
d2 <- aggregate(d1,by=list(d1$time.sec), FUN=mean, na.rm=TRUE)
d2 <- subset(d2, select = -c(index,Group.1))
write.csv(d2, file=paste(input_fn, 'csv', sep="."), row.names = FALSE, quote=FALSE)

#d2 <- dcast(d1, time.sec ~ index, value.var="mem")
#d2 <- aggregate(d1,by=list(d1$time.sec), FUN=mean, na.rm=TRUE)
#write.csv(d2, file=paste(input_fn, 'mem.csv', sep="."), row.names = FALSE, quote=FALSE)
