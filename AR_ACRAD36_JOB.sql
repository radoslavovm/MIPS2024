
DROP TABLE IF EXISTS MIPS.DBO.ACRAD36_CORONARYARTERY_FINAL_2024;

WITH ACRAD36_CTE (REPORTID, MEASURE_NUMBER, PATIENT_NAME, MRN, DOB, SEX, ACCESSION, APPOINTMENTDATE, APPOINTMENTTIME, MCODE, MODALITY, APPOINTMENTREASON, Reading_Radiologist, 
REPORTSIGNED, contenttext, pass_measure, CPT)
AS
(
SELECT 
R.REPORTID
, 'ACRAD36' AS MEASURE_NUMBER
, pd.lastname + ', ' + pd.firstname AS PATIENT_NAME
, Patient.MRN AS MRN
, patient.DOB
, patient.SEX
, [ORDER].FillerOrderNumber AS ACCESSION
,  convert(varchar(10), [order].startdate, 101) as APPOINTMENTDATE
,  CONVERT(VARCHAR(8),CONVERT(TIME,[order].startdate)) AS APPOINTMENTTIME
, [ORDER].PROCEDURECODELIST AS MCODE
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, R.LASTMODIFIEDDATE AS REPORTSIGNED
, R.contenttext
, pass_measure
, p.CPT
FROM (
SELECT DISTINCT ReportID, DictatorAcctID, SignerAcctID, LastModifiedDate, report.contenttext,
-- Does the report have at least one of the phrases in it. if so, pass_measure will return the first phrase found
(SELECT TOP 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'Y' AND MEASURE = 'ACRAD36'
	and REPORT.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
) pass_measure
FROM COMM4_HHC.DBO.Report 
-- filter out any reports that have a phrase that should be excluded from the denominator 
WHERE NOT EXISTS (select top 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE denominator = 'EXCLUDE' AND MEASURE = 'ACRAD36'
	and  Report.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%'))
) AS R
INNER JOIN comm4_hhc.dbo.[Order] ON R.ReportID = [Order].ReportID 
INNER JOIN comm4_hhc.dbo.Visit ON [Order].VisitID = Visit.VisitID 
INNER JOIN comm4_hhc.dbo.Patient ON Visit.PatientID = Patient.PatientID 
left outer JOIN comm4_hhc.dbo.PersonalInfo PD on Patient.PersonalInfoID = PD.PersonalInfoID 
left outer join comm4_hhc.dbo.Account ON R.DictatorAcctID = Account.AccountID 
left outer JOIN comm4_hhc.dbo.PersonalInfo pb on Account.PersonalInfoID = pb.PersonalInfoID 
left outer JOIN comm4_hhc.dbo.Account b on R.SignerAcctID = b.AccountID 
left outer JOIN comm4_hhc.dbo.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID 
left outer join MIPS.dbo.HHC_CPT_PIVOT p ON P.[MPI: ID] =[ORDER].ProcedureCodeList 
WHERE [order].siteid = 8 
and left([order].fillerordernumber, 2) not in ('CH', 'HM', 'MS', 'SV', 'WH') 
AND P.CPT IN ('71250','71270') 
and (R.LastModifiedDate >='1/1/2024' 
AND R.LastModifiedDate < '1/1/2025' 
and [order].ProcedureDescList like '%CHEST%')
)


SELECT distinct 
ACRAD36_CTE.APPOINTMENTDATE as EXAM_DATE_TIME
, ACRAD36_CTE.APPOINTMENTTIME
, '061614148' as PHYSICIAN_GROUP_TIN
, case when ACRAD36_CTE.READING_RADIOLOGIST = 'Noel Velasco' then '1922093590' 
       when ACRAD36_CTE.READING_RADIOLOGIST = 'Sudhir Kunchala' then '2005102554'
	   when ACRAD36_CTE.READING_RADIOLOGIST = 'Thomas Dibartholomeo' then '1598782492'
	   else ProviderDim.NPI end AS PHYSICIAN_NPI
, ACRAD36_CTE.READING_RADIOLOGIST
, ACRAD36_CTE.REPORTSIGNED
, ACRAD36_CTE.MRN AS PATIENT_ID
, CONVERT(int,ROUND(DATEDIFF(hour, ACRAD36_CTE.DOB, APPOINTMENTDATE)/8766.0,0)) as PATIENT_AGE
, ACRAD36_CTE.SEX AS PATIENT_GENDER
, 'ACRAD36' AS MEASURE_NUMBER
, ACRAD36_CTE.APPOINTMENTREASON
, ACRAD36_CTE.CPT AS CPT_CODE
, CASE WHEN ACRAD36_CTE.pass_measure IS NOT NULL THEN 'Y' ELSE 'N' END AS NUMERATOR_RESPONSE_VALUE 
, ACRAD36_CTE.ACCESSION AS EXAM_UNIQUE_ID
, ACRAD36_CTE.MCODE  
INTO MIPS.DBO.ACRAD36_CORONARYARTERY_FINAL_2024
FROM ACRAD36_CTE
inner join Caboodle.dbo.ImagingFact on ImagingFact.AccessionNumber = ACRAD36_CTE.ACCESSION
inner join Caboodle.dbo.ProviderDim on ImagingFact.FinalizingProviderDurableKey = ProviderDim.DurableKey
inner join Caboodle.dbo.DepartmentDim on ImagingFact.PerformingDepartmentKey = DepartmentDim.DepartmentKey

where left([imagingfact].accessionnumber, 2) not in ('CH', 'HM', 'MS', 'SV', 'WH') 
and departmentdim.departmentcenter = 'Advanced Radiology Partners'
and (
	(CONVERT(int,ROUND(DATEDIFF(hour, ACRAD36_CTE.DOB, APPOINTMENTDATE)/8766.0,0))  between 18 and 50 
		and ACRAD36_CTE.SEX = 'M')
	or (CONVERT(int,ROUND(DATEDIFF(hour, ACRAD36_CTE.DOB, APPOINTMENTDATE)/8766.0,0)) between 18 and 65 
		and ACRAD36_CTE.SEX = 'F')
		)
;

UPDATE MIPS.DBO.ACRAD36_CORONARYARTERY_FINAL_2024
SET NUMERATOR_RESPONSE_VALUE = 'Y'
WHERE  NUMERATOR_RESPONSE_VALUE = 'N'
AND left(ACRAD36_CORONARYARTERY_FINAL_2024.EXAM_UNIQUE_ID, 2) in ('AR')
AND EXISTS 
	(SELECT DISTINCT ACRAD36_CORONARYARTERY_FINAL_2024.EXAM_UNIQUE_ID
		FROM MIPS.DBO.ACRAD36_CORONARYARTERY_FINAL_2024
		Inner join comm4_hhc.dbo.[order] 
			ON [order].FillerOrderNumber = ACRAD36_CORONARYARTERY_FINAL_2024.EXAM_UNIQUE_ID
		INNER JOIN COMM4_HHC.DBO.Report 
			ON [order].ReportID = Report.ReportID
		INNER JOIN comm4_HHC.dbo.reportaddendum 
			ON report.reportid = reportaddendum.OriginalReportID
		INNER JOIN comm4_HHC.dbo.report AS addend 
			ON addend.reportid = ReportAddendum.AddendumReportID
		WHERE EXISTS (
			SELECT 1 
			FROM ARC_DW.DBO.REPORT_PHRASES
			WHERE CRITERIA = 'Y' AND MEASURE = 'ACRAD36'
			AND addend.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
				)
			)
;
