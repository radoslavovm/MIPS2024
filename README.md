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
(The descriptions are for a quick understanding of the measure. For a more detailed understanding of which reports are included and for the qualifications of compliance, click on the documentation link)
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
Appropriate Follow-up Imaging for Incidental Abdominal Lesions

Reports with one or more of the following noted incidentally with a specific recommendation for no follow‐up imaging recommended based on radiological  findings: <br>
> • Cystic renal lesion that is simple appearing (Bosniak I or II) <br>
> OR <br>
> • Adrenal lesion less than or equal to 1.0 cm <br>
> OR <br>
> • Adrenal lesion greater than 1.0 cm but less than or equal to 4.0 cm classified as likely benign by unenhanced CT or 
washout protocol CT, or MRI with in- and opposed-phase sequences or other equivalent institutional imaging 
protocols 

  > [Documentation](https://qpp.cms.gov/docs/QPP_quality_measure_specifications/CQM-Measures/2020_Measure_405_MIPSCQM.pdf)

### 406
Appropriate Follow-up Imaging for Incidental Thyroid Nodules in Patients <br>
*** This is an inverse measure. AKA the lower the score the better <br>
Final reports for CT, CTA, MRI or MRA of the chest or neck with follow-up imaging recommended for reports with 
an incidentally-detected thyroid nodule < 1.0 cm noted

  > [Documentation](https://qpp.cms.gov/docs/QPP_quality_measure_specifications/CQM-Measures/2024_Measure_406_MIPSCQM.pdf)

### 436
Radiation Consideration for Adult CT: Utilization of Dose Lowering Techniques

Computed tomography (CT) with documentation 
that one or more of the following dose reduction techniques were used <br>
> • Automated exposure control <br>
> • Adjustment of the mA and/or kV according to patient size <br>
> • Use of iterative reconstruction technique

  > [Documentation](https://qpp.cms.gov/docs/QPP_quality_measure_specifications/CQM-Measures/2020_Measure_436_MIPSCQM.pdf)



# TO DO 
- [] Measure 405 needs a quality check. Also a discussion with doctors to determine clearer language for the specifications of this measure 
- [] MSN13
- [] MSN15 TIRADS, this measure is under monitoring. Addendums should not be sent for this measure until Dr Muro decides it is appropriate
- [] BH addendum addition for all measures. Where do BH addendums sit?
- [] Addendum query currently is only checking for compliance, not a case where the addendum might exclude the report (ex. additional information of medical history that excludes the report from the denominator). We need to accomodate for this somehow. 

# Adendum Process
Use the ADRAD_COMPLIANCE.sql, BH_COMPLIANCE.sql, and SV_COMPLIANCE.sql scripts. The result will be all noncompliant cases: 
  Accession number, MRN, Radiologist, Report text, Measure, Date, and Addendum text. 

Examine the report and addendum to pin point the reason for the non compliance. 

## Send an email to the radiologist using the following template: 
​
Good day **[Radiologist]** , 

The following report is missing information necessary to satisfy MIPS quality requirements.  
The measure is related to **[ The title of the measure (they can be found on the first line of each measure, or in the documentation) ]**. <br>
This applies to exams where <br>
**[Provide the brief descriptions listed in the read me for the measure in question]**

An exception may apply if there is medical history reasons that might require a follow up. Your reports may qualify for the exception criteria.  Is there any relevant patient history that has not been specified in the report?

FillerOrderNumber/ Accession Number : **[Accession]** <br>
Date: **[Date]** <br>
MRN: **[MRN]** <br>

Reasoning for addendum request: **[provide reasoning]**

Let me know if you have any questions. 

Thank you, 
**[Your name]** 

Other Comments 
<br>
---
If the doctor has multiple addendums, you can add them to one email, just make sure it is clear the reasoning behind each one. 