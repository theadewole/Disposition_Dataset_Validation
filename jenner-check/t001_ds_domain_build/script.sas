*===========================================================================================================;
*Establoishing Library;
*===========================================================================================================;
/* ---------------------------------------------------------------------------
   Compatibility setup (the only lines adapted from the original DS.sas).

   DS.sas reads four SDTM source datasets through the MYSNIP libref and compares
   its result against an Anadata baseline. Those libraries live on a SAS OnDemand
   for Academics account (/home/u63305936/...), and the original also redirected
   its log to an absolute path via PROC PRINTTO. So that this script runs on its
   own, MYSNIP is pointed at WORK and given small, shape-compatible stand-ins for
   exactly the columns DS.sas reads. Values mirror the study in the repo's
   baseline (CYT21013DS / CYT21013-105-0NN) and exercise every DSDECOD recode
   branch and both PROC SQL CASE arms. Everything below this block is the
   author's DS.sas logic, unchanged.
   --------------------------------------------------------------------------- */
libname MYSNIP (work);

/* MYSNIP.Comvar : common variables keyed by USUBJID (Com_2 is later merged
   BY USUBJID), carrying STUDYID with a stray hyphen DS.sas strips via COMPRESS */
data MYSNIP.Comvar;
    length USUBJID $30 STUDYID $10;
    input USUBJID $ STUDYID $;
    datalines;
CYT21013-105-015 CYT-21013
CYT21013-105-016 CYT-21013
CYT21013-105-017 CYT-21013
CYT21013-105-018 CYT-21013
CYT21013-105-019 CYT-21013
CYT21013-105-020 CYT-21013
CYT21013-105-021 CYT-21013
;
run;

/* MYSNIP.Dm : demographics; DOVDTC present -> INFORMED CONSENT OBTAINED */
data MYSNIP.Dm;
    length STUDYID $8 SITEID $3 SUBJID $3 DOVDTC $10 _RFSTDTC $10;
    input STUDYID $ SITEID $ SUBJID $ DOVDTC $ _RFSTDTC $;
    datalines;
CYT21013 105 015 2008-12-01 2008-12-13
CYT21013 105 016 2008-12-01 2008-12-12
CYT21013 105 017 2008-12-09 2008-12-13
CYT21013 105 018 2008-12-09 2008-12-13
CYT21013 105 019 2009-03-12 2009-03-16
CYT21013 105 020 2009-03-12 2009-03-16
CYT21013 105 021 2009-03-17 2009-03-19
;
run;

/* MYSNIP.rand : randomization; yields RANDOMIZED milestone rows */
data MYSNIP.rand;
    length STUDYID $8 SITEID $3 SUBJID $3 DSTERM $200 DSDECOD $100 DSSTDTC $10 _RFSTDTC $10;
    input STUDYID $ SITEID $ SUBJID $ DSSTDTC $ _RFSTDTC $;
    DSTERM  = "RANDOMIZED";
    DSDECOD = "RANDOMIZED";
    datalines;
CYT21013 105 015 2008-12-13 2008-12-13
CYT21013 105 016 2008-12-12 2008-12-12
CYT21013 105 017 2008-12-13 2008-12-13
CYT21013 105 018 2008-12-13 2008-12-13
CYT21013 105 019 2009-03-16 2009-03-16
CYT21013 105 020 2009-03-16 2009-03-16
CYT21013 105 021 2009-03-19 2009-03-19
;
run;

/* MYSNIP.ds : disposition events; verbatim DSDECOD strings drive every recode
   branch (withdrawal, screen failure, physician decision, lost to follow-up,
   protocol violation) */
data MYSNIP.ds;
    length STUDYID $8 SITEID $3 SUBJID $3 DSCAT $30 DSSCAT $30
           DSTERM $200 DSDECOD $100 DSSTDTC $10 _RFSTDTC $10;
    input STUDYID $ SITEID $ SUBJID $ DSSTDTC $ _RFSTDTC $ DSDECOD $60.;
    DSTERM = DSDECOD;
    DSCAT  = "";
    DSSCAT = "";
    datalines;
