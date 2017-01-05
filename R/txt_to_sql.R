# convert sql text files into a list of sql statements

.sql_to_string_vector <- function(sql_file) {
  sql_raw <- readChar(sql_file, file.info(sql_file)$size)
  pattern <- "((?:[^;\"']|\"[^\"]*\"|'[^']*')+)"
  m <- gregexpr(pattern, sql_raw)
  unlist(regmatches(sql_raw, m))
}
