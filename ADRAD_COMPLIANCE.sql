WITH A_CTE (MRN, LastModifiedDate, ContentText, FillerOrderNumber, Addendum)
AS (
SELECT MRN, O.LastModifiedDate, REPORT.ContentText, FillerOrderNumber , addend.ContentText AS Addendum
FROM COMM4_HHC.dbo.[Order] AS O
JOIN COMM4_HHC.dbo.Report AS REPORT
	ON O.ReportID = REPORT.ReportID
JOIN COMM4_HHC.[dbo].[Visit] AS V
	ON O.VisitID = V.VisitID
JOIN COMM4_HHC.dbo.Patient AS P
	ON V.PatientID = P.PatientID
LEFT OUTER JOIN comm4_hhc.dbo.ReportEvent as RE 
	ON re.ReportID = REPORT.ReportID
LEFT OUTER JOIN Comm4_hhc.dbo.reportaddendum 
	ON REPORT.reportid = reportaddendum.OriginalReportID
LEFT OUTER JOIN Comm4_hhc.dbo.report addend 
	ON addend.reportid = reportaddendum.AddendumReportID
)

SELECT *
FROM 
(
SELECT EXAM_UNIQUE_ID, ContentText, A_CTE.Addendum, READING_RADIOLOGIST, MRN, LastModifiedDate, NUMERATOR_RESPONSE_VALUE, MEASURE_NUMBER
FROM MIPS.dbo.ACRAD36_CORONARYARTERY_FINAL_2024 AS FINAL
INNER JOIN A_CTE
ON A_CTE.FillerOrderNumber = FINAL.EXAM_UNIQUE_ID

UNION

SELECT EXAM_UNIQUE_ID, ContentText, Addendum, READING_RADIOLOGIST, MRN, LastModifiedDate, NUMERATOR_RESPONSE_VALUE, MEASURE_NUMBER
FROM MIPS.dbo.ACRAD37_PE_FINAL_2024 AS FINAL
INNER JOIN A_CTE
ON A_CTE.FillerOrderNumber = FINAL.EXAM_UNIQUE_ID

UNION

SELECT EXAM_UNIQUE_ID, ContentText, Addendum, READING_RADIOLOGIST, MRN, LastModifiedDate, NUMERATOR_RESPONSE_VALUE, MEASURE_NUMBER
FROM MIPS.dbo.ACRAD41_PET_FINAL_2024 AS FINAL
INNER JOIN A_CTE
ON A_CTE.FillerOrderNumber = FINAL.EXAM_UNIQUE_ID

UNION

SELECT EXAM_UNIQUE_ID, ContentText, Addendum, READING_RADIOLOGIST, MRN, LastModifiedDate, NUMERATOR_RESPONSE_VALUE, MEASURE_NUMBER
FROM MIPS.[dbo].[CAT_436_2024_FINAL] AS FINAL
INNER JOIN A_CTE
ON A_CTE.FillerOrderNumber = FINAL.EXAM_UNIQUE_ID

UNION

SELECT EXAM_UNIQUE_ID, ContentText, Addendum, READING_RADIOLOGIST, MRN, LastModifiedDate, NUMERATOR_RESPONSE_VALUE, MEASURE_NUMBER
FROM MIPS.[dbo].[INCIDENTAL_ABDOMINAL_LESIONS_405_2024_FINAL] AS FINAL
INNER JOIN A_CTE
ON A_CTE.FillerOrderNumber = FINAL.EXAM_UNIQUE_ID

UNION

SELECT EXAM_UNIQUE_ID, ContentText, Addendum, READING_RADIOLOGIST, MRN, LastModifiedDate, NUMERATOR_RESPONSE_VALUE, MEASURE_NUMBER
FROM MIPS.[dbo].[INCIDENTAL_THYROID_NODULES_406_2024_FINAL] AS FINAL
INNER JOIN A_CTE
ON A_CTE.FillerOrderNumber = FINAL.EXAM_UNIQUE_ID

UNION

SELECT EXAM_UNIQUE_ID, ContentText, Addendum, READING_RADIOLOGIST, MRN, LastModifiedDate, NUMERATOR_RESPONSE_VALUE, MEASURE_NUMBER
FROM MIPS.[dbo].[MSN_13_2024_FINAL] AS FINAL
INNER JOIN A_CTE
ON A_CTE.FillerOrderNumber = FINAL.EXAM_UNIQUE_ID

) A
WHERE NUMERATOR_RESPONSE_VALUE IN ('N', 'PNM01', 'G9554', 'G9550', 'G9638')
AND LastModifiedDate >= '04/1/2024' ;