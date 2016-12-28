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
charlson <- function(conn, pt_list){
  
  pt <- utils::read.csv(pt_list)
  
  RJDBC::dbSendUpdate(conn, "drop table session.candidate")
  RJDBC::dbWriteTable(conn, "session.candidate", pt, overwrite = TRUE)
  
  #return the results from database
  sql_get_icd <- 
    "
  select c.visit_no, icdx.ICDX_Diagnosis_Code
  from session.candidate c
  join cds.cds_visit index_cv 
  on c.visit_no = index_cv.visit_no
  join cds.registration index_reg 
  on index_cv.reg_no = index_reg.reg_no and index_cv.facility_concept_id = index_reg.facility_concept_id
  join cds.registration pre_reg   
  on index_reg.reference_no = pre_reg.reference_no
  and pre_reg.admit_date <= index_reg.admit_date
  and pre_reg.admit_date >= (index_reg.admit_date - 5 years)
  join cds.cds_visit pre_cv
  on pre_reg.reg_no = pre_cv.reg_no and pre_reg.facility_concept_id = pre_cv.facility_concept_id 
  join cds.registration_icdx_diagnosis icdx 
  on pre_cv.visit_no = icdx.visit_no
  order by c.visit_no"
  
  pt_w_icd <- RJDBC::dbGetQuery(conn, sql_get_icd)
  
  #remove space in the code
  pt_w_icd$ICDX_DIAGNOSIS_CODE <- trimws( pt_w_icd$ICDX_DIAGNOSIS_CODE)
  
  #get icd9 comorbidity
  com_pt9 <- icd::icd9_comorbid(pt_w_icd, map = icd::icd9_map_quan_deyo)
  
  #get icd10 comirbidity
  com_pt10 <- icd::icd10_comorbid(pt_w_icd, map = icd::icd10_map_quan_deyo)
  
  com_pt <- com_pt9 | com_pt10
  
  score_pt <- icd::icd_charlson_from_comorbid(com_pt, 
                                              scoring_system = "charlson", hierarchy = T)
  summary(score_pt)
  
  com_pt_n <- 1 * com_pt
  
  result <- cbind(pt, com_pt_n, score_pt)
  
  write.csv(result, "pt-w-charlson.csv", row.names = F)
  
}


