# Disposition_Dataset_Validation
- Project Title: 	Disposition (DS) Dataset Validation
- Description: 		Validation of DS dataset by writing independent SAS code.
- SAS Version:		STUDIO 
## Introduction 
The project involves validating an already developed Laboratory dataset using the input SDTM datasets and comparing both.
- Structure of DS: One record per disposition status or protocol milestone per 
subject.

## Logical Follow.
- Establishing a library to house all three datasets. 
- Specifying variables from individual datasets according to the RSD (Requirement specification document). 
- Merging the three datasets with USUBJID (unique subject ID)  and further specifying the other variable requiring more than one dataset.
- After completion, the final dataset was sorted with the  USUBJID, DSSTDTC, and DSDECOD. 
- The final dataset was then compared with an already-developed DS.SAS7bdat.
## Inputs
    •DS.sas7bdat
    •Rand.sas7bdat
    •Comvar.sas7bdat
          
## Tasks
	As explained in the Requirement Specification (RSD) 🔽

|SN|Variable Name 	|Variable Label |Data Type|CDISC Notes 	|Algorithm|
|---|---------------|---------------|---------|---------------|---------|
|1|STUDYID| Study Identifier| Char| Unique identifier for a study.| Direct Mapping|
|2|DOMAIN |Domain Abbreviation|Char |Two-character abbreviation for the domain.| "DS"|
|3|USUBJID| Unique Subject Identifier |Char|Identifier used to uniquely identify a subject across all studies for all applications or submissions involving the product. This must be a unique number, and could be a compound identifier formed by concatenating STUDYID-SITEID-SUBJID.|Direct Mapping(DS.STUDYID concatenated '-'concatenated SITEID concatenated'-'concatenated DS.SUBJID)|
|4|DSSEQ |Sequence Number| Num|Derived. Sequence Number is given to ensure the uniqueness of subject records within a domain.|Sequence Number = Number of subjects who participated in the study|
|5|DSTERM| Term for the Disposition Event|DSTERM|Verbatim name of the event or protocol milestone. Some terms in DSTERM will match DSDECOD, but others, such as ―Subject moved‖ will map to controlled terminology in DSDECOD, such as  ―LOST TO FOLLOW-UP.|RAND.DSTERM,  DM.DSTERM, DS.DSTERM (as DSTERM is not available in DM dataset, it is created by considering all DM data as 'Informed consent obtained')|
|6|DSDECOD| Standardized Disposition Term |DSDECOD|Controlled terminology for the name of disposition event or protocol milestone. Examples of protocol milestones: INFORMED CONSENT OBTAINED, RANDOMIZED|RAND.DSDECOD, DM.DSDECOD, DS.DSDECOD (as DSDECOD is not available in DM dataset, it is created by considering all DM data as 'Informed consent obtained')|
|7|DSCAT| Category for Disposition Event| Char|Used to define a category of related records. DSCAT is now an ―Expected variable. DSCAT was permissible in SDTMIG 3.1.1 and earlier versions. The change from ―permissible to ―expected is based on the requirement to distinguish protocol milestones and/or other events from disposition events. DSCAT may be null if there are only ―disposition events; however, it is recommended that DSCAT always be populated.|Derived from example given in IG which shows which data will comes under what category example : Protocol Milestone,Disposition Event, Other events.|
|8|DSSCAT|Subcategory for disposition event| Char| A further categorization of disposition event.||
|9|DSSTDTC| Start Date/Time of disposition event |Char| |RAND.DSSTDTC, DM.DSSTDTC, DS.DSSTDTC|
|10|DSSTDY| Study Day of Start of Disposition Event |Num |Study day of start of event relative to the sponsor-defined RFSTDTC. Perm|If DSSTDTC1 ge _RFSTDTC THEN DSSTDY=(ds.DSSTDTC1-comvar._RFSTDTC)+1; ELSE DSSTDY=ds.DSSTDTC1-comvar._RFSTDTC|

## Output
- [Dataset](https://github.com/theadewole/Disposition_Dataset_Validation/blob/main/ds.sas7bdat)
- [Program](https://github.com/theadewole/Disposition_Dataset_Validation/blob/main/DS.sas)
- [Log](https://github.com/theadewole/Disposition_Dataset_Validation/blob/main/DS.log)
- [Validate](https://github.com/theadewole/Disposition_Dataset_Validation/blob/main/Validate)
