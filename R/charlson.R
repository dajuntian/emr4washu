#' Charlson score from visit_no
#'
#' This function calculates the Charlson score based on visit_no
#' @param visit_no the visit_no from cds.cds_visit
#'
#' @export
#' @examples
#' \dontrun{
#' charlson(conn, "pt list.csv")
#' }
charlson <- function(conn, pt_list) {
  pt <- utils::read.csv(pt_list)
  names(pt)[1] <-  "VISIT_NO"

  #delete and create session.candidate
  tryCatch(
    RJDBC::dbSendUpdate(conn, "drop table session.candidate"),
    error = function(cond) {
      cat("notes: session.candidate does not exists")
    }
  )

  tryCatch(
    RJDBC::dbWriteTable(conn, "session.candidate", pt, overwrite = TRUE),
    error = function(cond) {
      cat("check if session.candidate was replace")
      stop(cond)
    }
  )

  #return the results from database
  sql_get_icd_5 <-
    "
  select c.visit_no, icdx.ICDX_Diagnosis_Code, icdx.ICDX_Version_No
  from session.candidate c
  join cds.cds_visit index_cv
  on c.visit_no = index_cv.visit_no
  join cds.registration index_reg
  on index_cv.reg_no = index_reg.reg_no
  and index_cv.facility_concept_id = index_reg.facility_concept_id
  join cds.registration pre_reg
  on index_reg.reference_no = pre_reg.reference_no
  and pre_reg.admit_date <= index_reg.admit_date
  and pre_reg.admit_date >= (index_reg.admit_date - 5 years)
  join cds.cds_visit pre_cv
  on pre_reg.reg_no = pre_cv.reg_no
  and pre_reg.facility_concept_id = pre_cv.facility_concept_id
  join cds.registration_icdx_diagnosis icdx
  on pre_cv.visit_no = icdx.visit_no
  order by c.visit_no
  "
  sql_get_icd_1 <-
    "
  select c.visit_no, icdx.ICDX_Diagnosis_Code, icdx.ICDX_Version_No
  from session.candidate c
  join cds.cds_visit index_cv
  on c.visit_no = index_cv.visit_no
  join cds.registration index_reg
  on index_cv.reg_no = index_reg.reg_no
  and index_cv.facility_concept_id = index_reg.facility_concept_id
  join cds.registration pre_reg
  on index_reg.reference_no = pre_reg.reference_no
  and pre_reg.admit_date <= index_reg.admit_date
  and pre_reg.admit_date >= (index_reg.admit_date - 1 years)
  join cds.cds_visit pre_cv
  on pre_reg.reg_no = pre_cv.reg_no
  and pre_reg.facility_concept_id = pre_cv.facility_concept_id
  join cds.registration_icdx_diagnosis icdx
  on pre_cv.visit_no = icdx.visit_no
  order by c.visit_no
  "

  if (look_back == 5) {
    sql_get_icd = sql_get_icd_5
    cat("looking back 5 years")
  } else if (look_back == 1) {
    sql_get_icd = sql_get_icd_1
    cat("looking back 1 years")
  } else {
    sql_get_icd = sql_get_icd_5
    cat("wrong looking back, use default 5 years")
  }

  pt_w_icd <- RJDBC::dbGetQuery(conn, sql_get_icd)

  #merge with original input
  pt_w_icd <- merge(pt,
                    pt_w_icd,
                    by = 'VISIT_NO',
                    all = T,
                    sort = T)

  #remove space in the code
  pt_w_icd[, c(2, 3)] <- sapply(pt_w_icd[, c(2, 3)], trimws)


  #get icd9 comorbidity
  pt_w_icd9 <- pt_w_icd
  pt_w_icd9[pt_w_icd9$ICDX_VERSION_NO == "10-CM", "ICDX_DIAGNOSIS_CODE"] <-
    NA
  pt_w_icd9$ICDX_VERSION_NO <- NULL
  com_pt9 <- icd::icd9_comorbid(
    pt_w_icd9,
    map = icd::icd9_map_quan_deyo,
    visit_name = "VISIT_NO",
    icd_name = "ICDX_DIAGNOSIS_CODE",
    short_code = F
  )

  #get icd10 comirbidity
  pt_w_icd10 <- pt_w_icd
  pt_w_icd10[pt_w_icd10$ICDX_VERSION_NO == "9-CM", "ICDX_DIAGNOSIS_CODE"] <-
    NA
  pt_w_icd10$ICDX_VERSION_NO <- NULL
  com_pt10 <- icd::icd10_comorbid(
    pt_w_icd10,
    map = icd::icd10_map_quan_deyo,
    visit_name = "VISIT_NO",
    icd_name = "ICDX_DIAGNOSIS_CODE",
    short_code = F
  )

  #combine the results from 9 and 10
  com_pt <- com_pt9 | com_pt10

  score_pt <- icd::icd_charlson_from_comorbid(com_pt,
                                              scoring_system = "charlson", hierarchy = T)
  summary(score_pt)

  com_pt_n <- 1 * com_pt

  result <- cbind(pt, com_pt_n, score_pt)

  #the output file name
  out_file <- paste0(normalizePath(dirname(pt_list)),
                     "\\",
                     "pt-w-charlson-",
                     sub("\\.", "", format(Sys.time(), "%Y%m%d%H%M%OS2")),
                     ".csv")
  write.csv(result, out_file, row.names = F)
  cat(paste0("file output to ", out_file))

}
