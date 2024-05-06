# Introduction 
MIPS Measures follow specific criteria to determine the exams that should be included in the denominator and the reports that are compliant and should represent the numerator to create a MIPS score of compliance. 

## The Data 
ARC_DW.DBO.REPORT_PHRASES 
  Fields: Phrase_id, (a unique ID that is the primary key. This is auto-generated)
          Phrase, (the phrase that will be searched for in a report)
          Criteria, (A string code that determines if the presence of the phrase suggests compliance, noncompliance, or an exception)
          Measure, (Value is a string determining the measure the phrase cooresponds to)
          Denominator (Values are INCLUDE or EXCLUDE)
  
  the report_phrases.sql file is how we insert new phrases that need to be considered in the mips measure calculation. This is how we rectify false negative numerator response values 

## The Measures 

### ACRAD37

### ACRAD36

### ACRAD41

### 405

### 406

### 436
