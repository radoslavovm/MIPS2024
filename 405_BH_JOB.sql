--USE COMM4_HHC;
DROP TABLE IF EXISTS MIPS_BRA.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_2024
DROP TABLE IF EXISTS MIPS_BRA.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE_BH;

WITH BH_405_CTE ([Patient Name]
, [Visit Type]
, [Exam Name]
, [Reason For Exam]
, [Exam Date]
, [Referring Physician]
, NPI
, [Rad]
, [Report Sign Date]
, [Exam Location]
, [ACCESSION]
, [MRN]
, BirthDate
, SEX
, INSURANCE
-- REPORTS 
, ADRENAL  
, KIDNEY
, ABDOMINAL
, REPORT
--
, CPT
)
AS (
SELECT DISTINCT 
BH_ExamDetails.[Patient Name]
, BH_ExamDetails.[Visit Type]
, BH_ExamDetails.[Exam Name]
, BH_ExamDetails.[Reason For Exam]
, BH_ExamDetails.[Exam Date]
, BH_ExamDetails.[Referring Physician]
, BH_Powerscribe2.NPI
, BH_ExamDetails.[Rad]
, BH_ExamDetails.[Report Sign Date]
, BH_ExamDetails.[Exam Location]
, BH_ExamDetails.[ACCESSION]
, BH_ExamDetails.[MRN]
, BH_ExamDetails.BirthDate
, BH_Powerscribe2.SEX
, BRIDGEPORT_BPI.[Custom Payor Name (Original)] AS INSURANCE
, ARC_DW.dbo.Pull_HeadersV2 (CONCAT(ReportA, ReportB), 'ADRENAL GLANDS:', '@') AS ADRENAL  
, ARC_DW.dbo.Pull_HeadersV2 (CONCAT(ReportA, ReportB), 'KidneyS:', '@') AS KIDNEY
, CONCAT(ARC_DW.dbo.Pull_HeadersV2 (CONCAT(ReportA, ReportB), 'ADRENAL GLANDS:', '@')  
, ARC_DW.dbo.Pull_HeadersV2 (CONCAT(ReportA, ReportB), 'KidneyS:', '@')) AS ABDOMINAL
, CONCAT(ReportA, ReportB) AS REPORT
, BRIDGEPORT_COMPENDIUM.CPT
from ARC_DW.dbo.BH_ExamDetails
inner join ARC_DW.dbo.BH_Reports on BH_ExamDetails.Accession = BH_Reports.Accession
left outer join ARC_DW.dbo.Bridgeport_Compendium on BH_ExamDetails.[Exam Name] = Bridgeport_Compendium.[Exam Name]
LEFT OUTER JOIN MPF.DBO.BH_POWERSCRIBE2 ON BH_EXAMDETAILS.ACCESSION = BH_POWERSCRIBE2.FILLERORDERNUMBER
LEFT OUTER JOIN MPF.DBO.BRIDGEPORT_BPI ON BH_EXAMDETAILS.ACCESSION = BRIDGEPORT_BPI.[Original Record Number]
WHERE Year(BH_ExamDetails.[Report Sign Date]) = '2024' 
AND Bridgeport_Compendium.cpt in ('71250', '71260', '71270', '71271', '71275', '71555', '72131', '72191', '72192', '72193', '72194', '72195', '72196', '72197', '72198', '74150', '74160', '74170', '74176', '74177', '74178', '74181', '74182', '74183')  
AND CONVERT(int,ROUND(DATEDIFF(hour,BirthDate,CONVERT(VARCHAR(12), CAST([EXAM DATE] AS DATE), 101)) /8766.0,0)) >= 18
AND (CONCAT(ReportA, ReportB) LIKE '%RENAL%' 
	OR CONCAT(ReportA, ReportB) LIKE '%KIDNEY%')
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
INTO MIPS_BRA.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE_BH
FROM BH_405_CTE AS F
INNER JOIN (
SELECT  DISTINCT ACCESSION
FROM BH_405_CTE
-- filter out any reports that have a phrase that should be excluded from the denominator 
WHERE NOT EXISTS (select top 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'EXCLUDE' AND MEASURE = '405'
	and BH_405_CTE.REPORT LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%'))
) AS R 
ON R.ACCESSION = f.ACCESSION
WHERE (ABDOMINAL NOT like '%complex appearing%'
	AND ABDOMINAL NOT like '%complex CYST%'
	AND ABDOMINAL NOT like '%Bosniak[3-4]%'
	AND ABDOMINAL NOT like '%Bosniak [3-4]%'
	AND REPLACE(ABDOMINAL, ' ', '') NOT LIKE '%[A-Z][4-9]CM%'
	AND REPLACE(ABDOMINAL, ' ', '') NOT LIKE '%[1-9][0-9]CM%'
	AND REPLACE(ABDOMINAL, ' ', '') NOT LIKE '%[4-9].[0-9]CM%'
)

SELECT DISTINCT 
CONVERT(VARCHAR(12), CAST([EXAM DATE] AS DATE), 101) AS APPOINTMENTDATE
, '061613357' as TIN
, NPI
, RAD AS READING_RADIOLOGIST
, MRN
, [Patient Name] AS PATIENT_NAME
 , CONVERT(int,ROUND(DATEDIFF(hour,BirthDate,CONVERT(VARCHAR(12), CAST([EXAM DATE] AS DATE), 101)) /8766.0,0)) as PATIENT_AGE
, SEX
, CASE WHEN INSURANCE LIKE '%MEDICARE%' THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_BENEFICIARY
 , CASE WHEN (INSURANCE  LIKE '%MEDICARE%' 
	and (INSURANCE NOT LIKE '%HARVARD PILGRIM%' OR INSURANCE NOT LIKE '%HARVARD PILGRIM UNITED%' OR INSURANCE NOT LIKE '%HUMANA%' OR INSURANCE NOT LIKE '%HUMANA - GENERIC%' OR INSURANCE NOT LIKE '%HUMANA MEDICARE GENERIC5' OR INSURANCE NOT LIKE '%HUMANA MGD MEDICARE%' OR INSURANCE NOT LIKE '%HUMANA - LEXINGTON%' OR INSURANCE NOT LIKE '%OXFORD HEALTH PLAN%'
		OR INSURANCE NOT LIKE '%EMPIRE BLUECROSS BLUESHIELD%' OR INSURANCE NOT LIKE '%HORIZON BCBSNJ%' OR INSURANCE NOT LIKE '%ANTHEM EMPIRE BCBS%' OR INSURANCE NOT LIKE '%ANTHEM FEP BCBS CT%' OR INSURANCE NOT LIKE '%ANTHEM NATIONAL BCBS CT%' OR INSURANCE NOT LIKE '%CIGNA ALL%' OR INSURANCE NOT LIKE '%CIGNA - GENERIC%' OR INSURANCE NOT LIKE '%CIGNA BEHAVIORAL HEALTH%'OR INSURANCE NOT LIKE '%CIGNA GENERIC%'
		OR INSURANCE NOT LIKE '%CIGNA HMO%' OR INSURANCE NOT LIKE '%CIGNA MGD MEDICARE%' OR INSURANCE NOT LIKE '%CIGNA OSCAR%' OR INSURANCE NOT LIKE '%CIGNA PPO%' OR INSURANCE NOT LIKE '%OXFORD HEALTH PLANS%' OR INSURANCE NOT LIKE '%AETNA - HMO-MEDICARE AND ALL OTHERS%' OR INSURANCE NOT LIKE '%AETNA HMO%' OR INSURANCE NOT LIKE '%AETNA HMO/POS%' OR INSURANCE NOT LIKE '%AETNA ADVANTAGE PLANS OFF EXCHANGE%'
		OR INSURANCE NOT LIKE '%AETNA MEDICARE ADVANTAGE%' OR INSURANCE NOT LIKE '%AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS%')  
	AND CONVERT(int,ROUND(DATEDIFF(hour,BirthDate,CONVERT(VARCHAR(12), CAST([EXAM DATE] AS DATE), 101)) /8766.0,0))  >= 65) THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_ADVANTAGE
,'405' as MEASURE_NUMBER
, [Exam Name] AS APPOINTMENTREASON
, CPT + ' & G9547' as CPT_CODE
, '' as DENOMINATOR_DIAGNOSIS_CODE
, INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE_BH.ACCESSION
, LEFT([EXAM NAME], 2) AS MODALITY
, CASE 
	WHEN ( R.performance_met IS NOT NULL)
		THEN 'G9548'  -- PERFORMANCE MET 
	WHEN (R.measure_exception IS NOT NULL
	OR CATEGORY = 'MID')
		THEN 'G9549' -- EXCLUDE
	ELSE 'G9550' END  AS NUMERATOR_RESPONSE_VALUE -- PNM
, '' AS MEASURE_EXTENSION_NUM
, '' AS EXTENSION_RESPONSE_VALUE 
INTO MIPS_BRA.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_2024
FROM MIPS_BRA.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE_BH
INNER JOIN (
SELECT  DISTINCT ACCESSION,
-- Does the report have at least one of the phrases in it. if so, pass_measure will return the first phrase found
(SELECT TOP 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'PE' AND MEASURE = '405'
	and REPORT LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
) measure_exception,
(SELECT TOP 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'Y' AND MEASURE = '405'
	and ABDOMINAL LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
) performance_met
FROM MIPS_BRA.DBO.INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE_BH
) AS R 
ON R.ACCESSION = INCIDENTAL_ABDOMINAL_LESIONS_405_CATEGORIZE_BH.ACCESSION

WHERE Year([Report Sign Date]) = '2024' 
AND CPT in ('71250', '71260', '71270', '71271', '71275', '71555', '72131', '72191', '72192', '72193', '72194', '72195', '72196', '72197', '72198', '74150', '74160', '74170', '74176', '74177', '74178', '74181', '74182', '74183')  
AND CONVERT(int,ROUND(DATEDIFF(hour,BirthDate,CONVERT(VARCHAR(12), CAST([EXAM DATE] AS DATE), 101)) /8766.0,0)) >= 18
AND CATEGORY NOT LIKE 'EXCLUDE' 
AND CATEGORY NOT LIKE 'OTHER'
;