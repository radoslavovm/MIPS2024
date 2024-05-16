
DROP TABLE IF EXISTS MIPS.DBO.MSN_15_2024;
DROP TABLE IF EXISTS MIPS.DBO.MSN_15_2024_FINAL;

SELECT DISTINCT R.REPORTID
, 'MSN15' AS MEASURE_NUMBER
, RTRIM(PatientDemo.LastName + ', ' + PatientDemo.FirstName + ' ' + case when PatientDemo.MiddleName is null or PatientDemo.MiddleName = '' then '' else PatientDemo.Middlename end) AS PATIENT_NAME
, PATIENT.MRN 
, [ORDER].FillerOrderNumber AS ACCESSION
, CONVERT(VARCHAR(12), [ORDER].STARTDATE, 101) as APPOINTMENTDATE
, [ORDER].PROCEDURECODELIST AS MCODE
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, R.contenttext
, r.pass_measure
into MIPS.DBO.MSN_15_2024
FROM (
SELECT DISTINCT ReportID, contenttext, DictatorAcctID, SignerAcctID, LastModifiedDate,
-- Does the report have at least one of the phrases in it. if so, pass_measure will return the first phrase found
(SELECT TOP 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'PM004' AND MEASURE = 'MSN15'
	and Report.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
) pass_measure
FROM COMM4_HHC.dbo.Report 
-- filter out any reports that have a phrase that should be excluded from the denominator 
WHERE NOT EXISTS (select top 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE DENOMINATOR = 'EXCLUDE' AND MEASURE = 'MSN15'
	and  Report.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%'))
) AS R
INNER JOIN COMM4_HHC.DBO.[Order] ON R.ReportID = [Order].ReportID 
INNER JOIN COMM4_HHC.DBO.Visit ON [Order].VisitID = Visit.VisitID 
INNER JOIN COMM4_HHC.DBO.Patient ON Visit.PatientID = Patient.PatientID 
left outer JOIN COMM4_HHC.DBO.PersonalInfo PatientDemo on Patient.PersonalInfoID = PatientDemo.PersonalInfoID 
left outer join COMM4_HHC.DBO.Account ON R.DictatorAcctID = Account.AccountID 
left outer JOIN COMM4_HHC.DBO.PersonalInfo pb on Account.PersonalInfoID = pb.PersonalInfoID 
left outer JOIN COMM4_HHC.DBO.Account b on R.SignerAcctID = b.AccountID 
left outer JOIN COMM4_HHC.DBO.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID 
INNER JOIN MIPS.DBO.HHC_CPT_PIVOT ON [ORDER].ProcedureCodeList = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID]
										AND MIPS.DBO.HHC_CPT_PIVOT.CPT IN ('76536')
WHERE  [ORDER].SITEID = 8 
AND left([order].fillerordernumber, 2) not in ('CH', 'HM', 'MS', 'SV', 'WH') 
AND [order].explorerstatus IN ('FINAL', 'FINAL (A)')  
AND ([ORDER].FILLERORDERNUMBER NOT LIKE '%PWH' 
	AND [ORDER].FILLERORDERNUMBER NOT LIKE '%SMA' 
	AND [ORDER].FILLERORDERNUMBER NOT LIKE '%SWC') 
AND (R.LastModifiedDate >= '1/1/2024' and R.LastModifiedDate < '1/1/2025');
		
SELECT distinct  
CONVERT(VARCHAR(10), APPOINTMENTDATE, 101) as EXAM_DATE_TIME
, '061614148' as PHYSICIAN_GROUP_TIN
, case when MSN_15_2024.READING_RADIOLOGIST = 'Adam Kaye' then '1881838118' 
       when MSN_15_2024.READING_RADIOLOGIST = 'Betty Mathew' then '1093153314'  
	   when MSN_15_2024.READING_RADIOLOGIST = 'Eran Rotem' then '1912294182'  
	   when MSN_15_2024.READING_RADIOLOGIST = 'Joshua Sapire' then '1164452066'  
	   when MSN_15_2024.READING_RADIOLOGIST = 'Kelly Harkins-Squitieri' then '1518915990'  
	   when MSN_15_2024.READING_RADIOLOGIST = 'Kenneth Zinn' then '1609861285' 
	   when MSN_15_2024.READING_RADIOLOGIST = 'Noel Velasco' then '1922093590' 
	   when MSN_15_2024.READING_RADIOLOGIST = 'Scott Smith' then '1952496424' 
	   when MSN_15_2024.READING_RADIOLOGIST = 'Terence Hughes' then '1053307421' 
	   else ProviderDim.npi end AS PHYSICIAN_NPI