CYT21013 105 015 2009-02-03 2008-12-13 SUBJECT LOST TO FOLLOW-UP
CYT21013 105 016 2009-04-13 2008-12-12 INVESTIGATOR JUDGMENT
CYT21013 105 017 2009-04-16 2008-12-13 MAJOR PROTOCOL VIOLATION
CYT21013 105 018 2009-05-01 2008-12-13 SUBJECT DID NOT MEET INCLUSION/EXCLUSION CRITERIA
CYT21013 105 019 2009-05-10 2009-03-16 SUBJECT WITHDREW CONSENT
CYT21013 105 020 2009-05-15 2009-03-16 SUBJECT RELOCATED
CYT21013 105 021 2009-05-20 2009-03-19 INCARCERATION
;
run;
RUN;
*===========================================================================================================;
*Removing the inconsistent data from STUDYID in Comvar dataset and Sorting the dataset;
*===========================================================================================================;
DATA com_1;
    RENAME STUDYID1=STUDYID;
	LENGTH STUDYID1 $8;
	SET MYSNIP.Comvar;
	STUDYID1=COMPRESS(PUT(STUDYID,$char10.),"-");
	DROP STUDYID;
RUN;

PROC SORT DATA=com_1 OUT=Com_2;
	BY USUBJID;
RUN;

*===========================================================================================================;
*Specifying DSTERM,DSDECOD and USUBJID In DM dataset and applying sort;
*===========================================================================================================;
DATA  DM_1;
	LENGTH DSTERM $200 DSDECOD $100;
 	SET MYSNIP.Dm;
	USUBJID=PUT(CATX("-",STUDYID,SITEID,SUBJID),$char30.);
	IF DOVDTC NE " " THEN DSTERM="INFORMED CONSENT OBTAINED";
	DSDECOD=DSTERM;
RUN;

PROC SORT DATA=DM_1	OUT=DM_2;
	BY USUBJID;
RUN;

*===========================================================================================================;
*Creating USUBJID from Rand dataset and applying sort;
*===========================================================================================================;
DATA  Rand_1;
 	SET MYSNIP.rand;
	USUBJID=PUT(CATX("-",STUDYID,SITEID,SUBJID),$char30.);
RUN;

PROC SORT DATA=Rand_1	OUT=Rand_2;
	BY USUBJID;
RUN;

*===========================================================================================================;
*Creating USUBJID in DS Dataset and applyoing sort;
*===========================================================================================================;
DATA  Ds_1 (DROP=siteid subjid DSCAT DSSCAT);
 	SET MYSNIP.ds;
	USUBJID=PUT(CATX("-",STUDYID,SITEID,SUBJID),$char30.);
RUN;

PROC SORT DATA=Ds_1	OUT=Ds_2;
	BY USUBJID;
RUN;

*===========================================================================================================;
*Merging the datasets;
*===========================================================================================================;
DATA DMCOM;
	MERGE Dm_2 Com_2;
	BY USUBJID;
RUN;

*Merging Rand to the already merged Dm and Comvar;
DATA DMCOMRAN;
	SET DMCOM Rand_2;
	BY USUBJID;
RUN;

*Merging DS to the already merged Dm,Comvar,Rand;
DATA All_Set;
	SET DMCOMRAN DS_1;
	BY USUBJID;
