-- Deprecate, or Archive for future use. 

USE COMM4_HHC;
DROP TABLE IF EXISTS MIPS_BRA.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE_SV;

WITH SV_405_CTE (REPORTID
, MEASURE_NUMBER
, PATIENT_NAME
, MRN 
, ACCESSION
, APPOINTMENTDATE
, MCODE
, MODALITY
, APPOINTMENTREASON
, Reading_Radiologist
, ADRENAL  
, KIDNEY
, ABDOMINAL
, REPORTCONTENT
)
AS (
SELECT DISTINCT 
REPORT.REPORTID
, '405' AS MEASURE_NUMBER
, RTRIM(PatientDemo.LastName + ', ' + PatientDemo.FirstName + ' ' + case when PatientDemo.MiddleName is null or PatientDemo.MiddleName = '' then '' else PatientDemo.Middlename end) AS PATIENT_NAME
, PATIENT.MRN 
, [ORDER].FillerOrderNumber AS ACCESSION
, CONVERT(VARCHAR(12), [ORDER].STARTDATE, 101) as APPOINTMENTDATE
, [ORDER].PROCEDURECODELIST AS MCODE
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, ARC_DW.dbo.Pull_HeadersV2 (contenttext, 'AdrenalS:', DEFAULT) AS ADRENAL  
, ARC_DW.dbo.Pull_HeadersV2 (contenttext, 'KidneyS:', DEFAULT) AS KIDNEY
, CONCAT(ARC_DW.dbo.Pull_HeadersV2 (contenttext, 'AdrenalS:', DEFAULT)  
, ARC_DW.dbo.Pull_HeadersV2 (contenttext, 'KidneyS:', DEFAULT)) AS ABDOMINAL
, report.contenttext as REPORTCONTENT
FROM COMM4_HHC.DBO.Report
Inner join comm4_hhc.dbo.[order] on report.reportid = [order].reportid
inner join comm4_hhc.dbo.visit on [order].visitid = visit.visitid
inner join comm4_hhc.dbo.patient on patient.patientid = visit.patientid
left outer JOIN COMM4_HHC.DBO.PersonalInfo PatientDemo on Patient.PersonalInfoID = PatientDemo.PersonalInfoID 
left outer JOIN COMM4_HHC.DBO.Account b on Report.SignerAcctID = b.AccountID 
left outer JOIN COMM4_HHC.DBO.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID 
left outer join Epic_SVMC.dbo.ImagingFact on [order].fillerordernumber = ImagingFact.img_accession_num
left outer join Caboodle.dbo.[providerdim] on ImagingFact.IMG_FINALIZING_PROV_ID= [providerdim].providerkey and [providerdim].npi <> '*Unspecified' 
left outer join Epic_SVMC.dbo.EncounterFact  on ImagingFact.IMG_PERF_ENC_KEY = EncounterFact.EncounterKey
left outer join Epic_SVMC.dbo.CoverageDim on EncounterFact.PrimaryCoverageKey = CoverageDim.CoverageKey
left outer join Caboodle.dbo.DepartmentDim on ImagingFact.IMG_PERFORMING_DEPT_KEY = DepartmentDim.DepartmentKey
inner JOIN MIPS.DBO.HHC_CPT_PIVOT ON [ORDER].ProcedureCodeList = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID]
						 AND MIPS.DBO.HHC_CPT_PIVOT.CPT in (
'71250','71260','71270','71271','71275','71555','72131','72191','72192','72193','72194','72195','72196','72197','72198','74150','74160','74170','74176','74177','74178','74181','74182','74183')
WHERE [ORDER].SITEID = 7   
AND REPORT.LastModifiedDate >= '01/01/2024'
and LEFT([ORDER].PROCEDUREDESCLIST, 2) = 'MR' 
and left([imagingfact].IMG_ACCESSION_NUM, 2) in ('SV') 
AND CONVERT(int,ROUND(DATEDIFF(hour,PATIENT.dob,CONVERT(VARCHAR(10), [ORDER].STARTDATE, 101))/8766.0,0)) >= 18
AND (ContentText LIKE '%RENAL%' 
	OR ContentText LIKE '%KIDNEY%')
)