, MSN_15_2024.READING_RADIOLOGIST
, PATIENT.MRN AS PATIENT_ID
, CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,mips.dbo.MSN_15_2024.appointmentdate)/8766.0,0)) as PATIENT_AGE
, PATIENT.SEX AS PATIENT_GENDER
, CASE WHEN CoverageDim.PayorFinancialClass IN ('MEDICARE', 'MEDICAREMC') THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_BENEFICIARY
, CASE WHEN (CoverageDim.PayorFinancialClass IN ('MEDICARE', 'MEDICAREMC') and CoverageDim.BenefitPlanName NOT IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD',
'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE',
'AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS')) or (CoverageDim.PayorFinancialClass IN ('MEDICARE', 'MEDICAREMC') and CoverageDim.BenefitPlanName IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD',
'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE',
'AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS') AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,mips.dbo.MSN_15_2024.appointmentdate)/8766.0,0))  >= 65) THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_ADVANTAGE
, 'MSN15' AS MEASURE_NUMBER
, MSN_15_2024.APPOINTMENTREASON
, MIPS.DBO.HHC_CPT_PIVOT.CPT AS CPT_CODE
, '' as DENOMINATOR_DIAGNOSIS_CODE
, CASE WHEN (MSN_15_2024.pass_measure IS NOT NULL) THEN 'PM004' 
       when RP.PHRASE_ID IS NOT NULL 
	   then 'PE004'
	   ELSE 'PNM04' END AS NUMERATOR_RESPONSE_VALUE
, '' AS MEASURE_EXTENSION_NUM
, '' AS EXTENSION_RESPONSE_VALUE
, [ORDER].FILLERORDERNUMBER AS EXAM_UNIQUE_ID
, MSN_15_2024.MCODE
into MIPS.DBO.MSN_15_2024_FINAL
FROM MIPS.DBO.MSN_15_2024
inner join comm4_HHC.dbo.report on MSN_15_2024.ReportID = report.reportid
Inner join comm4_hhc.dbo.[order] on report.reportid = [order].reportid
inner join comm4_hhc.dbo.visit on [order].visitid = visit.visitid
inner join comm4_hhc.dbo.patient on patient.patientid = visit.patientid
inner join comm4_hhc.dbo.account on Report.SignerAcctID = account.AccountID
inner join comm4_hhc.dbo.PersonalInfo ON account.PersonalInfoID = PersonalInfo.PersonalInfoID
inner join Caboodle.dbo.ImagingFact on [order].fillerordernumber = ImagingFact.AccessionNumber
inner join Caboodle.dbo.[providerdim] on ImagingFact.FinalizingProviderDurableKey = ProviderDim.DurableKey and ProviderDim.npi <> '*Unspecified' 
inner join Caboodle.dbo.EncounterFact  on ImagingFact.PerformingEncounterKey = EncounterFact.EncounterKey
inner join Caboodle.dbo.CoverageDim on EncounterFact.PrimaryCoverageKey = CoverageDim.CoverageKey
inner join Caboodle.dbo.DepartmentDim on ImagingFact.PerformingDepartmentKey = DepartmentDim.DepartmentKey
left outer join MIPS.DBO.HHC_CPT_PIVOT ON MIPS.DBO.MSN_15_2024.MCODE = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID] AND MIPS.DBO.HHC_CPT_PIVOT.CPT in ('76536')
LEFT OUTER JOIN (
	SELECT * FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'PE' AND MEASURE = 'MSN15') AS RP ON REPORT.ContentText LIKE CONCAT('%',RP.PHRASE,'%')
where [ORDER].SITEID = 8 and departmentdim.departmentcenter = 'Advanced Radiology Partners' AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,mips.dbo.MSN_15_2024.appointmentdate)/8766.0,0))>= 19
;