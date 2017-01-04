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
# charlson <- function(conn, pt_list, out_file = NA, look_back = 5) {
charlson <- function(conn, inData, outData, look_back = 5) {    
  sql_get_icd_5 <- paste0("
    select distinct c.visit_no, icdx.ICDX_Diagnosis_Code, icdx.ICDX_Version_No,
    case when 
                          pre_reg.admit_date >= (index_reg.admit_date - 1 years) then 1
                          else 5
                          end as year_back,
                          floor( (days(index_reg.discharge_date)-days(p.dob))/365.25) AS age
                          
                          from ",
    inData, 
 " c
join cds.cds_visit index_cv
 on c.visit_no = index_cv.visit_no
 join cds.registration index_reg
 on index_cv.reg_no = index_reg.reg_no
 and index_cv.facility_concept_id = index_reg.facility_concept_id
 join cds.patient p
 on index_reg.reference_no = p.reference_no
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
  ")  
  
  sql_get_icd = sql_get_icd_5


  pt_w_icd <- RJDBC::dbGetQuery(conn, sql_get_icd)
  result_5 <- .help_df2score(pt_w_icd, 5)
  
  #get results for one year look back
  pt_w_icd[pt_w_icd$YEAR_BACK == 5, "ICDX_DIAGNOSIS_CODE"] <- NA
  result_1 <- .help_df2score(pt_w_icd, 1)
  
  #output data to user
  dbWriteTable(conn, outData, result_5)

  cat(paste0("\ndata output to ", outData, "\n"))
}

.help_df2score <- function(pt_w_icd, look_back) {
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
                                                scoring_system = "charlson", hierarchy = T)
    summary(score_pt)
    
    com_pt_n <- 1 * com_pt
    visit_no <- pt_w_icd[!duplicated(pt_w_icd$VISIT_NO), c("VISIT_NO", "AGE")]
    result <- cbind(data.frame(VISIT_NO = unique(pt_w_icd$VISIT_NO)),
                    com_pt_n, score_pt)
    
    #join result and the age;
    result <- merge(result, visit_no, all = T)
    result$score <- result$score_pt
    result <- within(result,{
        score_age_adj <- NA
        score_age_adj[AGE <= 49] <- 0
        score_age_adj[50 <= AGE & AGE <= 59] <- 1
        score_age_adj[60 <= AGE & AGE <= 69] <- 2
        score_age_adj[70 <= AGE & AGE <= 79] <- 3
        score_age_adj[80 <= AGE & AGE <= 89] <- 4
        score_age_adj[90 <= AGE & AGE <= 99] <- 5
        score_age_adj[100 <= AGE] <- 6
    })
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
