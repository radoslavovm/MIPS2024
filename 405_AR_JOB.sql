
DROP TABLE IF EXISTS MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE;
DROP TABLE IF EXISTS MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_2024_FINAL;

WITH PT1_405_CTE (REPORTID
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
R.REPORTID
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
, R.ContentText as REPORTCONTENT
FROM (
SELECT DISTINCT ReportID, ContentText, DictatorAcctID, SignerAcctID
FROM COMM4_HHC.DBO.Report 
-- filter out any reports that have a phrase that should be excluded from the denominator 
WHERE NOT EXISTS (select top 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE DENOMINATOR = 'EXCLUDE' AND MEASURE = '405'
	and ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%'))
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
										AND MIPS.DBO.HHC_CPT_PIVOT.CPT IN ('71250','71260','71270','71271','71275','71555','72131','72191','72192','72193','72194','72195','72196','72197','72198','74150','74160','74170','74176','74177','74178','74181','74182','74183')
WHERE [ORDER].SITEID IN (8)  
AND [ORDER].LastModifiedDate >= '01/01/2024'
AND (ContentText LIKE '%RENAL%' 
	OR ContentText LIKE '%KIDNEY%')
AND CONVERT(int,ROUND(DATEDIFF(hour,PATIENT.dob,CONVERT(VARCHAR(10), CONVERT(VARCHAR(12), [ORDER].STARTDATE, 101), 101))/8766.0,0)) >= 18
)

SELECT F.*
, CASE 
	WHEN (ABDOMINAL like '%too small to characterize%' -- NOTE: WHEN A VALUE IS PASSED THROUGH THIS CASE IT IS MARKED WITH THE FIRST CONDITION THAT IS TRUE, THAT MEANS TO BE MARKED EXCLUDE THE REST OF THE STATEMENTS ARE FALSE
	OR ABDOMINAL like '%too small to reliably characterize%'
	OR ABDOMINAL LIKE '%SUBCENTIMETER%'
	OR ABDOMINAL LIKE '%Accuracy may be limited in such a small lesion%'
	OR ((ADRENAL LIKE '%UNREMARKABLE%' OR ADRENAL LIKE '%No suspicious mass%') 
			AND (KIDNEY LIKE '%No suspicious renal mass%'
			OR KIDNEY LIKE '%No suspicious SOLID mass%'
			OR KIDNEY LIKE '%No SOLID RENAL mass%'
			OR KIDNEY LIKE '%No suspicious mass%'
			OR KIDNEY LIKE '%No nephrolithiasis%'
			OR KIDNEY LIKE '%no hydronephrosis%'
			OR KIDNEY LIKE '%UNREMARKABLE%'
			OR KIDNEY LIKE '%Accuracy may be limited in such a small lesion%'
			OR KIDNEY LIKE '%incompletely characterized without IV contrast%'
			OR KIDNEY LIKE '%difficult to characterize%'))
	) THEN 'EXCLUDE'
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
	
	ELSE 'OTHER' END AS CATEGORY
INTO MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE
FROM PT1_405_CTE AS F
INNER JOIN comm4_hhc.dbo.[order] on F.reportid = [order].reportid
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

SELECT DISTINCT 
CONVERT(VARCHAR(10), APPOINTMENTDATE, 101) as EXAM_DATE_TIME
, '061216029' as PHYSICIAN_GROUP_TIN
, [PROVIDERDIM].npi AS PHYSICIAN_NPI
, MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE.READING_RADIOLOGIST
, PATIENT.MRN AS PATIENT_ID
, CONVERT(int,ROUND(DATEDIFF(hour,PATIENT.dob,CONVERT(VARCHAR(10), APPOINTMENTDATE, 101))/8766.0,0)) as PATIENT_AGE
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
	AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE.APPOINTMENTDATE)/8766.0,0))  >= 65) THEN 'Y' ELSE 'N' END 
	AS PATIENT_MEDICARE_ADVANTAGE
, '405' AS MEASURE_NUMBER
, MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE.APPOINTMENTREASON
, MIPS.DBO.HHC_CPT_PIVOT.CPT + ' & G9547' AS CPT_CODE
, '' as DENOMINATOR_DIAGNOSIS_CODE
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
INTO MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_2024_FINAL
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

UPDATE MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_2024_FINAL
SET NUMERATOR_RESPONSE_VALUE = 'G9548'
WHERE  NUMERATOR_RESPONSE_VALUE = 'G9550'
AND left(MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_2024_FINAL.EXAM_UNIQUE_ID, 2) in ('AR')
AND EXAM_UNIQUE_ID IN  
	(SELECT DISTINCT INCIDENTAL_ABDOMINAL_LESIONS_405_2024_FINAL.EXAM_UNIQUE_ID
		FROM MIPS.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_2024_FINAL
		Inner join comm4_hhc.dbo.[order] 
			ON [order].FillerOrderNumber = INCIDENTAL_ABDOMINAL_LESIONS_405_2024_FINAL.EXAM_UNIQUE_ID
		INNER JOIN COMM4_HHC.DBO.Report 
			ON [order].ReportID = Report.ReportID
		INNER JOIN comm4_HHC.dbo.reportaddendum 
			ON report.reportid = reportaddendum.OriginalReportID
		INNER JOIN comm4_HHC.dbo.report AS addend 
			ON addend.reportid = ReportAddendum.AddendumReportID
		WHERE EXISTS (
			SELECT *
			FROM ARC_DW.DBO.REPORT_PHRASES
			WHERE CRITERIA = 'Y' AND MEASURE = '405'
			AND addend.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
				)
			)
;

