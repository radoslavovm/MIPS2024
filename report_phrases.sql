
-- REPORT_PHRASES TABLE

/*
CREATE TABLE ARC_DW.DBO.REPORT_PHRASES(
	PHRASE_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	PHRASE NVARCHAR(4000) NOT NULL,
	MEASURE NVARCHAR(4000) NOT NULL,
	CRITERIA NVARCHAR(4000) NOT NULL
)
*/

INSERT INTO ARC_DW.DBO.REPORT_PHRASES (PHRASE, MEASURE, CRITERIA)
VALUES 
('','','')
;

SELECT * 
FROM ARC_DW.DBO.REPORT_PHRASES
ORDER BY MEASURE, CRITERIA;

