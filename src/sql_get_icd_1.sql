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