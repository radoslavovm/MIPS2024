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
Interpretation of CT Pulmonary Angiography (CTPA) for Pulmonary Embolism
  > CT pulmonary angiography (CTPA) with a finding of PE that specify the branching order level of the most proximal level of embolus (i.e. main, lobar, interlobar, segmental sub segmental)
  
  > [Documentation](https://www.acr.org/-/media/ACR/Files/Registries/QCDR/GRID-MIPS-Simplified-Measure-Specifications.pdf)

### ACRAD36
Incidental Coronary Artery Calcification Reported on Chest CT
  > CT exams that note presence or absence of coronary artery calcification (CAC) or not evaluable.
  
  > [Documentation](https://www.acr.org/-/media/ACR/Files/Registries/QCDR/GRID-MIPS-Simplified-Measure-Specifications.pdf)

### ACRAD41
Use of Quantitative Criteria for Oncologic FDG PET Imaging
  non-CNS oncologic FDG PET studies that include at a minimum:
  > a. Serum glucose (e.g. finger stick at time of injection)
  > b. Uptake time (interval from injection to initiation of imaging)
  > c. One reference background (e.g. volumetric normal liver or mediastinal blood pool) SUV measurement, along with description of the SUV measurement type (e.g. SUVmax) and normalization method (e.g. BMI)
  > d. At least one lesional SUV measurement OR diagnosis of "no disease-specific abnormal uptake"

  > [Documentation](https://www.acr.org/-/media/ACR/Files/Registries/QCDR/GRID-MIPS-Simplified-Measure-Specifications.pdf)

### 405
  > [Documentation](https://qpp.cms.gov/docs/QPP_quality_measure_specifications/CQM-Measures/2020_Measure_405_MIPSCQM.pdf)

### 406
  > [Documentation](https://qpp.cms.gov/docs/QPP_quality_measure_specifications/CQM-Measures/2024_Measure_406_MIPSCQM.pdf)

### 436
  > [Documentation](https://qpp.cms.gov/docs/QPP_quality_measure_specifications/CQM-Measures/2020_Measure_436_MIPSCQM.pdf)



# TO DO 
Update all of the queries with the new logic. Document as you go. 
- [x] Add the new column for report prases table that is layed out in the documentation
- [X] acrad37 
- [X] acrad36 
- [] acrad41
- [1/2] 405 
> - Needs a quality check
- [] 406
- [X] 436 
- [] BH addendum addition for all measures. where do BH addendums sit?
 

- [X] As part of the new job, create an output that provides all of the noncompliant cases, and the necessary information to submit an addendum.
  Add documentation on these results. 

- [] Addendum query currently is only checking for compliance, not a case where the addendum might exclude the report. we need to accomodate for this somehow. 

Add links in this read me to all of the measure documentation