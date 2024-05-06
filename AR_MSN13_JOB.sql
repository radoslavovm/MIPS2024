
DROP TABLE MIPS.DBO.MSN_13_2024; 
SELECT DISTINCT
REPORT.REPORTID, 'MSN13' AS MEASURE_NUMBER
, RTRIM(PatientDemo.LastName + ', ' + PatientDemo.FirstName + ' ' + case when PatientDemo.MiddleName is null or PatientDemo.MiddleName = '' then '' else PatientDemo.Middlename end) AS PATIENT_NAME
, PATIENT.MRN
, [ORDER].FillerOrderNumber AS ACCESSION
,  CONVERT(VARCHAR(12), [ORDER].STARTDATE, 101) as APPOINTMENTDATE
, [ORDER].PROCEDURECODELIST AS MCODE
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, report.contenttext
INTO MIPS.DBO.MSN_13_2024
FROM COMM4_HHC.DBO.Report
INNER JOIN COMM4_HHC.DBO.[Order] ON Report.ReportID = [Order].ReportID
INNER JOIN COMM4_HHC.DBO.Visit ON [Order].VisitID = Visit.VisitID
INNER JOIN COMM4_HHC.DBO.Patient ON Visit.PatientID = Patient.PatientID
left outer JOIN COMM4_HHC.DBO.PersonalInfo PatientDemo on Patient.PersonalInfoID = PatientDemo.PersonalInfoID
left outer join COMM4_HHC.DBO.Account ON Report.DictatorAcctID = Account.AccountID
left outer JOIN COMM4_HHC.DBO.PersonalInfo pb on Account.PersonalInfoID = pb.PersonalInfoID
left outer JOIN COMM4_HHC.DBO.Account b on Report.SignerAcctID = b.AccountID
left outer JOIN COMM4_HHC.DBO.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID
INNER JOIN MIPS.DBO.HHC_CPT_PIVOT ON [ORDER].ProcedureCodeList = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID] AND MIPS.DBO.HHC_CPT_PIVOT.CPT IN ('75571')
LEFT OUTER JOIN (
	SELECT * FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'EXCLUDE' AND MEASURE = 'MSN13') AS RP_EXCLUDE ON ContentText LIKE CONCAT('%',RP_EXCLUDE.PHRASE,'%')
INNER JOIN (
	SELECT * FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'INCLUDE' AND MEASURE = 'MSN13') AS RP_INCLUDE ON ContentText LIKE CONCAT('%',RP_INCLUDE.PHRASE,'%')
WHERE [ORDER].SITEID = 8 and [order].explorerstatus IN ('FINAL', 'FINAL (A)')  
and ([ORDER].FILLERORDERNUMBER NOT LIKE '%PWH' AND [ORDER].FILLERORDERNUMBER NOT LIKE '%SMA' AND [ORDER].FILLERORDERNUMBER NOT LIKE '%SWC')
AND (REPORT.LastModifiedDate >= '1/1/2024' AND REPORT.LastModifiedDate < '1/1/2025')
AND RP_EXCLUDE.PHRASE_ID IS NULL
;


DROP TABLE MIPS.DBO.MSN_13_2024_FINAL;
SELECT distinct  
CONVERT(VARCHAR(10), APPOINTMENTDATE, 101) as EXAM_DATE_TIME
, '061614148' as PHYSICIAN_GROUP_TIN
, case when MSN_13_2024.READING_RADIOLOGIST = 'Adam Kaye' then '1881838118'
		when MSN_13_2024.READING_RADIOLOGIST = 'Betty Mathew' then '1093153314'  
		when MSN_13_2024.READING_RADIOLOGIST = 'Eran Rotem' then '1912294182'  
		when MSN_13_2024.READING_RADIOLOGIST = 'Joshua Sapire' then '1164452066'  
		when MSN_13_2024.READING_RADIOLOGIST = 'Kelly Harkins-Squitieri' then '1518915990'  
		when MSN_13_2024.READING_RADIOLOGIST = 'Kenneth Zinn' then '1609861285'
		when MSN_13_2024.READING_RADIOLOGIST = 'Noel Velasco' then '1922093590'
		when MSN_13_2024.READING_RADIOLOGIST = 'Scott Smith' then '1952496424'
		when MSN_13_2024.READING_RADIOLOGIST = 'Terence Hughes' then '1053307421'
		else ProviderDim.npi end AS PHYSICIAN_NPI
