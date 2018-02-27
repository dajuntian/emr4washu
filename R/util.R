
library(tmpm)

#get the column names of the csv file
input_dx <- read.csv("", colClasses = 'character',
                     nrows = 1000)

colnames <- names(input_dx)

index <- 0
chunkSize <- 1000000
con <- file("", open = "r")
dataChunk <- read.table(con, nrows=chunkSize, 
                        header=T, fill=TRUE, sep=",", col.names=colnames,
                        colClasses = "character")
counter <- 0
total <- 0
pt_id <- character(0)
p_death <- numeric(0)

repeat {
  index <- index + 1
  print(paste('Processing rows:', index * chunkSize))
  
  #add dot after first three characters
  dataChunk[-1] <- 
    sapply(dataChunk[-1], function (x) sub("^(...)(.*)$", "\\1\\.\\2", x, perl = TRUE))
  #r <- unlist(lapply(x, function(y) paste0(substr(y, 1, 3), ifelse(nchar(y) > 3, paste0('.', substr(y, 4, nchar(y))),''))))
  #remove dot if dot is the last characte
  dataChunk[-1] <- 
    sapply(dataChunk[-1], function (x) sub("^(...)(\\.)$", "\\1", x, perl = TRUE))
  
  icd9_pdeath <- tmpm(dataChunk, ILex = 9)
  
  pt_id <- c(pt_id, icd9_pdeath$KEY_OR_KEY_NIS)
  p_death <- c(p_death, icd9_pdeath$pDeath)
  
  if (nrow(dataChunk) != chunkSize){
    print('Processed all files!')
    break}
  
  dataChunk <- read.table(con, nrows=chunkSize, skip=0, header=FALSE, fill = TRUE, sep=",", 
                          col.names=colnames,
                          colClasses = "character")
  
}
close(con)

write.csv(data.frame(pt_id, p_death), file = "", 
          row.names = F, na = "")





