# convert sql text files into a list of sql statements

#' commit .sql file to database
#' @param conn the connection from connect_db
#' @param sql_file the sql file without any comments
#' @param file_flag default TRUE, if FALSE, the sql file itself is treated as a string
#' @export 
#' @examples
#' \dontrun{
#' commit_sql(conn, "Z:/EMR/bearhunt.sql")
#' commit_sql(conn, "select * from session.ca", file_flag = F)
#' }
#' 
commit_sql <- function(conn, sql_file, file_flag = T) {
    
    #read the sql file into separate sql statements into sql_seq
    sql_seq <- ""
    if (file_flag == T) {sql_seq <- .file_to_sql_vector(sql_file)}
    else {sql_seq <- .string_to_sql_vector(sql_file)}
    result_set_id <- 1
    
    for (sql_statement in sql_seq) {
        sql_statement <- trimws(gsub("\\s+", " ", sql_statement, perl = T))
        
        if (sql_statement == "" | is.na(sql_statement)) {break}

        if (grepl("^select", sql_statement, ignore.case = T, perl = T)) {
            result <- DBI::dbGetQuery(conn, sql_statement)
            assign(paste0('resultset_', result_set_id), result, envir = .GlobalEnv)
            result_set_id <- result_set_id + 1
        } else {
            RJDBC::dbSendUpdate(conn, sql_statement)
        }
    }
}


.file_to_sql_vector <- function(sql_file) {
  # import sql text files into vector of string
  sql_raw <- readChar(sql_file, file.info(sql_file)$size)
  pattern <- "((?:[^;\"']|\"[^\"]*\"|'[^']*')+)"
  m <- gregexpr(pattern, sql_raw)
  unlist(regmatches(sql_raw, m))
}

.string_to_sql_vector <- function(input_text) {
    sql_raw <- input_text
    pattern <- "((?:[^;\"']|\"[^\"]*\"|'[^']*')+)"
    m <- gregexpr(pattern, sql_raw)
    unlist(regmatches(sql_raw, m))
}




