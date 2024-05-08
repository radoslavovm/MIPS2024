DROP TABLE IF EXISTS MIPS.DBO.CAT_436_2024_FINAL;

WITH CAT436_CTE (ReportID, SignerAcctID, MEASURE_NUMBER, PATIENT_NAME, MRN, ACCESSION, APPOINTMENTDATE, MCODE, MODALITY, APPOINTMENTREASON, Reading_Radiologist, performance_met)
AS (
SELECT DISTINCT
REPORT.ReportID, Report.SignerAcctID
, '436' AS MEASURE_NUMBER
, RTRIM(PatientDemo.LastName + ', ' + PatientDemo.FirstName + ' ' + case when PatientDemo.MiddleName is null or PatientDemo.MiddleName = '' then '' else PatientDemo.Middlename end) AS PATIENT_NAME
, PATIENT.MRN 
, [ORDER].FillerOrderNumber AS ACCESSION
,  CONVERT(VARCHAR(12), [ORDER].STARTDATE, 101) as APPOINTMENTDATE
, [ORDER].PROCEDURECODELIST AS MCODE
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, R.performance_met
FROM (
SELECT  DISTINCT ReportID,
(SELECT TOP 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'Y' AND MEASURE = '436'
	and Report.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
) performance_met
FROM COMM4_HHC.DBO.Report
) AS R 
INNER JOIN COMM4_HHC.DBO.Report ON R.ReportID = REPORT.ReportID
INNER JOIN COMM4_HHC.DBO.[Order] ON Report.ReportID = [Order].ReportID 
INNER JOIN COMM4_HHC.DBO.Visit ON [Order].VisitID = Visit.VisitID 
INNER JOIN COMM4_HHC.DBO.Patient ON Visit.PatientID = Patient.PatientID 
left outer JOIN COMM4_HHC.DBO.PersonalInfo PatientDemo on Patient.PersonalInfoID = PatientDemo.PersonalInfoID 
left outer join COMM4_HHC.DBO.Account ON Report.DictatorAcctID = Account.AccountID 
left outer JOIN COMM4_HHC.DBO.PersonalInfo pb on Account.PersonalInfoID = pb.PersonalInfoID 
left outer JOIN COMM4_HHC.DBO.Account b on Report.SignerAcctID = b.AccountID 
left outer JOIN COMM4_HHC.DBO.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID 
INNER JOIN MIPS.DBO.HHC_CPT_PIVOT ON [ORDER].ProcedureCodeList = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID]
										AND MIPS.DBO.HHC_CPT_PIVOT.CPT IN ('70450', '70460', '70470', '70480', '70481', '70482', '70486', '70487', '70488', '70490', '70491', '70492', '70496', '70498', '71250', '71260', '71270', '71271'
										, '71275', '72125', '72126', '72127', '72128', '72129', '72130', '72131', '72132', '72133', '72191', '72192', '72193', '72194', '73200', '73201', '73202', '73206', '73700', '73701'
										, '73702', '73706', '74150', '74160', '74170', '74174', '74175', '74176', '74177', '74178', '74261', '74262', '74263', '75571', '75572', '75573', '75574', '75635', '76380', '76497'
										, '77011', '77012', '77013', '77014', '77078', '0042T', 'G0297')
WHERE  [ORDER].SITEID = 8 
and left([order].fillerordernumber, 2) not in ('CH', 'HM', 'MS', 'SV', 'WH') 
and [order].PROCEDURECODELIST <> 'IMG1154C' and [order].explorerstatus IN ('FINAL', 'FINAL (A)')  
and ([ORDER].FILLERORDERNUMBER NOT LIKE '%PWH' AND [ORDER].FILLERORDERNUMBER NOT LIKE '%SMA' 
AND [ORDER].FILLERORDERNUMBER NOT LIKE '%SWC') 
AND REPORT.LastModifiedDate >= '01/01/2024' 
)

SELECT DISTINCT  
CONVERT(VARCHAR(10), APPOINTMENTDATE, 101) as EXAM_DATE_TIME
, '061614148' as PHYSICIAN_GROUP_TIN
, case when CAT_436_2024.READING_RADIOLOGIST = 'Adam Kaye' then '1881838118' 
       when CAT_436_2024.READING_RADIOLOGIST = 'Betty Mathew' then '1093153314'  
	   when CAT_436_2024.READING_RADIOLOGIST = 'Eran Rotem' then '1912294182'  
	   when CAT_436_2024.READING_RADIOLOGIST = 'Joshua Sapire' then '1164452066'  
	   when CAT_436_2024.READING_RADIOLOGIST = 'Kelly Harkins-Squitieri' then '1518915990'  
	   when CAT_436_2024.READING_RADIOLOGIST = 'Kenneth Zinn' then '1609861285' 
	   when CAT_436_2024.READING_RADIOLOGIST = 'Noel Velasco' then '1922093590' 
	   when CAT_436_2024.READING_RADIOLOGIST = 'Scott Smith' then '1952496424' 
	   when CAT_436_2024.READING_RADIOLOGIST = 'Terence Hughes' then '1053307421' 
	   else ProviderDim.npi end AS PHYSICIAN_NPI
