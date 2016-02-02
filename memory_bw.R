#!/usr/bin/Rscript

args = commandArgs(trailingOnly=TRUE)
input_fn <- args[1]
d <- read.csv(input_fn)
d1 <- data.frame('time_sec'=d$TIME_SEC)

if("PM_DATA_FROM_L2" %in% names(d)){
    # Power8
    # http://www-01.ibm.com/support/knowledgecenter/SSFK5S_2.1.0/com.ibm.cluster.pedev.v2r1.pedev100.doc/bl7ug_derivedmetricspower8.htm
    cache_line_size <- 128

    tot_ld_l_L1 <- (d$PM_LD_REF_L1 - d$PM_LD_MISS_L1)/ (1024*1024*1024) #Total Loads from L1
    #d1$L1 <- cache_line_size * tot_ld_l_L1
    tot_ld_l_L2 <- d$PM_DATA_FROM_L2 / (1024*1024*1024) #Total Loads from local L2
    d1$L2 <- round(cache_line_size * tot_ld_l_L2, 2)
    tot_ld_l_L3 <- d$PM_DATA_FROM_L3 / (1024*1024*1024) #Total Loads from local L3
    #tot_ld_l_L3 <- d$PM_L3_PREF_ALL / (1024*1024*1024) #Total Loads from local L3
    d1$L3 <- round(cache_line_size * tot_ld_l_L3, 2)
    tot_ld_mem = (d$PM_DATA_FROM_RMEM + d$PM_DATA_FROM_LMEM) / (1024*1024*1024)
    #tot_ld_mem = d$PM_DATA_ALL_FROM_MEMORY / (1024*1024*1024)
    #tot_ld_mem = (d$PM_L3_PREF_ALL + d$PM_DATA_ALL_FROM_LMEM + d$PM_DATA_ALL_FROM_RMEM + d$PM_DATA_ALL_FROM_DMEM + d$PM_DATA_ALL_FROM_LL4) / (1024*1024*1024)
    #tot_ld_mem = d$PM_L3_PF_MISS_L3 / (1024*1024*1024)
    tot_ld_mem = d$PM_MEM_PREF / (1024*1024*1024)
    d1$MEM <- round(cache_line_size * tot_ld_mem, 2)
} else {
    # x86 Haswell
    cache_line_size <- 64
    #d1$L1 <- d$mem_load_uops_retired.l1_hit * cache_line_size / (1024*1024*1024)
    d1$L2 <- d$mem_load_uops_retired.l2_hit * cache_line_size / (1024*1024*1024)
    d1$L3 <- d$mem_load_uops_retired.l3_hit * cache_line_size / (1024*1024*1024)
    d1$MEM <- d$LLC_MISSES * cache_line_size / (1024*1024*1024)
}

#d1$SUM <- d1$L2 + d1$L3 + d1$MEM
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
