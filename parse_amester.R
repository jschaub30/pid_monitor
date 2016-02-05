#!/usr/bin/Rscript

args = commandArgs(trailingOnly=TRUE)
input_fn <- args[1]
d <- read.csv(input_fn, stringsAsFactors=FALSE)

t <- strptime(paste(d$AMESTER.Date, d$AMESTER.Time), format="%m/%d/%Y %H:%M:%S")
d1 <- data.frame(time.sec=floor(as.numeric(t-t[1])))

prefix <- function(x){
    paste('mysys_node0', c('ame0', 'ame1'), x, sep='_')
}

sensors <- c('MRD2MSP0M0', 'MRD2MSP0M1', 'MRD2MSP0M4', 'MRD2MSP0M5')
all_sensors <- unlist(lapply(sensors, prefix))
d1$READ <- rowSums(d[all_sensors])
sensors <- c('MWR2MSP0M0', 'MWR2MSP0M1', 'MWR2MSP0M4', 'MWR2MSP0M5')
all_sensors <- unlist(lapply(sensors, prefix))
d1$WRITE <- rowSums(d[all_sensors])
write.csv(d1, file=paste(input_fn, 'csv', sep="."), row.names = FALSE, quote=FALSE)