SELECT F.*
, CASE 
	WHEN (
	KIDNEY like '%Bosniak%'
	OR KIDNEY like '%simple appear%'
	OR KIDNEY like '%BENIGN SIMPLE CYST%'
	OR KIDNEY like '%BENIGN CYST%'
	OR KIDNEY like '%SIMPLE CYST%'
	OR KIDNEY LIKE '%adenoma%'
	OR KIDNEY LIKE '%angiomyolipoma%'
	OR KIDNEY LIKE '%representing a splenule%'
	) THEN 'BENIGN'
	WHEN (
	(REPLACE(ADRENAL, ' ', '') LIKE '%[1-3].[0-9]CM%'
	OR REPLACE(ADRENAL, ' ', '') LIKE '%[A-Z][1-3]CM%'
	OR REPLACE(ADRENAL, ' ', '') LIKE '%[A-Z][. :][1-3]CM%'
	OR REPLACE(ADRENAL, ' ', '') LIKE '%[1-9][0-9]MM%')
	) THEN 'MID'
	WHEN (
	REPLACE(ADRENAL, ' ', '') LIKE '%[A-Z . : ( -][1-9]MM%'
	OR REPLACE(ADRENAL, ' ', '') LIKE '%0.[1-9]CM%'
	OR REPLACE(ADRENAL, ' ', '') LIKE '%1CM%'
	) THEN 'SMALL'
	WHEN (ABDOMINAL like '%too small to characterize%' -- NOTE: WHEN A VALUE IS PASSED THROUGH THIS CASE IT IS MARKED WITH THE FIRST CONDITION THAT IS TRUE, THAT MEANS TO BE MARKED EXCLUDE THE REST OF THE STATEMENTS ARE FALSE
	OR ABDOMINAL like '%too small to reliably characterize%'
	OR ABDOMINAL LIKE '%SUBCENTIMETER%'
	OR ((ADRENAL LIKE '%UNREMARKABLE%' OR ADRENAL LIKE '%No suspicious mass%') 
			AND (KIDNEY LIKE '%No suspicious renal mass%'
			OR KIDNEY LIKE '%No suspicious SOLID mass%'
			OR KIDNEY LIKE '%No SOLID RENAL mass%'
			OR KIDNEY LIKE '%No suspicious mass%'
			OR KIDNEY LIKE '%No nephrolithiasis%'
			OR KIDNEY LIKE '%no hydronephrosis%'
			OR KIDNEY LIKE '%UNREMARKABLE%'
			OR KIDNEY LIKE '%NO FOCAL MASS%'))
	) THEN 'EXCLUDE'
	ELSE 'OTHER' END AS CATEGORY
--INTO MIPS_BRA.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE_SV
FROM SV_405_CTE AS F
INNER JOIN (
SELECT  DISTINCT ReportID
FROM SV_405_CTE
-- filter out any reports that have a phrase that should be excluded from the denominator 
WHERE NOT EXISTS (select top 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'EXCLUDE' AND MEASURE = '405'
	and SV_405_CTE.REPORTCONTENT LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%'))
) AS R 
ON R.ReportID = f.ReportID
INNER JOIN comm4_hhc.dbo.[order] on R.reportid = [order].reportid
INNER JOIN comm4_hhc.dbo.visit on [order].visitid = visit.visitid
INNER JOIN comm4_hhc.dbo.patient on patient.patientid = visit.patientid

WHERE F.MODALITY = 'MR'
AND (ABDOMINAL NOT like '%complex appearing%'
	AND ABDOMINAL NOT like '%complex CYST%'
	AND ABDOMINAL NOT like '%Bosniak[3-4]%'
	AND ABDOMINAL NOT like '%Bosniak [3-4]%'
	AND REPLACE(ABDOMINAL, ' ', '') NOT LIKE '%[A-Z][4-9]CM%'
	AND REPLACE(ABDOMINAL, ' ', '') NOT LIKE '%[1-9][0-9]CM%'
	AND REPLACE(ABDOMINAL, ' ', '') NOT LIKE '%[4-9].[0-9]CM%'
)

INSERT INTO MIPS_BRA.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_2024([APPOINTMENTDATE],[TIN],[NPI],[READING_RADIOLOGIST],[MRN],[PATIENT_NAME],
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
		and CoverageDim.benefitplanname NOT IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD',
			'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS',
			'AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE', 'AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS')) 
	or (CoverageDim.payorfinancialclass IN ('MEDICARE', 'MEDICAREMC') 
		and CoverageDim.benefitplanname IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD',
			'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE',
			'AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS')  
	AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,[ORDER].STARTDATE)/8766.0,0))  >= 65) THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_ADVANTAGE