RUN;
*===========================================================================================================;
*Specifying Domain DSTERM DSDECOD;
*===========================================================================================================;
DATA DSS;
	LENGTH DOMAIN $3;
	SET All_Set;
	DOMAIN="DS";
	DSTERM=COMPRESS(DSTERM,"#");
	IF DSDECOD EQ "SUBJECT WITHDREW CONSENT" THEN DSDECOD="WITHDRAWAL OF CONSENT";
	IF DSDECOD IN ("SUBJECT WITHDREW CONSENT","SUBJECT WITHDREW CONSENT: TIME CONSTRAINTS","SUBJECT RELOCATED")
	THEN DSDECOD="WITHDRAWAL OF CONSENT";
	IF DSDECOD IN ("SUBJECT DID NOT MEET INCLUSION/EXCLUSION CRITERIA")THEN DSDECOD="SCREEN FAILURE";
	IF DSDECOD IN ("INVESTIGATOR JUDGMENT")THEN DSDECOD="PHYSICIAN DECISION";
	IF DSDECOD IN ("INCARCERATION","SUBJECT LOST TO FOLLOW-UP","SUBJECT RELOCATED")
	THEN DSDECOD="LOST TO FOLLOW-UP";
	IF DSDECOD IN ("MAJOR PROTOCOL VIOLATION")THEN DSDECOD="PROTOCOL VIOLATION";
RUN;

*===========================================================================================================;
*Specifying DSCAT,DSSCAT;
*===========================================================================================================;
PROC SQL;
	CREATE TABLE DSSS AS
	SELECT *, CASE
	WHEN DSDECOD IN ("RANDOMIZED","INFORMED CONSENT OBTAINED") THEN "PROTOCOL MILESTONE"
	ELSE "DISPOSITION EVENT"
	END AS DSCAT,
	CASE
	WHEN DSDECOD NOT IN ("RANDOMIZED","INFORMED CONSENT OBTAINED") THEN "STUDY PARTICIPATION"
	ELSE ""
	END AS DSSCAT
	FROM DSS;
QUIT;

*===========================================================================================================;
*Specifying DSSTDY as given in RSD;
*===========================================================================================================;
DATA DSSS1;
	SET DSSS;
	IF DSSTDTC NE "" THEN DSSTDTC1=INPUT(DSSTDTC,anydtdte32.);
	IF _RFSTDTC NE "" THEN RFSTDTC=INPUT(_RFSTDTC,anydtdte32.);
	IF DSSTDTC1 GE RFSTDTC THEN DSSTDY=(DSSTDTC1-RFSTDTC)+1;
	ELSE DSSTDY=DSSTDTC1-RFSTDTC;
RUN;
*===========================================================================================================;
*Sorting the dataset with USUBJID, DSSTDTC, and DSDECOD;
*===========================================================================================================;
PROC SORT DATA=DSSS1   OUT=DSsort;
	BY USUBJID DSSTDTC DSDECOD;
RUN;

*===========================================================================================================;
*Creating DSSEQ;
*===========================================================================================================;
DATA DSS2;
	SET DSsort;
	BY USUBJID DSSTDTC DSDECOD;
	IF FIRST.USUBJID THEN DSSEQ=1;
	ELSE DSSEQ+1;
RUN;

*===========================================================================================================;
*Creating DS Dataset;
*===========================================================================================================;
PROC SQL;
	CREATE TABLE DS AS
	SELECT
	STUDYID 		"Study Identifier",
	DOMAIN 			"Domain Abbreviation",
	USUBJID			"Unique Subject Identifier",
	DSSEQ 			"Sequence Number",
	DSTERM			"Reported Term for the Disposition Event",
	DSDECOD			"Standardized Disposition Term",
	DSCAT			"Category for Disposition Event",
	DSSCAT			"Subcategory for disposition event",
	DSSTDTC			" Start Date/Time of disposition event",
	DSSTDY			"Study Day of Start of Disposition Event"
	FROM DSS2;
QUIT;

*===========================================================================================================;
/* Reviewing the created DS dataset. The original wrote DS.sas7bdat via PROC COPY
   and an RTF PROC COMPARE against the Anadata baseline at an absolute path; here
   the created DS dataset and its structure are printed so the run is self-contained. */
*===========================================================================================================;
TITLE "QC Validation For DS Dataset";
FOOTNOTE "Created DS dataset from independent SAS code";
PROC PRINT DATA=DS LABEL;
RUN;

PROC CONTENTS DATA=DS;
RUN;
TITLE;
FOOTNOTE;
