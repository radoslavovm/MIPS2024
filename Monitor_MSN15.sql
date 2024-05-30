/*
On a weekly basis, Dr Muro wants to see the compliance and non compliance of MSN15 by doctors. 
The only adjustment to this query needs to be to update the date range, both in the column and in the 'where' filters
*/

SELECT READING_RADIOLOGIST, NUMERATOR_RESPONSE_VALUE, count(EXAM_UNIQUE_ID), 'ADRAD' as [Site], '5/20/2024 - 5/30/2024' AS DATERANGE
FROM MIPS.[dbo].[MSN_15_2024_FINAL] AS FINAL
JOIN COMM4_HHC.dbo.[Order] AS O
ON O.FillerOrderNumber = FINAL.EXAM_UNIQUE_ID
JOIN COMM4_HHC.dbo.Report AS REPORT
ON O.ReportID = REPORT.ReportID
JOIN COMM4_HHC.[dbo].[Visit] AS V
ON O.VisitID = V.VisitID
JOIN COMM4_HHC.dbo.Patient AS P
ON V.PatientID = P.PatientID
AND o.LastModifiedDate >= '05/20/2024'
group by READING_RADIOLOGIST, NUMERATOR_RESPONSE_VALUE

union 

SELECT READING_RADIOLOGIST, NUMERATOR_RESPONSE_VALUE, count(f.ACCESSION), 'BH' as [Site], '5/20/2024 - 5/30/2024' AS DATERANGE
FROM MIPS_BRA.dbo.MSN_15_2024 AS F
JOIN ARC_DW.dbo.BH_Reports AS R
ON R.ACCESSION = F.ACCESSION
JOIN ARC_DW.dbo.BH_ExamDetails AS E
ON E.ACCESSION = F.ACCESSION
AND f.APPOINTMENTDATE >= '05/20/2024'
group by READING_RADIOLOGIST, NUMERATOR_RESPONSE_VALUE

union


SELECT READING_RADIOLOGIST, NUMERATOR_RESPONSE_VALUE, count(f.ACCESSION), 'SV' as [Site], '5/20/2024 - 5/30/2024' AS DATERANGE
FROM MIPS_BRA.dbo.MSN_15_2024 AS F
INNER JOIN comm4_hhc.dbo.[Order] as O
ON O.FillerOrderNumber = F.ACCESSION
JOIN comm4_hhc.dbo.Report AS R
ON R.ReportID = O.ReportID 
LEFT OUTER JOIN arc_dw.[dbo].[PS_AutoText] AS PS ON O.FillerOrderNumber = PS.Accession
LEFT OUTER JOIN ARC_DW.[dbo].ARC_rads AS AR ON F.NPI = AR.NPI
WHERE F.ACCESSION LIKE 'SV%'
AND f.APPOINTMENTDATE >= '05/20/2024'
AND AR.Organization NOT LIKE 'TRS'
group by READING_RADIOLOGIST, NUMERATOR_RESPONSE_VALUE

;