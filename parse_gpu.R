#!/usr/bin/Rscript

#library(reshape2)
args = commandArgs(trailingOnly=TRUE)
input_fn <- args[1]
d <- read.csv(input_fn, stringsAsFactors=FALSE)
IDX <- c()
for(GPU in unique(d$index)){
  idx <- which(d$index==GPU)
  s = sum(as.numeric(sub('%','',d$utilization.gpu....[idx])))
  if(s>0){
    IDX <- c(IDX, idx)
  }
}

IDX <- sort(IDX)
d <- d[IDX,]
t <- as.POSIXct(d$timestamp)
t <- floor(as.numeric(t - t[1]))
# Make timestamps for all GPUs match that of GPU0
t0 = 0
for(I in seq(length(t))){
    if(d$index[I]==d$index[1]){
        t0 = t[I]
    } else {
        t[I] = t0
    }
}
d1 <- data.frame(time.sec=t, index=d$index)
d1$GPU <- as.numeric(sub("%","",d$utilization.gpu....))
d1$MEMORY <- as.numeric(sub("%","",d$utilization.memory....))
d2 <- aggregate(d1,by=list(d1$time.sec), FUN=mean, na.rm=TRUE)
d2 <- subset(d2, select = -c(index,Group.1))
write.csv(d2, file=paste(input_fn, 'csv', sep="."), row.names = FALSE, quote=FALSE)

d1 <- data.frame(time.sec=floor(as.numeric(t-t[1])), index=d$index)
d1$POWER <- as.numeric(sub("W","",d$power.draw..W.))
d2 <- aggregate(d1,by=list(d1$time.sec), FUN=mean, na.rm=TRUE)
d2 <- subset(d2, select = -c(index,Group.1))
write.csv(d2, file=paste(input_fn, 'pwr.csv', sep="."), row.names = FALSE, quote=FALSE)
