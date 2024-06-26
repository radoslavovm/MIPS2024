USE COMM4_HHC;
INSERT INTO MIPS_BRA.DBO.ACRAD36_CORONARYARTERY_2024([APPOINTMENTDATE],[TIN],[NPI],[READING_RADIOLOGIST],[MRN],[PATIENT_NAME],
[PATIENT_AGE],[SEX],[PATIENT_MEDICARE_BENEFICIARY],[PATIENT_MEDICARE_ADVANTAGE],[MEASURE_NUMBER],[APPOINTMENTREASON],[CPT_CODE],[DENOMINATOR_DIAGNOSIS_CODE],
[ACCESSION],[MODALITY],[NUMERATOR_RESPONSE_VALUE],[MEASURE_EXTENSION_NUM],[EXTENSION_RESPONSE_VALUE])

SELECT distinct 
convert(varchar(10), [order].startdate, 101)  as EXAM_DATE_TIME
, '061613357' as PHYSICIAN_GROUP_TIN
, ProviderDim.NPI AS PHYSICIAN_NPI
, PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, MRN AS PATIENT_ID
, pd.lastname + ', ' + pd.firstname AS PATIENT_NAME
, CONVERT(int,ROUND(DATEDIFF(hour,PATIENT.dob,CONVERT(VARCHAR(10), [ORDER].STARTDATE, 101))/8766.0,0)) as PATIENT_AGE
, PATIENT.SEX AS PATIENT_GENDER
, CASE WHEN CoverageDim.PayorFinancialClass IN ('MEDICARE', 'MEDICAREMC') THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_BENEFICIARY
, CASE WHEN (CoverageDim.PayorFinancialClass  IN ('Managed Medicare', 'Medicare') 
        and CoverageDim.benefitplanname NOT IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD',
            'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE',
            'AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS')) 
    or (CoverageDim.payorfinancialclass IN ('MEDICARE', 'MEDICAREMC') 
        and CoverageDim.benefitplanname IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD',
            'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE',
            'AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS') 
    AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,[ORDER].STARTDATE)/8766.0,0))  >= 65) THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_ADVANTAGE
, 'ACRAD36' AS MEASURE_NUMBER
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, P.CPT AS CPT_CODE
, '' as DENOMINATOR_DIAGNOSIS_CODE
, [ORDER].FILLERORDERNUMBER AS ACCESSION
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
-- one pass measure must be present for compliance. Refer to report_phrases table to see the phrases
, CASE WHEN R.pass_measure IS NOT NULL THEN 'Y' ELSE 'N' END AS NUMERATOR_RESPONSE_VALUE 
, '' AS MEASURE_EXTENSION_NUM
, '' AS EXTENSION_RESPONSE_VALUE
FROM (
SELECT  DISTINCT ReportID, DictatorAcctID, SignerAcctID, LastModifiedDate,
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
left outer join Epic_SVMC.dbo.ImagingFact on [order].fillerordernumber = ImagingFact.img_accession_num
left outer join Caboodle.dbo.[providerdim] on ImagingFact.IMG_FINALIZING_PROV_ID= [providerdim].providerkey and [providerdim].npi <> '*Unspecified' 
left outer join Caboodle.dbo.DepartmentDim on ImagingFact.IMG_PERFORMING_DEPT_KEY = DepartmentDim.DepartmentKey
left outer join Epic_SVMC.dbo.EncounterFact  on ImagingFact.IMG_PERF_ENC_KEY = EncounterFact.EncounterKey
left outer join Epic_SVMC.dbo.CoverageDim on EncounterFact.PrimaryCoverageKey = CoverageDim.CoverageKey
INNER join MIPS.dbo.HHC_CPT_PIVOT p ON P.[MPI: ID] =[ORDER].ProcedureCodeList 
WHERE [order].siteid = 7 and left([ORDER].FILLERORDERNUMBER, 2) in ('SV') AND P.CPT IN ('71250','71270') 
AND R.LastModifiedDate >='1/1/2024' 
AND ((CONVERT(int,ROUND(DATEDIFF(hour,PATIENT.dob,CONVERT(VARCHAR(10), [ORDER].STARTDATE, 101))/8766.0,0)) between 18 and 50 and PATIENT.SEX = 'M') 
OR (CONVERT(int,ROUND(DATEDIFF(hour,PATIENT.dob,CONVERT(VARCHAR(10), [ORDER].STARTDATE, 101))/8766.0,0)) between 18 and 65 and PATIENT.SEX = 'F'))
;

-- Addendum updates. this will not cover addendums that explain why report should be excluded
UPDATE MIPS_BRA.DBO.ACRAD36_CORONARYARTERY_2024
SET NUMERATOR_RESPONSE_VALUE = 'Y'
WHERE  NUMERATOR_RESPONSE_VALUE = 'N'
AND left(ACRAD36_CORONARYARTERY_2024.ACCESSION, 2) in ('SV')
AND ACCESSION IN 
	(SELECT DISTINCT ACRAD36_CORONARYARTERY_2024.ACCESSION
		FROM MIPS_BRA.DBO.ACRAD36_CORONARYARTERY_2024
		Inner join comm4_hhc.dbo.[order] 
			ON [order].FillerOrderNumber = ACRAD36_CORONARYARTERY_2024.ACCESSION
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

-- DELETE FROM TABLE IF THE ADDENDUM CLAIMS REPORT SHOULD BE EXEMPT. (ADD VALUES TO REPORT_PHRASES TABLE AS NEEDED)
DELETE FROM  MIPS.DBO.ACRAD36_CORONARYARTERY_FINAL_2024
WHERE EXAM_UNIQUE_ID IN 
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
			WHERE DENOMINATOR = 'EXCLUDE' AND MEASURE = 'ACRAD36'
			AND addend.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
				)
			)
;