, MSN_13_2024.READING_RADIOLOGIST
, PATIENT.MRN AS PATIENT_ID
, CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,mips.dbo.MSN_13_2024.appointmentdate)/8766.0,0)) as PATIENT_AGE
, PATIENT.SEX AS PATIENT_GENDER,
CASE WHEN CoverageDim.PayorFinancialClass IN ('MEDICARE', 'MEDICAREMC') THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_BENEFICIARY
 , MAX(CASE WHEN (CoverageDim.PayorFinancialClass IN ('MEDICARE', 'MEDICAREMC') and CoverageDim.BenefitPlanName NOT IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD',
'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE',
'AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS')) or (CoverageDim.PayorFinancialClass IN ('MEDICARE', 'MEDICAREMC') and CoverageDim.BenefitPlanName IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD',
'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE',
'AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS') AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,mips.dbo.MSN_13_2024.appointmentdate)/8766.0,0))  >= 65) THEN 'Y' ELSE 'N' END) AS PATIENT_MEDICARE_ADVANTAGE
, 'MSN13' AS MEASURE_NUMBER
, MSN_13_2024.APPOINTMENTREASON
, MIPS.DBO.HHC_CPT_PIVOT.CPT AS CPT_CODE
, 'EE013' as DENOMINATOR_DIAGNOSIS_CODE
, CASE WHEN ((
concat(report.contenttext, addend.ContentText) LIKE '%Calcium Score%' or concat(report.contenttext, addend.ContentText) like '%CACS%') -- This is redundent because MSN_13_2024 filters for reports with these 2 phrases
and (concat(report.contenttext, addend.ContentText) like '%Left Main%' or concat(report.contenttext, addend.ContentText) like '%LM:%') 
and concat(report.contenttext, addend.ContentText) like '%LAD:%' and concat(report.contenttext, addend.ContentText) like '%LCx:%' 
and concat(report.contenttext, addend.ContentText) like '%RCA:%' and concat(report.contenttext, addend.ContentText) like '%PDA:%') THEN 'PM001' ELSE 'PNM01' END AS NUMERATOR_RESPONSE_VALUE
, '' AS MEASURE_EXTENSION_NUM
, '' AS EXTENSION_RESPONSE_VALUE
, [ORDER].FILLERORDERNUMBER AS EXAM_UNIQUE_ID
, MSN_13_2024.MCODE
INTO MIPS.DBO.MSN_13_2024_FINAL
FROM MIPS.DBO.MSN_13_2024
inner join comm4_HHC.dbo.report on MSN_13_2024.ReportID = report.reportid
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
left outer join MIPS.DBO.HHC_CPT_PIVOT ON MIPS.DBO.MSN_13_2024.MCODE = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID] AND MIPS.DBO.HHC_CPT_PIVOT.CPT in ('75571')
left outer join Comm4_hhc.dbo.reportaddendum on report.reportid = reportaddendum.OriginalReportID
left outer join Comm4_hhc.dbo.report addend on addend.reportid = reportaddendum.AddendumReportID
where [ORDER].SITEID = 8 and departmentdim.departmentcenter = 'Advanced Radiology Partners'
GROUP BY APPOINTMENTDATE,  MSN_13_2024.READING_RADIOLOGIST,  ProviderDim.npi,
MSN_13_2024.Reading_Radiologist, PATIENT.MRN, patient.dob, mips.dbo.MSN_13_2024.appointmentdate, 
PATIENT.SEX , CoverageDim.PayorFinancialClass, MSN_13_2024.APPOINTMENTREASON, addend.ContentText,
HHC_CPT_PIVOT.CPT, [ORDER].FILLERORDERNUMBER, report.contenttext, MSN_13_2024.MCODE
;