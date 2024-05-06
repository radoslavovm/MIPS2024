DROP TABLE MIPS.DBO.ACRAD41_PET_2024;
SELECT 
[REPORT].REPORTID
, 'ACRAD41' AS MEASURE_NUMBER
, pd.lastname + ', ' + pd.firstname AS PATIENT_NAME
, Patient.MRN AS MRN
,patient.DOB
, patient.Sex
, [ORDER].FillerOrderNumber AS ACCESSION
,  convert(varchar(10), [order].startdate, 101) as APPOINTMENTDATE
,  CONVERT(VARCHAR(8),CONVERT(TIME,[order].startdate)) AS APPOINTMENTTIME
, [ORDER].PROCEDURECODELIST AS MCODE
, LEFT([ORDER].PROCEDUREDESCLIST, 2) AS MODALITY
, [ORDER].PROCEDUREDESCLIST AS APPOINTMENTREASON
, PersonalInfo.FirstName + ' ' + PersonalInfo.LastName as Reading_Radiologist
, REPORT.LASTMODIFIEDDATE AS REPORTSIGNED
, report.contenttext
, p.CPT
INTO MIPS.DBO.ACRAD41_PET_2024
FROM comm4_hhc.dbo.Report 
INNER JOIN comm4_hhc.dbo.[Order] ON Report.ReportID = [Order].ReportID 
INNER JOIN comm4_hhc.dbo.Visit ON [Order].VisitID = Visit.VisitID 
INNER JOIN comm4_hhc.dbo.Patient ON Visit.PatientID = Patient.PatientID 
left outer JOIN comm4_hhc.dbo.PersonalInfo PD on Patient.PersonalInfoID = PD.PersonalInfoID 
left outer join comm4_hhc.dbo.Account ON Report.DictatorAcctID = Account.AccountID 
left outer JOIN comm4_hhc.dbo.PersonalInfo pb on Account.PersonalInfoID = pb.PersonalInfoID 
left outer JOIN comm4_hhc.dbo.Account b on Report.SignerAcctID = b.AccountID 
left outer JOIN comm4_hhc.dbo.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID 
inner join MIPS.dbo.HHC_CPT_PIVOT p ON P.[MPI: ID] =[ORDER].ProcedureCodeList 
						 AND P.CPT IN ('78811','78812','78813','78814','78815','78816','G0219','G0235','G0252')
WHERE [order].siteid = 8 and left([order].fillerordernumber, 2) not in ('CH', 'HM', 'MS', 'SV', 'WH')  and report.contenttext not like '%Alzheimer%' and (REPORT.LastModifiedDate >='1/1/2024' AND REPORT.LastModifiedDate < '1/1/2025') ;

DROP TABLE MIPS.DBO.ACRAD41_PET_FINAL_2024;
SELECT distinct 
APPOINTMENTDATE as EXAM_DATE_TIME
, APPOINTMENTTIME
, '061614148' as PHYSICIAN_GROUP_TIN
, case when reading_radiologist = 'Adam Kaye' then '1881838118'
       when reading_radiologist = 'Sudhir Kunchala' then '1023467495'
	   when reading_radiologist = 'John-Paul Velasco' then '1861712309'
       else ProviderDim.NPI end AS PHYSICIAN_NPI
,MIPS.DBO.ACRAD41_PET_2024.READING_RADIOLOGIST
, MIPS.DBO.ACRAD41_PET_2024.REPORTSIGNED
, MRN AS PATIENT_ID,
 CONVERT(int,ROUND(DATEDIFF(hour, MIPS.DBO.ACRAD41_PET_2024.DOB, APPOINTMENTDATE)/8766.0,0)) as PATIENT_AGE
 , MIPS.DBO.ACRAD41_PET_2024.SEX AS PATIENT_GENDER
, 'ACRAD41' AS MEASURE_NUMBER
, MIPS.DBO.ACRAD41_PET_2024.APPOINTMENTREASON
, MIPS.DBO.ACRAD41_PET_2024.CPT AS CPT_CODE
,  CASE WHEN (MIPS.DBO.ACRAD41_PET_2024.contenttext LIKE '%Blood glucose%') and (MIPS.DBO.ACRAD41_PET_2024.contenttext like '%background uptake%') and (MIPS.DBO.ACRAD41_PET_2024.contenttext like '%uptake time%' or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%minutes following tracer administration PET imaging%') and
                                (MIPS.DBO.ACRAD41_PET_2024.contenttext like '%maximum SUV%' or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%SUV maxf%' or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%(SUVmax%' 
								or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%max SUV%' or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%No disease-specific abnormal uptake%' 
								or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%No other disease-specific abnormal uptake is identified%' or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%No evidence of FDG avid recurrent or metastatic disease%' 
								or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%no significant FDG uptake%' or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%detectable FDG uptake%' or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%no significant uptake%' 
								or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%no additional sites of FDG%' or MIPS.DBO.ACRAD41_PET_2024.contenttext like '%No abnormal FDG avid uptake%') 
	THEN 'Y' ELSE 'N' END AS NUMERATOR_RESPONSE_VALUE
, '' AS MEASURE_EXTENSION_NUM
, '' AS EXTENSION_RESPONSE_VALUE
, ACCESSION AS EXAM_UNIQUE_ID
, MIPS.DBO.ACRAD41_PET_2024.MCODE
INTO MIPS.DBO.ACRAD41_PET_FINAL_2024 
FROM MIPS.DBO.ACRAD41_PET_2024
inner join Caboodle.dbo.ImagingFact on ImagingFact.AccessionNumber =  MIPS.DBO.ACRAD41_PET_2024.ACCESSION
inner join Caboodle.dbo.ProviderDim on ImagingFact.FinalizingProviderDurableKey = ProviderDim.DurableKey
inner join Caboodle.dbo.DepartmentDim on ImagingFact.PerformingDepartmentKey = DepartmentDim.DepartmentKey 
where left([imagingfact].accessionnumber, 2) not in ('CH', 'HM', 'MS', 'SV', 'WH') and departmentdim.departmentcenter = 'Advanced Radiology Partners' and MIPS.DBO.ACRAD41_PET_2024.contenttext not like '%the patient did not keep the appointment%'
order by numerator_response_value
