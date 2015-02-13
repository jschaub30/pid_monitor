#!/usr/bin/Rscript

#require(plyr)
#require(ggplot2)

dir.create('../img', showWarnings = FALSE)

d <- read.csv('../data/final/summary.csv', header=TRUE)
d1 <- d[c("timestamp", "meas_type", "meas_value")]
idx <- which(d1$meas_type=='elapsed_time_sec')
d2 <- d1[idx,]
write.csv(d2, '../data/final/chartdata.csv')

