#!/usr/bin/Rscript

args = commandArgs(trailingOnly=TRUE)
input_fn <- args[1]
d <- read.csv(input_fn)
d1 <- data.frame('time_sec'=d$TIME_SEC)

# http://www-01.ibm.com/support/knowledgecenter/SSFK5S_2.1.0/com.ibm.cluster.pedev.v2r1.pedev100.doc/bl7ug_derivedmetricspower8.htm
L1_cache_line_size <- 128
L2_cache_line_size <- 128
L3_cache_line_size <- 128

tot_ld_l_L1 <- (d$PM_LD_REF_L1 - d$PM_LD_MISS_L1)/ (1024*1024*1024) #Total Loads from L1
#d1$L1 <- L1_cache_line_size * tot_ld_l_L1
tot_ld_l_L2 <- d$PM_DATA_FROM_L2 / (1024*1024*1024) #Total Loads from local L2
d1$L2 <- L1_cache_line_size * tot_ld_l_L2
tot_ld_l_L3 <- d$PM_DATA_FROM_L3 / (1024*1024*1024) #Total Loads from local L3
d1$L3 <- L2_cache_line_size * tot_ld_l_L3
tot_ld_mem = (d$PM_DATA_FROM_RMEM + d$PM_DATA_FROM_LMEM) / (1024*1024*1024)
d1$MEM <- L3_cache_line_size * tot_ld_mem
write.csv(d1, row.names=FALSE, quote=FALSE, stdout())

if(FALSE){
  # Use this to plot
  require('ggplot2')
  require('reshape2')
  d2 <- melt(d1, c('time_sec'), variable.name="measurement", value.name="bandwidth_GB")
  
  svg(paste(RUN_ID, '.memory_bandwidth.svg', sep=""))
  
  p <- ggplot(d2, aes(x=time_sec, y=bandwidth_GB, color=measurement)) + geom_line()
  p <- p + xlab('Time [ sec ]') + ylab('Total Bandwidth [ GB/sec ]')
  print(p)
  tmp <- dev.off()
}
