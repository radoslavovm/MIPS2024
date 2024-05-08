DROP TABLE IF EXISTS MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024;
SELECT DISTINCT   
REPORT.REPORTID
, '406' AS MEASURE_NUMBER
, RTRIM(PatientDemo.LastName + ', ' + PatientDemo.FirstName + ' ' + case when PatientDemo.MiddleName is null or PatientDemo.MiddleName = '' then '' else PatientDemo.Middlename end) AS PATIENT_NAME
, PATIENT.MRN 
, [ORDER].FillerOrderNumber AS ACCESSION
,  CONVERT(VARCHAR(12), [ORDER].STARTDATE, 101) as APPOINTMENTDATE
, [ORDER].PROCEDURECODELIST AS MCODE
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, HHC_CPT_PIVOT.CPT
, CONCAT(
[ARC_DW].dbo.Pull_HeadersV2 (ContentText, 'Soft Tissues:', DEFAULT) 
, [ARC_DW].dbo.Pull_HeadersV2 (ContentText, 'Thyroid Gland:', DEFAULT)
, [ARC_DW].dbo.Pull_HeadersV2 (ContentText, 'IMPRESSION:', DEFAULT)) as ThyroidText
, ContentText 
, HI.PHRASE_ID
into MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024
FROM        
COMM4_HHC.DBO.Report INNER JOIN
                         COMM4_HHC.DBO.[Order] ON Report.ReportID = [Order].ReportID INNER JOIN
                         COMM4_HHC.DBO.Visit ON [Order].VisitID = Visit.VisitID INNER JOIN
                         COMM4_HHC.DBO.Patient ON Visit.PatientID = Patient.PatientID left outer JOIN
						 COMM4_HHC.DBO.PersonalInfo PatientDemo on Patient.PersonalInfoID = PatientDemo.PersonalInfoID left outer join
						 COMM4_HHC.DBO.Account ON Report.DictatorAcctID = Account.AccountID left outer JOIN
						 COMM4_HHC.DBO.PersonalInfo pb on Account.PersonalInfoID = pb.PersonalInfoID left outer JOIN
						 COMM4_HHC.DBO.Account b on Report.SignerAcctID = b.AccountID left outer JOIN
                         COMM4_HHC.DBO.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID INNER JOIN
						 MIPS.DBO.HHC_CPT_PIVOT ON [ORDER].ProcedureCodeList = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID]
						 AND MIPS.DBO.HHC_CPT_PIVOT.CPT  IN ('70486','70487','70488','70490','70491','70492','70498','70540','70542','70543','70547','70548','70549','71250','71260','71270','71271','71555','72125','72126','72127','71550','71551','71552','72141','72142','72156')
						 LEFT OUTER JOIN 
							(SELECT * FROM ARC_DW.DBO.REPORT_PHRASES WHERE MEASURE = '406') AS HI 
						 ON ContentText LIKE concat('%',HI.PHRASE,'%')
WHERE  [ORDER].SITEID IN (8) 
and (report.contenttext LIKE '%THYROID%' and report.contenttext like '%nodule%') 
AND (REPORT.LastModifiedDate >= '1/1/2024' AND REPORT.LastModifiedDate < '1/1/2025')
AND PHRASE_ID IS NULL
;

DROP TABLE IF EXISTS MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024_FINAL;
SELECT 
EXAM_DATE_TIME
, PHYSICIAN_GROUP_TIN
, PHYSICIAN_NPI
, READING_RADIOLOGIST
, PATIENT_ID
, PATIENT_AGE
, PATIENT_GENDER
, PATIENT_MEDICARE_BENEFICIARY
, PATIENT_MEDICARE_ADVANTAGE
, MEASURE_NUMBER
, APPOINTMENTREASON
, CPT_CODE
, DENOMINATOR_DIAGNOSIS_CODE
, MEASURE_EXTENSION_NUM
, EXTENSION_RESPONSE_VALUE
, EXAM_UNIQUE_ID
, MODALITY
, MCODE, 
	CASE 
		WHEN (ThyroidText LIKE '%No discrete thyroid%'
		OR ThyroidText LIKE '%No significant thyroid%'
		OR ThyroidText LIKE '%Thyroid Gland:  Unremarkable%'
		OR (ThyroidText NOT LIKE '%thyroid%' AND ThyroidText NOT LIKE '%nodule%')
		OR addendtext LIKE '%US THYROID NOT RECOMMEND%')
		THEN 'G9556'
		ELSE 
			CASE 
				WHEN (ContentText LIKE '%US Thyroid recommend%'
						OR ContentText LIKE '%US Thyroid need%'
						OR ContentText LIKE '%thyroid ultrasound is recommend%'
						OR ContentText LIKE '%ultrasound follow-up is recommend%') 
				THEN 'G9554' 
				ELSE 'G9556' 
				END 
		END AS NUMERATOR_RESPONSE_VALUE 
into MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024_FINAL
FROM (
 SELECT distinct 
 CONVERT(VARCHAR(10), APPOINTMENTDATE, 101) as EXAM_DATE_TIME
 , case when  MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.MODALITY = 'CT' then '061614148'  else '061216029' end as PHYSICIAN_GROUP_TIN
, [PROVIDERDIM].npi AS PHYSICIAN_NPI
 , MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.READING_RADIOLOGIST
 , PATIENT.MRN AS PATIENT_ID
 , CONVERT(int,ROUND(DATEDIFF(hour,PATIENT.dob, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.appointmentdate)/8766.0,0)) as PATIENT_AGE
 , PATIENT.SEX AS PATIENT_GENDER
, CASE WHEN CoverageDim.PayorFinancialClass IN ('Managed Medicare', 'Medicare') THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_BENEFICIARY
 , MAX(CASE WHEN (CoverageDim.PayorFinancialClass  IN ('Managed Medicare', 'Medicare') and CoverageDim.benefitplanname NOT IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD',
'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE',
'AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS')) or (CoverageDim.payorfinancialclass IN ('MEDICARE', 'MEDICAREMC') and CoverageDim.benefitplanname IN ('HARVARD PILGRIM','HARVARD PILGRIM UNITED','HUMANA','HUMANA - GENERIC','HUMANA MEDICARE GENERIC','HUMANA MGD MEDICARE','HUMANA - LEXINGTON','OXFORD HEALTH PLAN','EMPIRE BLUECROSS BLUESHIELD',
'HORIZON BCBSNJ','ANTHEM EMPIRE BCBS','ANTHEM FEP BCBS CT','ANTHEM NATIONAL BCBS CT','CIGNA ALL','CIGNA - GENERIC','CIGNA BEHAVIORAL HEALTH','CIGNA GENERIC','CIGNA HMO','CIGNA MGD MEDICARE','CIGNA OSCAR','CIGNA PPO','OXFORD HEALTH PLANS','AETNA - HMO-MEDICARE AND ALL OTHERS','AETNA HMO','AETNA HMO/POS','AETNA ADVANTAGE PLANS OFF EXCHANGE','AETNA MEDICARE ADVANTAGE',
'AETNA ADVANTAGE PLANS/AETNA OPEN ACCESS') AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.appointmentdate)/8766.0,0))  >= 65) THEN 'Y' ELSE 'N' END) AS PATIENT_MEDICARE_ADVANTAGE
, '406' AS MEASURE_NUMBER
, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.APPOINTMENTREASON
, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.CPT + ' & G9552' AS CPT_CODE
, '' as DENOMINATOR_DIAGNOSIS_CODE
, '' AS MEASURE_EXTENSION_NUM
, '' AS EXTENSION_RESPONSE_VALUE
, [ORDER].FILLERORDERNUMBER AS EXAM_UNIQUE_ID
, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.MODALITY
, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.MCODE
, ThyroidText
, report.ContentText
, addend.Contenttext as addendtext
FROM MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024
inner join comm4_HHC.dbo.report on MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.reportid = report.reportid
Inner join comm4_hhc.dbo.[order] on report.reportid = [order].reportid
inner join comm4_hhc.dbo.visit on [order].visitid = visit.visitid
inner join comm4_hhc.dbo.patient on patient.patientid = visit.patientid
inner join Caboodle.dbo.ImagingFact on [order].fillerordernumber = ImagingFact.AccessionNumber
inner join Caboodle.dbo.[providerdim] on ImagingFact.FinalizingProviderDurableKey = ProviderDim.DurableKey and ProviderDim.npi <> '*Unspecified' 
inner join Caboodle.dbo.EncounterFact  on ImagingFact.PerformingEncounterKey = EncounterFact.EncounterKey
inner join Caboodle.dbo.CoverageDim on EncounterFact.PrimaryCoverageKey = CoverageDim.CoverageKey
inner join Caboodle.dbo.DepartmentDim on ImagingFact.PerformingDepartmentKey = DepartmentDim.DepartmentKey
left outer join Comm4_hhc.dbo.reportaddendum on report.reportid = reportaddendum.OriginalReportID
left outer join Comm4_hhc.dbo.report addend on addend.reportid = reportaddendum.AddendumReportID
WHERE
MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.MODALITY in ('CT', 'MR') 
AND left([imagingfact].accessionnumber, 2) not in ('CH', 'HM', 'MS', 'SV', 'WH') 
AND departmentdim.departmentcenter = 'Advanced Radiology Partners' 
AND CONVERT(int,ROUND(DATEDIFF(hour,PATIENT.dob, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.appointmentdate)/8766.0,0)) >= 18
GROUP BY APPOINTMENTDATE, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.MODALITY, [PROVIDERDIM].npi, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.READING_RADIOLOGIST
, PATIENT.MRN, PATIENT.dob, PATIENT.SEX, CoverageDim.PayorFinancialClass, CoverageDim.benefitplanname, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.APPOINTMENTREASON
, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.CPT, [ORDER].FILLERORDERNUMBER, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.MODALITY
, MIPS.DBO.INCIDENTAL_THYROID_NODULES_406_2024.MCODE, ThyroidText, report.ContentText, addend.Contenttext
) AS X
WHERE replace(CONCAT(ThyroidText, addendtext) , ' ', '') NOT LIKE '%[1-9].[0-9]CM%' 
AND replace(CONCAT(ThyroidText, addendtext) , ' ', '') NOT LIKE '%[1-9].[0-9] x [0-9].[0-9]cm%' 
AND replace(CONCAT(ThyroidText, addendtext) , ' ', '') NOT LIKE '%[1-9][1-9]mm%'
AND replace(CONCAT(ThyroidText, addendtext) , ' ', '') NOT LIKE '%[1-9]cm%'
AND (ThyroidText NOT LIKE '%Unremarkable%' AND ThyroidText NOT LIKE '%Additional Comments: NONE%')
AND (ThyroidText like '%subcentimeter%' OR replace(ThyroidText, ' ', '') like '%[0-9]mm%' OR replace(ThyroidText, ' ', '') like '%0.[1-9]cm%')
;