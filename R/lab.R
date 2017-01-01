#' This function fetches labs based on visit_no
#' @param conn the connection returned from connect_db
#' @param inData the table name of the input containing visit_no
#' @param outData the table name for the output
#' @export
#' @examples
#' \dontrun{
#' lab(conn, "user.cohort", "user.output")
#' }
lab <- function(conn, inData, outData) {

    library(RJDBC)

    dbSendUpdate(
        conn,
        "declare global temporary table session.temp_reg_list as
        (select reg_no, facility_concept_id from cds.cds_visit)
        definition only with replace on commit preserve rows not logged
        "
    )
    dbSendUpdate(
        conn,
        paste0(
            "insert into session.temp_reg_list
            select distinct reg_no, facility_concept_id
            from cds.cds_visit cv
            join ",
            inData,
            " c
            on cv.visit_no = c.visit_no"
        )
    )
    
    
    dbSendUpdate(
        conn,
        paste0(
            "create table ",
            outData,
            " as
            (select * from cdr.lab_test_results)
            definition only"
        )
        )
    
    #progress bar
    total_visit <-
        dbGetQuery(conn, "select count(*) from session.temp_reg_list")[1, 1]
    pb = txtProgressBar(min = 0,
                        max = total_visit,
                        initial = 0)
    sql_get_reg_no <- "select reg_no, facility_concept_id
    from session.temp_reg_list"
    
    get_reg <- dbSendQuery(conn, sql_get_reg_no)
    completed_visit <- 0
    repeat {
        single_pt <- dbFetch(get_reg, n = 1)
        if (nrow(single_pt) <= 0) {
            cat(': Done')
            break
        }
        dbSendUpdate(
            conn,
            sqlInterpolate(
                conn,
                paste0(
                    "insert into ",
                    outData,
                    "
                    select *
                    from cdr.lab_test_results
                    where PATIENT_ACCOUNT_NUMBER = ?PAN
                    and PATIENT_ACCOUNT_NUMBER_FACILITY_ID = ?FAC"
                ),
                PAN = trimws(single_pt$REG_NO),
                FAC = single_pt$FACILITY_CONCEPT_ID
                )
            )
        completed_visit <- completed_visit + 1
        setTxtProgressBar(pb, completed_visit)
    }
    dbClearResult(get_reg)
    
    #output info
    cat(paste0("\nlab results output to: ", outData, "\n"))
}