, CAT436_CTE.READING_RADIOLOGIST
, PATIENT.MRN AS PATIENT_ID
, CONVERT(int,ROUND(DATEDIFF(hour,patient.dob, CAT436_CTE.appointmentdate)/8766.0,0)) as PATIENT_AGE
, PATIENT.SEX AS PATIENT_GENDER
, CASE WHEN CoverageDim.PayorFinancialClass IN ('MEDICARE', 'MEDICAREMC') THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_BENEFICIARY
, CASE WHEN (CoverageDim.PayorFinancialClass IN ('Managed Medicare', 'Medicare') 
		AND CoverageDim.BenefitPlanName NOT IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC',
			'HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD', 'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS',
			'ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO',
			'CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS',
			'AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE','AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS')) 
	OR (CoverageDim.PayorFinancialClass IN ('MEDICARE', 'MEDICAREMC') 
		AND CoverageDim.BenefitPlanName IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE',
			'HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD','HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT',
			'ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE',
			'CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE',
			'AETNA MEDICARE ADVANTAGE','AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS') 
	AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob, CAT436_CTE.appointmentdate)/8766.0,0))  >= 65) THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_ADVANTAGE
, MEASURE_NUMBER
, CAT436_CTE.APPOINTMENTREASON
, MIPS.DBO.HHC_CPT_PIVOT.CPT AS CPT_CODE
, '' as DENOMINATOR_DIAGNOSIS_CODE
, CASE WHEN (
	CAT436_CTE.performance_met IS NOT NULL
	) THEN 'G9637' ELSE 'G9638' END AS NUMERATOR_RESPONSE_VALUE
, '' AS MEASURE_EXTENSION_NUM
, '' AS EXTENSION_RESPONSE_VALUE
, [ORDER].FILLERORDERNUMBER AS EXAM_UNIQUE_ID
, CAT436_CTE.MCODE
into MIPS.DBO.CAT_436_2024_FINAL
FROM CAT436_CTE
Inner join comm4_hhc.dbo.[order] on [order].FillerOrderNumber = CAT436_CTE.ACCESSION
inner join comm4_hhc.dbo.visit on [order].visitid = visit.visitid
inner join comm4_hhc.dbo.patient on patient.patientid = visit.patientid
inner join comm4_hhc.dbo.account on CAT436_CTE.SignerAcctID = account.AccountID
inner join comm4_hhc.dbo.PersonalInfo ON account.PersonalInfoID = PersonalInfo.PersonalInfoID
inner join Caboodle.dbo.ImagingFact on [order].fillerordernumber = ImagingFact.AccessionNumber
inner join Caboodle.dbo.[providerdim] on ImagingFact.FinalizingProviderDurableKey = ProviderDim.DurableKey and ProviderDim.npi <> '*Unspecified' 
inner join Caboodle.dbo.EncounterFact  on ImagingFact.PerformingEncounterKey = EncounterFact.EncounterKey
inner join Caboodle.dbo.CoverageDim on EncounterFact.PrimaryCoverageKey = CoverageDim.CoverageKey
inner join Caboodle.dbo.DepartmentDim on ImagingFact.PerformingDepartmentKey = DepartmentDim.DepartmentKey
left outer join MIPS.DBO.HHC_CPT_PIVOT ON MIPS.DBO.CAT_436_2024.MCODE = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID]
						 AND MIPS.DBO.HHC_CPT_PIVOT.CPT in (
						   '70450', '70460', '70470', '70480', '70481', '70482', '70486', '70487', '70488', '70490', '70491', '70492', '70496', '70498', '71250', '71260', '71270', '71271'
						 , '71275', '72125', '72126', '72127', '72128', '72129', '72130', '72131', '72132', '72133', '72191', '72192', '72193', '72194', '73200', '73201', '73202', '73206', '73700', '73701'
						 , '73702', '73706', '74150', '74160', '74170', '74174', '74175', '74176', '74177', '74178', '74261', '74262', '74263', '75571', '75572', '75573', '75574', '75635', '76380', '76497'
						 , '77011', '77012', '77013', '77014', '77078', '0042T', 'G0297')
WHERE [ORDER].SITEID = 8  
AND departmentdim.departmentcenter = 'Advanced Radiology Partners' 
AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob, CAT436_CTE.appointmentdate)/8766.0,0))>= 18
;

UPDATE MIPS.DBO.CAT_436_2024_FINAL
SET NUMERATOR_RESPONSE_VALUE = 'G9637'
WHERE  NUMERATOR_RESPONSE_VALUE = 'G9638'
AND EXISTS 
	(SELECT DISTINCT EXAM_UNIQUE_ID
		FROM MIPS.DBO.CAT_436_2024_FINAL
		Inner join comm4_hhc.dbo.[order] 
			ON [order].FillerOrderNumber = CAT_436_2024_FINAL.EXAM_UNIQUE_ID
		INNER JOIN COMM4_HHC.DBO.Report 
			ON [order].ReportID = Report.ReportID
		INNER JOIN comm4_HHC.dbo.reportaddendum 
			ON report.reportid = reportaddendum.OriginalReportID
		INNER JOIN comm4_HHC.dbo.report AS addend 
			ON addend.reportid = ReportAddendum.AddendumReportID
		WHERE EXISTS (
			SELECT 1 
			FROM ARC_DW.DBO.REPORT_PHRASES
			WHERE CRITERIA = 'Y' AND MEASURE = '436'
			AND addend.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
				)
			)