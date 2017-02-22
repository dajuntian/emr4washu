#' Charlson score from visit_no
#'
#' This function calculates the Charlson score based on visit_no
#' @param conn the connection from connect_db
#' @param inData the table name for input, must have visit_no
#' @param outData the table name for the output
#' @export
#' @examples
#' \dontrun{
#' charlson(conn, "user.incohort", "usr.out_cohort")
#' }
charlson <- function(conn, inData, outData) {
    sql_get_icd <- sub("session.candidates", inData, get_icdx_code)

    pt_w_icd <- RJDBC::dbGetQuery(conn, sql_get_icd)
    result_5 <- .help_df2score(pt_w_icd, 5)

    #get results for one year look back
    pt_w_icd[pt_w_icd$YEAR_BACK == 5, "ICDX_DIAGNOSIS_CODE"] <- NA
    result_1 <- .help_df2score(pt_w_icd, 1)

    result <- merge(result_1, result_5)
    #output data to user
    RJDBC::dbWriteTable(conn, outData, result)

    cat(paste0("\ndata output to ", outData, "\n"))
}

.help_df2score <- function(pt_w_icd, look_back) {
    pt_w_icd[, c(2)] <- sub("\\.", "", pt_w_icd[, c(2)])
    pt_w_icd[, c(2, 3)] <- sapply(pt_w_icd[, c(2, 3)], trimws)

    #get icd9 comorbidity
    pt_w_icd9 <- pt_w_icd
    if (nrow(pt_w_icd9) > 0) {
        pt_w_icd9[!is.na(pt_w_icd9$ICDX_VERSION_NO) &
                      pt_w_icd9$ICDX_VERSION_NO == "10-CM", "ICDX_DIAGNOSIS_CODE"] <-
            NA
        pt_w_icd9$ICDX_VERSION_NO <- NULL
    }

    com_pt9 <- icd::icd9_comorbid(
        pt_w_icd9,
        map = icd::icd9_map_quan_deyo,
        visit_name = "VISIT_NO",
        icd_name = "ICDX_DIAGNOSIS_CODE",
        short_code = T,
        short_map = T
    )

    #get icd10 comirbidity
    pt_w_icd10 <- pt_w_icd
    if (nrow(pt_w_icd10)) {
        pt_w_icd10[!is.na(pt_w_icd10$ICDX_VERSION_NO) &
                       pt_w_icd10$ICDX_VERSION_NO == "9-CM", "ICDX_DIAGNOSIS_CODE"] <-
            NA
    }

    pt_w_icd10$ICDX_VERSION_NO <- NULL
    com_pt10 <- icd::icd10_comorbid(
        pt_w_icd10,
        map = icd::icd10_map_quan_deyo,
        visit_name = "VISIT_NO",
        icd_name = "ICDX_DIAGNOSIS_CODE",
        short_code = T,
        short_map = T
    )

    #combine the results from 9 and 10
    com_pt <- com_pt9 | com_pt10

    score_pt <- icd::icd_charlson_from_comorbid(com_pt,
                                                scoring_system = "charlson", hierarchy = T)
    summary(score_pt)

    com_pt_n <- 1 * com_pt
    visit_no <-
        pt_w_icd[!duplicated(pt_w_icd$VISIT_NO), c("VISIT_NO", "AGE")]
    result <-
        cbind(data.frame(VISIT_NO = unique(pt_w_icd$VISIT_NO)),
              com_pt_n, score_pt)

    #join result and the age;
    result <- merge(result, visit_no, all = T)
    result$score <- result$score_pt

    result$score_age_adj <- NA
    #if age is not missing
    result[!is.na(result$AGE) & result$AGE <= 49, 'score_age_adj'] <- 0
    result[!is.na(result$AGE) & 50 <= result$AGE &
               result$AGE <= 59, 'score_age_adj'] <- 1
    result[!is.na(result$AGE) & 60 <= result$AGE &
               result$AGE <= 69, 'score_age_adj'] <- 2
    result[!is.na(result$AGE) & 70 <= result$AGE &
               result$AGE <= 79, 'score_age_adj'] <- 3
    result[!is.na(result$AGE) & 80 <= result$AGE &
               result$AGE <= 89, 'score_age_adj'] <- 4
    result[!is.na(result$AGE) & 90 <= result$AGE &
               result$AGE <= 99, 'score_age_adj'] <- 5
    result[!is.na(result$AGE) & 100 <= result$AGE, 'score_age_adj'] <- 6

    result$score_pt <- NULL
    result$AGE <- NULL
    result$score_age_adj <- result$score_age_adj + result$score

    if (look_back == 5) {
        names(result)[2:20] <- paste0("five_year_", names(result[2:20]))
    } else {
        names(result)[2:20] <- paste0("one_year_", names(result[2:20]))
    }

    return(result)
}
