--Drop the table
DROP TABLE MIPS.DBO.ACRAD37_PE_2024;

-- Repopulate this table : Patient ID name dob sex, order accession, appointment date time reason, mcode, modality, reading rad, signed date, Report ID text, measure, CPT, and split text 
-- this data contains adrad Computed tomographic angiography (CTA) of the chest (71275) exams only, in year 2024
SELECT 
[REPORT].REPORTID
, 'ACRAD37' AS MEASURE_NUMBER
, pd.lastname + ', ' + pd.firstname AS PATIENT_NAME
, Patient.MRN AS MRN
,patient.DOB
, patient.Sex
, [ORDER].FillerOrderNumber AS ACCESSION
,  convert(varchar(10), [order].startdate, 101) as APPOINTMENTDATE
,  CONVERT(VARCHAR(8),CONVERT(TIME,[order].startdate)) AS APPOINTMENTTIME
, [ORDER].PROCEDURECODELIST AS MCODE
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, REPORT.LASTMODIFIEDDATE AS REPORTSIGNED
, report.contenttext
, p.CPT
-- Split reports 
, ARC_DW.dbo.acrad37_striptext(report.contenttext,'PULMONARY ARTERIES:', 'Lymph Nodes:') as pulmonary_artery_text
into MIPS.DBO.ACRAD37_PE_2024
FROM comm4_hhc.dbo.Report 
INNER JOIN comm4_hhc.dbo.[Order] ON Report.ReportID = [Order].ReportID 
INNER JOIN comm4_hhc.dbo.Visit ON [Order].VisitID = Visit.VisitID 
INNER JOIN comm4_hhc.dbo.Patient ON Visit.PatientID = Patient.PatientID 
left outer JOIN comm4_hhc.dbo.PersonalInfo PD on Patient.PersonalInfoID = PD.PersonalInfoID 
left outer join comm4_hhc.dbo.Account ON Report.DictatorAcctID = Account.AccountID 
left outer JOIN comm4_hhc.dbo.PersonalInfo pb on Account.PersonalInfoID = pb.PersonalInfoID 
left outer JOIN comm4_hhc.dbo.Account b on Report.SignerAcctID = b.AccountID 
left outer JOIN comm4_hhc.dbo.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID 
left outer join MIPS.dbo.HHC_CPT_PIVOT p ON P.[MPI: ID] =[ORDER].ProcedureCodeList 
WHERE [order].siteid = 8 AND P.CPT IN ('71275') and [order].procedurecodelist = 'IMG2167' and (REPORT.LastModifiedDate >='1/1/2024' AND REPORT.LastModifiedDate < '1/1/2025')

--Drop the table
DROP TABLE MIPS.DBO.ACRAD37_PE_FINAL_2024;

-- Repopulate this table : 
-- this table calculates numerator response value based on split text. also filtering out exams that should be excluded from this measure 
SELECT distinct 
APPOINTMENTDATE as EXAM_DATE_TIME
, APPOINTMENTTIME
, '061614148' as PHYSICIAN_GROUP_TIN
, ProviderDim.NPI AS PHYSICIAN_NPI
,MIPS.DBO.ACRAD37_PE_2024.READING_RADIOLOGIST
, MIPS.DBO.ACRAD37_PE_2024.REPORTSIGNED
, MRN AS PATIENT_ID,
 CONVERT(int,ROUND(DATEDIFF(hour, ACRAD37_PE_2024.DOB, APPOINTMENTDATE)/8766.0,0)) as PATIENT_AGE
 , ACRAD37_PE_2024.SEX AS PATIENT_GENDER
, 'ACRAD37' AS MEASURE_NUMBER
, MIPS.DBO.ACRAD37_PE_2024.APPOINTMENTREASON
, ACRAD37_PE_2024.CPT AS CPT_CODE
, ACCESSION AS EXAM_UNIQUE_ID
, MIPS.DBO.ACRAD37_PE_2024.MCODE
, CASE WHEN (pulmonary_artery_text LIKE '%segmental%' 
OR pulmonary_artery_text LIKE '%saddle%'
or pulmonary_artery_text like '%main%'
or pulmonary_artery_text like '%lobar%'
or pulmonary_artery_text like '%central%'
or pulmonary_artery_text like '%medial basal segment%'
or pulmonary_artery_text like '%right%'
or pulmonary_artery_text like '%left%'
or pulmonary_artery_text like '%lower%'
or pulmonary_artery_text like '%upper%' 
or pulmonary_artery_text like '%filling defect in%'
or pulmonary_artery_text like '%filling defects in%')
THEN 'Y' ELSE 'N' END AS NUMERATOR_RESPONSE_VALUE
INTO MIPS.DBO.ACRAD37_PE_FINAL_2024
FROM MIPS.DBO.ACRAD37_PE_2024
inner join Caboodle.dbo.ImagingFact on ImagingFact.AccessionNumber = MIPS.DBO.ACRAD37_PE_2024.ACCESSION
inner join Caboodle.dbo.ProviderDim on ImagingFact.FinalizingProviderDurableKey = ProviderDim.DurableKey
inner join Caboodle.dbo.DepartmentDim on ImagingFact.PerformingDepartmentKey = DepartmentDim.DepartmentKey
WHERE  left([imagingfact].accessionnumber, 2) not in ('CH', 'HM', 'MS', 'SV', 'WH') and departmentdim.departmentcenter = 'Advanced Radiology Partners' and ProviderDim.npi <> '*Unspecified' and CONVERT(int,ROUND(DATEDIFF(hour, ACRAD37_PE_2024.DOB, APPOINTMENTDATE)/8766.0,0))  >= 18
AND pulmonary_artery_text NOT LIKE '%No evidence%'
AND pulmonary_artery_text NOT LIKE '%no %pulmonary embol%'
AND pulmonary_artery_text NOT LIKE '%no detect%'
AND pulmonary_artery_text NOT LIKE '%no acute%'
AND pulmonary_artery_text NOT LIKE '%no definite pulmonary embolism%'
AND pulmonary_artery_text NOT LIKE '%without a definitive pulmonary embolism%'
AND pulmonary_artery_text NOT LIKE '%no filling defect%'
AND pulmonary_artery_text NOT LIKE '%nondiagnostic examination%'
AND pulmonary_artery_text NOT LIKE '%without evidence of %';