select REPORT.ReportID

from (select distinct MEASURE

      from ARC_DW.DBO.REPORT_PHRASES

     ) all_measures

    ,COMM4_HHC.DBO.Report

WHERE REPORT.LastModifiedDate >= '1/1/2024'

  and exits (select 1

             from ARC_DW.DBO.REPORT_PHRASES

             WHERE CRITERIA = 'Y' and MEASURE = all_measures.all_measures

               and Report.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')

            )

  and not exits (select 1

                 from ARC_DW.DBO.REPORT_PHRASES

                 WHERE CRITERIA = 'EXCLUDE' and MEASURE = all_measures.all_measures

                   and Report.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')

            );


SELECT distinct COUNT(R.ReportID)
FROM (
SELECT DISTINCT ReportID, Report.SignerAcctID, report.lastmodifieddate,
(SELECT TOP 1 PHRASE FROM ARC_DW.DBO.REPORT_PHRASES
	WHERE CRITERIA = 'Y' AND MEASURE = '436'
	and Report.ContentText LIKE CONCAT('%',REPORT_PHRASES.PHRASE,'%')
) performance_met
FROM COMM4_HHC.DBO.Report
WHERE Report.lastmodifieddate >= '01/01/2024' 
) AS R -- 386,284 (There are duplicate reports but why)
Inner join comm4_hhc.dbo.[order] on R.reportid = [order].reportid
-- 394,652
inner join comm4_hhc.dbo.visit on [order].visitid = visit.visitid
inner join comm4_hhc.dbo.patient on patient.patientid = visit.patientid
inner JOIN COMM4_HHC.DBO.PersonalInfo PatientDemo on Patient.PersonalInfoID = PatientDemo.PersonalInfoID 
inner JOIN COMM4_HHC.DBO.Account b on R.SignerAcctID = b.AccountID --394,625
inner JOIN COMM4_HHC.DBO.PersonalInfo ON b.PersonalInfoID = PersonalInfo.PersonalInfoID 
INNER join Epic_SVMC.dbo.ImagingFact on [order].fillerordernumber = ImagingFact.img_accession_num --35,707
INNER join Caboodle.dbo.[providerdim] on ImagingFact.IMG_FINALIZING_PROV_ID= [providerdim].providerkey and [providerdim].npi <> '*Unspecified' 
INNER join Epic_SVMC.dbo.EncounterFact  on ImagingFact.IMG_PERF_ENC_KEY = EncounterFact.EncounterKey --35,315
INNER join Epic_SVMC.dbo.CoverageDim on EncounterFact.PrimaryCoverageKey = CoverageDim.CoverageKey --56,154,399
INNER join Caboodle.dbo.DepartmentDim on ImagingFact.IMG_PERFORMING_DEPT_KEY = DepartmentDim.DepartmentKey
LEFT OUTER JOIN MIPS.DBO.HHC_CPT_PIVOT ON [ORDER].ProcedureCodeList = MIPS.DBO.HHC_CPT_PIVOT.[MPI: ID]
						 AND MIPS.DBO.HHC_CPT_PIVOT.CPT  IN (
						   '70450', '70460', '70470', '70480', '70481', '70482', '70486', '70487', '70488', '70490', '70491', '70492', '70496', '70498', '71250', '71260', '71270', '71271'
						 , '71275', '72125', '72126', '72127', '72128', '72129', '72130', '72131', '72132', '72133', '72191', '72192', '72193', '72194', '73200', '73201', '73202', '73206', '73700', '73701'
						 , '73702', '73706', '74150', '74160', '74170', '74174', '74175', '74176', '74177', '74178', '74261', '74262', '74263', '75571', '75572', '75573', '75574', '75635', '76380', '76497'
						 , '77011', '77012', '77013', '77014', '77078', '0042T', 'G0297')