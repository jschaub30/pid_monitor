#!/usr/bin/Rscript

#library(reshape2)
args = commandArgs(trailingOnly=TRUE)
input_fn <- args[1]
NUM <- as.numeric(args[2])
d <- read.csv(input_fn, stringsAsFactors=FALSE)
IDX <- which(d$index<NUM)
d <- d[IDX,]
t <- as.POSIXct(d$timestamp)
d1 <- data.frame(time.sec=floor(as.numeric(t-t[1])), index=d$index)
d1$GPU <- as.numeric(sub("%","",d$utilization.gpu....))
d1$MEMORY <- as.numeric(sub("%","",d$utilization.memory....))
#d2 <- dcast(d1, time.sec ~ index, value.var="gpu")
d2 <- aggregate(d1,by=list(d1$time.sec), FUN=mean, na.rm=TRUE)
d2 <- subset(d2, select = -c(index,Group.1))
write.csv(d2, file=paste(input_fn, 'csv', sep="."), row.names = FALSE, quote=FALSE)

d1 <- data.frame(time.sec=floor(as.numeric(t-t[1])), index=d$index)
d1$POWER <- as.numeric(sub("W","",d$power.draw..W.))
d2 <- aggregate(d1,by=list(d1$time.sec), FUN=mean, na.rm=TRUE)
d2 <- subset(d2, select = -c(index,Group.1))
write.csv(d2, file=paste(input_fn, 'pwr.csv', sep="."), row.names = FALSE, quote=FALSE)
