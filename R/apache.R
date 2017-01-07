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
    generate_candiates <- paste0("
DECLARE GLOBAL TEMPORARY TABLE session.candidates as (
                                 select r.facility_concept_id, r.reference_no, r.reg_no, p.pat_name, 
                                 r.admit_date, r.discharge_date, p.dob, 
                                 floor( (days(r.admit_date)-days(p.dob))/365.25) as age,
                                 ca.index_date
                                 from cds.registration r
                                 join cds.patient p 
                                 on r.reference_no = p.reference_no
                                 join ", inData, " ca
                                 on r.reg_no = ca.reg_no and r.facility_concept_id = ca.facility_concept_id
    ) definition only WITH REPLACE ON COMMIT PRESERVE ROWS NOT LOGGED;
                                 
                                 insert into  session.candidates
                                 select r.facility_concept_id, r.reference_no, r.reg_no, p.pat_name, 
                                 r.admit_date, r.discharge_date, p.dob, 
                                 floor( (days(r.admit_date)-days(p.dob))/365.25) as age,
                                 ca.index_date
                                 from cds.registration r
                                 join cds.patient p 
                                 on r.reference_no = p.reference_no
                                 join ", inData, " ca
                                 on r.reg_no = ca.reg_no and r.facility_concept_id = ca.facility_concept_id;")

    
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


   