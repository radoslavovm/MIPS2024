-- 3.5 MIN RUNTIME 5/16/2024
USE COMM4_HHC;

--TRUNCATE TABLE MIPS_BRA.DBO.CAT_436_2024;

INSERT INTO MIPS_BRA.DBO.CAT_436_2024([APPOINTMENTDATE],[TIN],[NPI],[READING_RADIOLOGIST],[MRN],[PATIENT_NAME],
[PATIENT_AGE],[SEX],[PATIENT_MEDICARE_BENEFICIARY],[PATIENT_MEDICARE_ADVANTAGE],[MEASURE_NUMBER],[APPOINTMENTREASON],[CPT_CODE],[DENOMINATOR_DIAGNOSIS_CODE],
[ACCESSION],[MODALITY],[NUMERATOR_RESPONSE_VALUE],[MEASURE_EXTENSION_NUM],[EXTENSION_RESPONSE_VALUE])

SELECT DISTINCT 
 CONVERT(VARCHAR(12), [ORDER].STARTDATE, 101) as APPOINTMENTDATE
, '061613357' as TIN
, [PROVIDERDIM].npi AS NPI
,PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, PATIENT.MRN
, RTRIM(PatientDemo.LastName + ', ' + PatientDemo.FirstName + ' ' + case when PatientDemo.MiddleName is null or PatientDemo.MiddleName = '' then '' else PatientDemo.Middlename end) AS PATIENT_NAME
, CONVERT(int,ROUND(DATEDIFF(hour,PATIENT.dob,CONVERT(VARCHAR(10), [ORDER].STARTDATE, 101))/8766.0,0)) as PATIENT_AGE
, PATIENT.SEX
, CASE WHEN CoverageDim.PayorFinancialClass IN ('MEDICARE', 'MEDICAREMC') THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_BENEFICIARY

, CASE WHEN (CoverageDim.PayorFinancialClass  IN ('Managed Medicare', 'Medicare') 
            and CoverageDim.benefitplanname NOT IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE',
                'HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD','HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT',
                'CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS',
                'AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE','AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS')) 
            or (CoverageDim.payorfinancialclass IN ('MEDICARE', 'MEDICAREMC') 
            and CoverageDim.benefitplanname IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE',
                'HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD','HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT',
                'CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS',
                'AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE','AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS') 
        AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,[ORDER].STARTDATE)/8766.0,0))  >= 65) THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_ADVANTAGE

, '436' AS MEASURE_NUMBER
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, MIPS.DBO.HHC_CPT_PIVOT.CPT + ' & G9547' AS CPT_CODE
, '' as DENOMINATOR_DIAGNOSIS_CODE
, [ORDER].FILLERORDERNUMBER AS ACCESSION
, '' AS MODALITY
, CASE WHEN (performance_met IS NOT NULL) THEN 'G9637' ELSE 'G9638' END AS NUMERATOR_RESPONSE_VALUE
, '' AS MEASURE_EXTENSION_NUM
, '' AS EXTENSION_RESPONSE_VALUE
FROM (
-- PULL ONLY THE REPORTS THAT ARE WITHIN DATE RANGE, AND MARK COMPLIANCE USING REPORT PHRASES QUERY  
SELECT DISTINCT ReportID, Report.SignerAcctID, report.lastmodifieddate,
(SELECT TOP 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'Y' AND MEASURE = '436'
	and Report.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
) performance_met
FROM COMM4_HHC.DBO.Report
WHERE Report.lastmodifieddate >= '01/01/2024' 
) AS R 
INNER JOIN comm4_hhc.dbo.[order] on R.reportid = [order].reportid AND [ORDER].SITEID = 7 
INNER JOIN comm4_hhc.dbo.visit on [order].visitid = visit.visitid
INNER JOIN comm4_hhc.dbo.patient on patient.patientid = visit.patientid
INNER JOIN COMM4_HHC.DBO.PersonalInfo PatientDemo on Patient.PersonalInfoID = PatientDemo.PersonalInfoID 
INNER JOIN COMM4_HHC.DBO.Account b on R.SignerAcctID = b.AccountID  
INNER JOIN COMM4_HHC.DBO.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID 
INNER JOIN Epic_SVMC.dbo.ImagingFact on [order].fillerordernumber = ImagingFact.img_accession_num
INNER JOIN Caboodle.dbo.[providerdim] on ImagingFact.IMG_FINALIZING_PROV_ID= [providerdim].providerkey and [providerdim].npi <> '*Unspecified' 
INNER JOIN Epic_SVMC.dbo.EncounterFact  on ImagingFact.IMG_PERF_ENC_KEY = EncounterFact.EncounterKey
-- SEEMS TO BE A LARGE AMOUNT OF DUPLICATES HERE, SO JOINING ON SELECT OF ONLY THE DISTINCT NECESSARY FIELDS
INNER JOIN (select distinct PayorFinancialClass, BenefitPlanName, CoverageKey 
			from Epic_SVMC.dbo.CoverageDim) as CoverageDim  
				on EncounterFact.PrimaryCoverageKey = CoverageDim.CoverageKey
INNER JOIN Caboodle.dbo.DepartmentDim on ImagingFact.IMG_PERFORMING_DEPT_KEY = DepartmentDim.DepartmentKey
INNER JOIN MIPS.DBO.HHC_CPT_PIVOT ON [ORDER].ProcedureCodeList = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID]
						 AND MIPS.DBO.HHC_CPT_PIVOT.CPT  IN (
						   '70450', '70460', '70470', '70480', '70481', '70482', '70486', '70487', '70488', '70490', '70491', '70492', '70496', '70498', '71250', '71260', '71270', '71271'
						 , '71275', '72125', '72126', '72127', '72128', '72129', '72130', '72131', '72132', '72133', '72191', '72192', '72193', '72194', '73200', '73201', '73202', '73206', '73700', '73701'
						 , '73702', '73706', '74150', '74160', '74170', '74174', '74175', '74176', '74177', '74178', '74261', '74262', '74263', '75571', '75572', '75573', '75574', '75635', '76380', '76497'
						 , '77011', '77012', '77013', '77014', '77078', '0042T', 'G0297')
WHERE [ORDER].SITEID = 7  
AND LEFT([ORDER].FILLERORDERNUMBER, 2) in ('SV') 
AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,[ORDER].STARTDATE)/8766.0,0))>= 18;


-- SEARCH FOR ADDENDUMS THAT WILL MAKE THE NONCOMPLIANT REPORTS COMPLIANT
UPDATE MIPS_BRA.DBO.CAT_436_2024
SET NUMERATOR_RESPONSE_VALUE = 'G9637'
WHERE  NUMERATOR_RESPONSE_VALUE = 'G9638'
AND ACCESSION IN 
	(SELECT DISTINCT ACCESSION
		FROM MIPS_BRA.DBO.CAT_436_2024
		Inner join comm4_hhc.dbo.[order] 
			ON [order].FillerOrderNumber = CAT_436_2024.ACCESSION
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