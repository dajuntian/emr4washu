# calculate the apache II score

#' This is function calculates the apache II score
#' @param conn the connection from connect_db
#' @param inData the table name of the input containing visit_no and index_date
#' @param outData the table name for the output
#' @export
#' 
#' @examples
#' \dontrun{
#' apache(conn, "user.cohort", "user.output")
#' }


apache <- function(conn, inData, outData) {
    
    #import the inData into a global temporary session.candidates
    #it will be used in the following script
    generate_candiates <- gsub("input.input", inData, apache_declare_candidates)
    commit_sql(conn, generate_candiates, file_flag = F)
    
    #read sql file
    cat("\nsession.candidated created, beginning apache-ing\n")
    commit_sql(conn, apache_sql_text, file_flag = F)
    
    RJDBC::dbSendUpdate(
        conn,
        paste0(
            "create table ",
            outData,
            " as
            (select * from session.apache)
            definition only"
        )
    )
    
    RJDBC::dbSendUpdate(conn, 
    paste0(
        "insert into ",
        outData, " select * from session.apache"))
    
    cat(paste0("\napache results output to: ", outData, "\n"))
}


   