#' This function fetches labs based on visit_no from cds.labs
#' @param conn the connection returned from connect_db
#' @param inData the table name of the input containing visit_no
#' @param outData the table name for the output
#' @importFrom utils setTxtProgressBar txtProgressBar
#' @export
#' @examples
#' \dontrun{
#' lab(conn, "user.cohort", "user.output")
#' }
lab_cds <- function(conn, inData, outData) {

    #create temporary list and out table
    declare_template <- sub("input.input", inData, lab_sql_c_template_cds)
    declare_template <- sub("output.output", outData, declare_template)

    commit_sql(conn, declare_template, file_flag = F)

    #progress bar
    total_visit <-
        RJDBC::dbGetQuery(conn, "select count(*) from session.temp_reg_list")[1, 1]
    pb = txtProgressBar(min = 0,
                        max = total_visit,
                        initial = 0)

    sql_get_reg_no <- lab_sql_get_reg_no_cds

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
                sub("output.output", outData, lab_insert_outdata_cds),
                PAN = trimws(single_pt$REG_NO),
                FAC = single_pt$FACILITY_CONCEPT_ID
            )

            )
        completed_visit <- completed_visit + 1
        setTxtProgressBar(pb, completed_visit)
    }
    RJDBC::dbClearResult(get_reg)

    #output info
    cat(paste0("\nlab results output to: ", outData, "\n"))
}
