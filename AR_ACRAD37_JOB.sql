--Drop the table
DROP TABLE IF EXISTS MIPS.DBO.ACRAD37_PE_FINAL_2024;

WITH ACRAD37_CTE (REPORTID, MEASURE_NUMBER, PATIENT_NAME, MRN, DOB, SEX, ACCESSION, APPOINTMENTDATE, APPOINTMENTTIME, MCODE, MODALITY, APPOINTMENTREASON, Reading_Radiologist, REPORTSIGNED, CPT)
AS
(
SELECT 
[REPORT].REPORTID
, 'ACRAD37' AS MEASURE_NUMBER
, pd.lastname + ', ' + pd.firstname AS PATIENT_NAME
, Patient.MRN AS MRN
, patient.DOB
, patient.Sex
, [ORDER].FillerOrderNumber AS ACCESSION
,  convert(varchar(10), [order].startdate, 101) as APPOINTMENTDATE
,  CONVERT(VARCHAR(8),CONVERT(TIME,[order].startdate)) AS APPOINTMENTTIME
, [ORDER].PROCEDURECODELIST AS MCODE
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, REPORT.LASTMODIFIEDDATE AS REPORTSIGNED
, p.CPT
FROM comm4_hhc.dbo.[Order] 
INNER JOIN COMM4_HHC.DBO.Report ON [Order].ReportID = Report.ReportID
INNER JOIN comm4_hhc.dbo.Visit ON [Order].VisitID = Visit.VisitID 
INNER JOIN comm4_hhc.dbo.Patient ON Visit.PatientID = Patient.PatientID 
left outer JOIN comm4_hhc.dbo.PersonalInfo PD on Patient.PersonalInfoID = PD.PersonalInfoID 
left outer join comm4_hhc.dbo.Account ON Report.DictatorAcctID = Account.AccountID 
left outer JOIN comm4_hhc.dbo.PersonalInfo pb on Account.PersonalInfoID = pb.PersonalInfoID 
left outer JOIN comm4_hhc.dbo.Account b on Report.SignerAcctID = b.AccountID 
left outer JOIN comm4_hhc.dbo.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID 
left outer join MIPS.dbo.HHC_CPT_PIVOT p ON P.[MPI: ID] =[ORDER].ProcedureCodeList 
WHERE [order].siteid = 8 
AND left([order].fillerordernumber, 2) not in ('CH', 'HM', 'MS', 'SV', 'WH') 
AND P.CPT IN ('71275') and [order].procedurecodelist = 'IMG2167' 
AND REPORT.LastModifiedDate >= '01/01/2024'
)

SELECT DISTINCT 
ACRAD37_CTE.APPOINTMENTDATE as EXAM_DATE_TIME
, ACRAD37_CTE.APPOINTMENTTIME
, '061614148' as PHYSICIAN_GROUP_TIN
, ProviderDim.NPI AS PHYSICIAN_NPI
, ACRAD37_CTE.Reading_Radiologist
, ACRAD37_CTE.REPORTSIGNED
, ACRAD37_CTE.MRN AS PATIENT_ID
, CONVERT(int,ROUND(DATEDIFF(hour, ACRAD37_CTE.DOB, ACRAD37_CTE.APPOINTMENTDATE)/8766.0,0)) as PATIENT_AGE
, ACRAD37_CTE.SEX AS PATIENT_GENDER
, 'ACRAD37' AS MEASURE_NUMBER
, APPOINTMENTREASON
, ACRAD37_CTE.CPT AS CPT_CODE
, ACRAD37_CTE.ACCESSION AS EXAM_UNIQUE_ID
, ACRAD37_CTE.MCODE
--, ACRAD37_CTE.PATIENT_NAME
--, ACRAD37_CTE.DOB
--, ACRAD37_CTE.MODALITY
, CASE WHEN (pass_measure IS NOT NULL) --if no pass phrases where found then the report is not in compliance 
	THEN 'Y' ELSE 'N' END AS NUMERATOR_RESPONSE_VALUE
INTO MIPS.DBO.ACRAD37_PE_FINAL_2024
FROM ACRAD37_CTE
-- inner join on the reports that meet the denominator specifications based on report content
INNER JOIN (
SELECT  DISTINCT ReportID,
-- Does the report have at least one of the phrases in it. if so, pass_measure will return the first phrase found
(SELECT TOP 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'Y' AND MEASURE = 'ACRAD37'
	and ARC_DW.DBO.Pull_HeadersV2(Report.ContentText, 'PULMONARY ARTERIES:', DEFAULT) LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
) pass_measure
FROM COMM4_HHC.DBO.Report 
-- filter out any reports that have a phrase that should be excluded from the denominator 
WHERE NOT EXISTS (select top 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE denominator = 'EXCLUDE' AND MEASURE = 'ACRAD37'
	and  Report.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%'))
) AS R
ON R.ReportID = ACRAD37_CTE.ReportID
INNER JOIN Caboodle.dbo.ImagingFact on ImagingFact.AccessionNumber = ACRAD37_CTE.ACCESSION
INNER JOIN Caboodle.dbo.ProviderDim on ImagingFact.FinalizingProviderDurableKey = ProviderDim.DurableKey and ProviderDim.npi <> '*Unspecified' 
INNER JOIN Caboodle.dbo.DepartmentDim on ImagingFact.PerformingDepartmentKey = DepartmentDim.DepartmentKey
WHERE departmentdim.departmentcenter = 'Advanced Radiology Partners' 
AND CONVERT(int,ROUND(DATEDIFF(hour, ACRAD37_CTE.DOB, ACRAD37_CTE.APPOINTMENTDATE)/8766.0,0)) >= 18
