#!/usr/bin/Rscript
# Input:  CSV file in 'tidy' format
# time, pid, cpu_pct
#    0,   1,   0
#    0,   2,   2
#    1,   1,   5
#    1,   2,   4
#    2,   1,   7
#    2,   2,   3
#    3,   2,   9
# Output: CSV file with common timebase for all y variables
#   x,1,2
#   0,0,2
#   1,5,4
#   2,7,3
#   3,NA,9
# Usage:   
#  ./split_chartdata.R [TIDY_CSV] [SPLIT_VAR] [TIME_VAR] [MEAS_VAR]
# Example: ./split_chartdata.R pwatch.csv pid elapsed_time_sec, cpu_pct

args <- commandArgs(TRUE)

input_csv <- args[1]       # Input filename
split_var <- args[2]       # Split on this column name
time_var  <- args[3]       # Timebase
data_var  <- args[4]       # Print these column names to output files

write(sprintf("Reading input file=%s", input_csv), stderr())
write(sprintf("Splitting on column name=%s", split_var), stderr())
write(sprintf("x data column: %s", time_var), stderr())
write(sprintf("y data column: %s", data_var), stderr())

d <- read.csv(input_csv, header=TRUE)

pieces <- split(d, d[split_var])

x <- unique(d[, time_var])
dnew <- data.frame(x=x)

for (i in seq_along(pieces)){
  id <- names(pieces)[i]
  d1 <- pieces[[i]]
  x2 <- d1[ , time_var]
  d2 <- d1[ , data_var]
  pos <- c()
  for (j in seq_along(x2)){
    pos[j] = which(x2[j]==x)
  }
  y <- x*NaN  # Common timebase shared across all vectors
  y[pos] <- d2
  dnew <- cbind(dnew, y)
}
names(dnew) <- c('x', names(pieces))
out_fn <- paste(data_var,'csv', sep='.')
write(sprintf("Writing to: %s", out_fn), stderr())
write.csv(dnew, out_fn, row.names=FALSE)

