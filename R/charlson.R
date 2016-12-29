#' Charlson score from visit_no
#'
#' This function calculates the Charlson score based on visit_no
#' @param conn the connection from connect_db
#' @param visit_no the visit_no from cds.cds_visit
#' @param look_back the time looking back 1 or 5 years
#' @export
#' @examples
#' \dontrun{
#' charlson(conn, "pt list.csv")
#' }
charlson <- function(conn, pt_list, out_file = NA, look_back = 5) {
  pt <- utils::read.csv(pt_list)
  names(pt)[1] <-  "VISIT_NO"
  #remove NA visit_no
  pt <- pt[!is.na(pt$VISIT_NO), , drop = F]

  #delete and create session.candidate
  tryCatch(
    RJDBC::dbSendUpdate(conn, "drop table session.candidate"),
    error = function(cond) {
      cat("notes: session.candidate does not exists\n")
    }
  )

  tryCatch(
    RJDBC::dbWriteTable(conn, "session.candidate", pt, overwrite = TRUE),
    error = function(cond) {
      cat("check if session.candidate was replace\n")
      stop(cond)
    }
  )

  #return the results from database
  sql_get_icd_5 <- readChar("../src/sql_get_icd_5.sql", 
                            file.info("../src/sql_get_icd_5.sql")$size)
  
  sql_get_icd_1 <- readChar("../src/sql_get_icd_1.sql",
                            file.info("../src/sql_get_icd_1.sql")$size)

  if (look_back == 5) {
    sql_get_icd = sql_get_icd_5
    cat("looking back 5 years\n")
  } else if (look_back == 1) {
    sql_get_icd = sql_get_icd_1
    cat("looking back 1 years\n")
  } else {
    sql_get_icd = sql_get_icd_5
    cat("wrong looking back, use default 5 years\n")
  }

  pt_w_icd <- RJDBC::dbGetQuery(conn, sql_get_icd)

  #merge with original input
  pt_w_icd <- merge(pt,
                    pt_w_icd,
                    by = 'VISIT_NO',
                    all = T,
                    sort = T)

  #remove dot and space in the code
  pt_w_icd[, c(2)] <- sub("\\.", "", pt_w_icd[, c(2)])
  pt_w_icd[, c(2, 3)] <- sapply(pt_w_icd[, c(2, 3)], trimws)

  #get icd9 comorbidity
  pt_w_icd9 <- pt_w_icd
  if (nrow(pt_w_icd9) > 0) {
  pt_w_icd9[!is.na(pt_w_icd9$ICDX_VERSION_NO) &
              pt_w_icd9$ICDX_VERSION_NO == "10-CM", "ICDX_DIAGNOSIS_CODE"] <- NA
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
               pt_w_icd10$ICDX_VERSION_NO == "9-CM", "ICDX_DIAGNOSIS_CODE"] <- NA      
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
                                              scoring_system = "quan", hierarchy = T)
  summary(score_pt)

  com_pt_n <- 1 * com_pt

  result <- cbind(pt, com_pt_n, score_pt)

  #the output file name
  if (is.na(out_file)) {
  out_file <- paste0(normalizePath(dirname(pt_list)),
                     "\\",
                     "pt-w-charlson-",
                     sub("\\.", "", format(Sys.time(), "%Y%m%d%H%M%OS2")),
                     ".csv")}
  write.csv(result, out_file, row.names = F)
  cat(paste0("file output to ", out_file, "\n"))
}
