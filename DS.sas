*===========================================================================================================;
*Establoishing Library;
*===========================================================================================================;
LIBNAME MYSNIP "/home/u63305936/Internship Series/QC of SDTM Datasets Development (DM and DS)/Work/Data_Raw";
LIBNAME  Anadata"/home/u63305936/Internship Series/QC of SDTM Datasets Development (DM and DS)/Work/Data_Analysis/SDTM";
RUN;
*===========================================================================================================;
*Generating Log;
*===========================================================================================================;
PROC PRINTTO LOG="/home/u63305936/Internship Series/QC of SDTM Datasets Development (DM and DS)/Work/Log/DS.log" New;

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
DATA  Ds_1;
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
	DSSTDTC1=INPUT(DSSTDTC,anydtdte32.);
	RFSTDTC=INPUT(_RFSTDTC,anydtdte32.);
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
*Creating a  DS.sas7bdat;
*===========================================================================================================;
PROC COPY IN=work OUT=Mysnip; 
	SELECT DS; 
RUN;

*===========================================================================================================;
*Creating RTF for the compare output;
*===========================================================================================================;
TITLE "QC Validation For DS Dataset";
FOOTNOTE "Validating Anadata DS dataset with created DS dataset";
ODS LISTING CLOSE;
ODS RTF FILE="/home/u63305936/Internship Series/QC of SDTM Datasets Development (DM and DS)/Work/Validation/DS.RTF";
PROC COMPARE BASE=Anadata.DS COMP=Work.DS LISTALL;
RUN;
ODS RTF CLOSE;
