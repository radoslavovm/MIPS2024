
-- REPORT_PHRASES TABLE
/*

PHRASE_ID PRIMARY KEY of the table. 
PHRASE the phrase to search for in reports 
MEASURE the measure that the phrase is relevant to 
CRITERIA to signify compliance or noncompliance based on phrase (ex. Y, N)
DENOMINATOR to determine if the report should be inculded in the measure calculation based on the phrase (ex. INCLUDE, EXCLUDE)
)
*/

/*
CREATE TABLE ARC_DW.DBO.REPORT_PHRASES(
	PHRASE_ID INT NOT NULL IDENTITY(1,1) PRIMARY KEY,
	PHRASE NVARCHAR(4000) NOT NULL,
	MEASURE NVARCHAR(4000) NOT NULL,
	CRITERIA NVARCHAR(4000) NOT NULL,
	DENOMINATOR NVARCHAR(4000)
)
*/

INSERT INTO ARC_DW.DBO.REPORT_PHRASES (PHRASE, MEASURE, CRITERIA, DENOMINATOR
)
VALUES 
('','','','')
;

SELECT * 
FROM ARC_DW.DBO.REPORT_PHRASES
ORDER BY MEASURE, CRITERIA;