, '405' AS MEASURE_NUMBER
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, MIPS.DBO.HHC_CPT_PIVOT.CPT + ' & G9547' AS CPT_CODE
, '' as DENOMINATOR_DIAGNOSIS_CODE
, [ORDER].FILLERORDERNUMBER AS ACCESSION
, 'MR' AS MODALITY
, CASE 
	WHEN ( R.performance_met IS NOT NULL)
		THEN 'G9548'  -- PERFORMANCE MET 
	WHEN (R.measure_exception IS NOT NULL
	OR CATEGORY = 'MID')
		THEN 'G9549' -- EXCLUDE
	ELSE 'G9550' END  AS NUMERATOR_RESPONSE_VALUE -- PNM
, '' AS MEASURE_EXTENSION_NUM
, '' AS EXTENSION_RESPONSE_VALUE
, [ORDER].FILLERORDERNUMBER AS EXAM_UNIQUE_ID
, MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE.MODALITY
, MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE.MCODE  
FROM MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE
INNER JOIN (
SELECT  DISTINCT ReportID,
-- Does the report have at least one of the phrases in it. if so, pass_measure will return the first phrase found
(SELECT TOP 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'PE' AND MEASURE = '405'
	and REPORTCONTENT LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
) measure_exception,
(SELECT TOP 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'Y' AND MEASURE = '405'
	and ABDOMINAL LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
) performance_met
FROM MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE
) AS R 
ON R.ReportID = INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE.ReportID
Inner join comm4_hhc.dbo.[order] on R.reportid = [order].reportid
inner join comm4_hhc.dbo.visit on [order].visitid = visit.visitid
inner join comm4_hhc.dbo.patient on patient.patientid = visit.patientid
inner join Caboodle.dbo.ImagingFact on [order].fillerordernumber = ImagingFact.AccessionNumber
inner join Caboodle.dbo.[providerdim] on ImagingFact.FinalizingProviderDurableKey = [providerdim].DurableKey and [providerdim].npi <> '*Unspecified' 
inner join Caboodle.dbo.EncounterFact  on ImagingFact.PerformingEncounterKey = EncounterFact.EncounterKey
inner join Caboodle.dbo.CoverageDim on EncounterFact.PrimaryCoverageKey = CoverageDim.CoverageKey
inner join Caboodle.dbo.DepartmentDim on ImagingFact.PerformingDepartmentKey = DepartmentDim.DepartmentKey
left outer join MIPS.DBO.HHC_CPT_PIVOT ON MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE.MCODE = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID]
						 AND MIPS.DBO.HHC_CPT_PIVOT.CPT in (
'71250','71260','71270','71271','71275','71555','72131','72191','72192','72193','72194','72195','72196','72197','72198','74150','74160','74170','74176','74177','74178','74181','74182','74183'
)
where CATEGORY NOT LIKE 'EXCLUDE' 
AND CATEGORY NOT LIKE 'OTHER'
;

