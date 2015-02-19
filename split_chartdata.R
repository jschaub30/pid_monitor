#!/usr/bin/Rscript

args <- commandArgs(TRUE)

input_csv <- args[1]       # Input filename
split_var <- args[2]       # Split on this column name
data_cols <- args[-(1:2)]  # Print these column names to output files

cat(sprintf("Reading input file=%s.\nSplitting on column name=%s\n", input_csv, split_var))
cat(sprintf("Writing these columns to output files: "))
for (i in seq_along(data_cols)){
  cat(data_cols[i],' ')
}
cat('\n')

d <- read.csv(input_csv, header=TRUE)

pieces <- split(d, d[split_var])

fn <- c()
for (i in seq_along(pieces)){
  id <- names(pieces)[i]
  d1 <- pieces[[i]]
  d2 <- d1[ , data_cols]
  fn[i] <- paste("chartdata", id, "csv", sep=".")
  write.csv(d2, fn[i], row.names=FALSE)

}

library(jsonlite, warn.conflicts=FALSE)
# Write json object to a summary file
json <- toJSON(data.frame('id'=names(pieces), 'filename'=fn))
fn_str <- paste('var chartdata = ', json, ';', sep='')
fileConn <- file("chart_summary.js")
writeLines(fn_str, fileConn)
close(fileConn)

