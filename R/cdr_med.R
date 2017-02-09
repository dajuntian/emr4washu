#' This function fetches labs based on visit_no
#' @param conn the connection returned from connect_db
#' @param inData the table name of the input containing visit_no
#' @param outData the table name for the output
#' @importFrom utils setTxtProgressBar txtProgressBar
#' @export
#' @examples
#' \dontrun{
#' cdr_med(conn, "user.cohort", "user.output")
#' }
cdr_med <- function(conn, inData, outData) {

    #create temporary list and out table
    cdr_med_sql_c_template <- "declare global temporary table session.temp_reg_list as
        (select reg_no, facility_concept_id from cds.cds_visit)
    definition only with replace on commit preserve rows not logged;
    
    insert into session.temp_reg_list
    select distinct cv.reg_no, cv.facility_concept_id
    from cds.cds_visit cv
    join input.input c
    on cv.visit_no = c.visit_no;
    
    create table output.output as
    (select
    PATIENT_ACCOUNT_NUMBER as REG_NO, 
    PATIENT_FACILITY_CODE as FACILITY_CONCEPT_ID, 
    FORM_SOURCE_CODE, ROUTE_TYPE_SOURCE_CODE,
    ADMIN_START_TMSTP, ADMIN_END_TMSTP, 
    MEDICATION_SOURCE_CODE_DESC,
    TOTAL_DOSE_GIVEN_VALUE, 
    TOTAL_DOSE_GIVEN_AMT,       
    TOTAL_DOSE_GIVEN_UNITS_SOURCE_CODESET_NAME,
    GIVE_SEQUENCE_NUMBER,   NOT_GIVEN_REASON_TEXT,  PHARMACY_INSTRUCTION_TEXT,
    ADMIN_PROVIDER_LASTNAME,    ADMIN_PROVIDER_FIRSTNAME,
    COMMENT_TEXT, COMPONENT_DESC,
    COMPONENT_DOSAGE_VALUE, 
    COMPONENT_DOSAGE_AMT,
    COMPONENT_DOSAGE_UNITS_SOURCE_CODE
    from cdr.medication_administration ma
    )
    definition only;"
    declare_template <- sub("input.input", inData, cdr_med_sql_c_template)
    declare_template <- sub("output.output", outData, declare_template)
   
    commit_sql(conn, declare_template, file_flag = F)

    #progress bar
    total_visit <-
        RJDBC::dbGetQuery(conn, "select count(*) from session.temp_reg_list")[1, 1]
    pb = txtProgressBar(min = 0,
                        max = total_visit,
                        initial = 0)
    
    sql_get_reg_no <- 
        "select reg_no, facility_concept_id from session.temp_reg_list"

    cdr_med_insert_outdata <- "insert into output.output
    select
    PATIENT_ACCOUNT_NUMBER as REG_NO, 
    PATIENT_FACILITY_CODE as FACILITY_CONCEPT_ID, 
    FORM_SOURCE_CODE, ROUTE_TYPE_SOURCE_CODE,
    ADMIN_START_TMSTP, ADMIN_END_TMSTP, 
    MEDICATION_SOURCE_CODE_DESC,
    TOTAL_DOSE_GIVEN_VALUE, 
    TOTAL_DOSE_GIVEN_AMT,       
    TOTAL_DOSE_GIVEN_UNITS_SOURCE_CODESET_NAME,
    GIVE_SEQUENCE_NUMBER,   NOT_GIVEN_REASON_TEXT,  PHARMACY_INSTRUCTION_TEXT,
    ADMIN_PROVIDER_LASTNAME,    ADMIN_PROVIDER_FIRSTNAME,
    COMMENT_TEXT, COMPONENT_DESC,
    COMPONENT_DOSAGE_VALUE, 
    COMPONENT_DOSAGE_AMT,
    COMPONENT_DOSAGE_UNITS_SOURCE_CODE
    from cdr.medication_administration ma
    where PATIENT_ACCOUNT_NUMBER = ?PAN
    and PATIENT_FACILITY_CODE = ?FAC"
    
    get_reg <- RJDBC::dbSendQuery(conn, sql_get_reg_no)
    completed_visit <- 0
    repeat {
        single_pt <- DBI::dbFetch(get_reg, n = 1)
        if (nrow(single_pt) <= 0) {
            cat(': Done')
            break
        }
        RJDBC::dbSendUpdate(
            conn,
            DBI::sqlInterpolate(
                conn,
                sub("output.output", outData, cdr_med_insert_outdata),
                PAN = trimws(single_pt$REG_NO),
                FAC = single_pt$FACILITY_CONCEPT_ID
            )
            
            )
        completed_visit <- completed_visit + 1
        setTxtProgressBar(pb, completed_visit)
    }
    RJDBC::dbClearResult(get_reg)

    #output info
    cat(paste0("\ncdr med results output to: ", outData, "\n"))
}
