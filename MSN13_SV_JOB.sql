INSERT INTO MIPS_BRA.DBO.MSN_13_2024([APPOINTMENTDATE],[TIN],[NPI],[READING_RADIOLOGIST],[MRN],[PATIENT_NAME],
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
        AND CONVERT(int,ROUND(DATEDIFF(hour,patient.dob,[ORDER].STARTDATE)/8766.0,0))  >= 65) 
    THEN 'Y' ELSE 'N' END AS PATIENT_MEDICARE_ADVANTAGE
, 'MSN13' AS MEASURE_NUMBER
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, P.CPT AS CPT_CODE
, '' as DENOMINATOR_DIAGNOSIS_CODE
, [ORDER].FILLERORDERNUMBER AS ACCESSION
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
,  CASE WHEN ((report.contenttext LIKE '%Calcium Score%' or report.contenttext like '%CACS%') 
        and (report.contenttext like '%Left Main%' or report.contenttext like '%LM:%' or report.contenttext like '%LM%') 
        and report.contenttext like '%LAD%' 
        and report.contenttext like '%LCx%' 
        and report.contenttext like '%RCA%' 
        and report.contenttext like '%PDA%') 
    THEN 'PM001' ELSE 'PNM01' END AS NUMERATOR_RESPONSE_VALUE
, '' AS MEASURE_EXTENSION_NUM
, '' AS EXTENSION_RESPONSE_VALUE
FROM comm4_hhc.dbo.Report 
INNER JOIN comm4_hhc.dbo.[Order] ON Report.ReportID = [Order].ReportID 
INNER JOIN comm4_hhc.dbo.Visit ON [Order].VisitID = Visit.VisitID 
INNER JOIN comm4_hhc.dbo.Patient ON Visit.PatientID = Patient.PatientID 
left outer JOIN comm4_hhc.dbo.PersonalInfo PD on Patient.PersonalInfoID = PD.PersonalInfoID 
left outer join comm4_hhc.dbo.Account ON Report.DictatorAcctID = Account.AccountID 
left outer JOIN comm4_hhc.dbo.PersonalInfo pb on Account.PersonalInfoID = pb.PersonalInfoID 
left outer JOIN comm4_hhc.dbo.Account b on Report.SignerAcctID = b.AccountID 
left outer JOIN comm4_hhc.dbo.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID 
left outer join Epic_SVMC.dbo.ImagingFact on [order].fillerordernumber = ImagingFact.img_accession_num
left outer join Caboodle.dbo.[providerdim] on ImagingFact.IMG_FINALIZING_PROV_ID= [providerdim].providerkey and [providerdim].npi <> '*Unspecified' 
left outer join Caboodle.dbo.DepartmentDim on ImagingFact.IMG_PERFORMING_DEPT_KEY = DepartmentDim.DepartmentKey
left outer join Epic_SVMC.dbo.EncounterFact  on ImagingFact.IMG_PERF_ENC_KEY = EncounterFact.EncounterKey
left outer join Epic_SVMC.dbo.CoverageDim on EncounterFact.PrimaryCoverageKey = CoverageDim.CoverageKey
INNER join MIPS.dbo.HHC_CPT_PIVOT p ON P.[MPI: ID] =[ORDER].ProcedureCodeList 
where [order].siteid = 7 and left([ORDER].FILLERORDERNUMBER, 2)in ( 'SV') 
AND P.CPT IN ('75571') and REPORT.LastModifiedDate >='1/1/2024' 
and  (report.contenttext not like '%calcium score is 0%')
;
