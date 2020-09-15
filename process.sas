%macro process (in_data_t= ,
                in_data_m= ,
                diag_dim= ,
                outcome_dim= ,
                fill_dt= , 
                DAYS_SUP= ,
                BRND_NM= ,
                fst_dt= ,
                lst_dt= ,
                patid= ,
                input_path_1= ;
                input_path_2= ;
                output_path= );
							
libname uhc  excel "&input_path_1";
libname phar excel "&input_path_2";
libname out excel "&output_path";

  %if %quote(&input_path_1) =  %then %do;
    %put ERROR: TEMP INPUT DIRECTORY_1 IS MISSING;
    %goto EXIT_WITH_ERROR;
  %end;
  %if %quote(&input_path_2) =  %then %do;
    %put ERROR: TEMP INPUT DIRECTORY_2 IS MISSING;
    %goto EXIT_WITH_ERROR;
  %end;
  %if %quote(&output_path) =  %then %do;
    %put ERROR: TEMP OUTPUT DIRECTORY IS MISSING;
    %goto EXIT_WITH_ERROR;
  %end;

  %if &patid = %then %do;
    %put ERROR: VAR patid IS MISSING;
    %goto EXIT_WITH_ERROR;
  %end;

  %if &in_data_t = %then %do;
    %put ERROR: INPUT TREATMENT IS MISSING;
    %goto EXIT_WITH_ERROR;
  %end;
  
  %if &in_data_m = %then %do;
    %put ERROR: INPUT COHORT IS MISSING;
    %goto EXIT_WITH_ERROR;
  %end;
  
title 'identify treatment duration';

data uhc.t_c;
set phar.&in_data_t;
&fill_dt = intnx('day',&chk_dt,-&DAYS_SUP);
keep &patid &fill_dt &chk_dt &BRND_NM;
run;

proc sql;
create table uhc.treatment as
select &patid, min(&fill_dt) as start, max(&chk_dt) as finish
from uhc.treatment
group by &patid;
format start finish mmddyy10. ;
quit;

title;

title 'filter records within effective interval';

proc sort data=uhc.&in_data_m; by &patid; run;
proc sort data=uhc.treatment; by &patid; run;

data uhc.t_c;
merge uhc.&in_data_m uhc.treatment;
by &patid;
run;

data uhc.t_c;
set uhc.t_c;
if finish ne . then treatment = 1;
else treatment = 0;
call streaminit(123);
b = "01JUN2007"d;
a = "01JAN2000"d;
if missing(finish) then finish = a + floor((b-a) * rand("uniform"));
duration_1= intck('month',&fst_dt,finish) ;
duration_2= intck('month',&fill_dt,finish) ;
format &fst_dt &lst_dt &fill_dt chk_dt a b start finish mmddyy10. ;
run;

data uhc.t_c;
set uhc.t_c;
where (6 >= duration_1 >= -6) or &fst_dt = .;
where (18 >= duration_2 >= 0) or &chk_dt = .;
format &fst_dt &lst_dt &fill_dt chk_dt a b start finish mmddyy10. ;
run;

%let m=&diag_dim; 
  data uhc.t_c;
  set uhc.t_c;
  array var{*} DIAG1 -- DIAG&m;
  do i=1 to dim(var);
  DIAG1 = var[i];
  output;
  end;
  run;

  data uhc.t_c;
  set uhc.t_c;
  if cmiss(of DIAG1) = 1 then delete;
  DIAG = substr(DIAG1,1,3);
  drop DIAG2 -- DIAG&n i;
  run;

title;

title "identify outcomes ICD-9 codes";

data uhc.t_c;
set uhc.t_c;
outcome1 = 0;
IF SUBSTR(DIAG1,1,3) in('284') or SUBSTR(DIAG1,1,4) in('2850','2858') THEN outcome1 = 1;
utcome2 = 0;
IF SUBSTR(DIAG1,1,4) in('9951','2776','4786') or SUBSTR(DIAG1,1,5) in('47825') THEN outcome2 = 1;
outcome3 = 0;
IF SUBSTR(DIAG1,1,3) in('410','411','412','413','414') THEN outcome3 = 1;
outcome4 = 0;
IF SUBSTR(DIAG1,1,3) in('821','820','808') THEN outcome4 = 1;
outcome5 = 0;
IF SUBSTR(DIAG1,1,3) in('584','585','586','587') THEN outcome5 = 1;
outcome6 = 0;
IF SUBSTR(DIAG1,1,3) in('531','532','533','534','578') THEN outcome6 = 1;
outcome7 = 0;
IF SUBSTR(DIAG1,1,4) in('5733','5722','5738','5739','7824','7904','7891') or SUBSTR(DIAG1,1,3) in ('570') THEN outcome7 = 1;
outcome8 = 0;
IF SUBSTR(DIAG1,1,3) in('578', '430', '431', '432', '853') or SUBSTR(DIAG1,1,4) in('5310', '5312', '5314', '5316', '5320', '5322', '5324', '5326', '5330', '5332', '5334', '5336', '5340', '5342', '5344', '5346', '5693', '8520', '8521', '9582', '7847', '7848', '7863', '5997', '2871', '2872', '4590') or SUBSTR(DIAG1,1,5) in('53501', '53511', '53521', '53531', '53541', '53551', '53561', '53571', '53783', '53784', '56202', '56203', '56985', '56986', '56212', '56213') THEN outcome8 = 1;
drop start finish &fst_dt &lst_dt chk_dt &fill_dt &DAYS_SUP duration_1 duration_2 a b i &BRND_NM;
run;

proc sql;
create table uhc.t_c(drop=rn) as
select *,max(outcome1) as max_1, max(outcome2) as max_2, max(outcome3) as max_3, max(outcome4) as max_4, max(outcome5) as max_5, max(outcome6) as max_6, max(outcome7) as max_7, max(outcome8) as max_8, monotonic() as rn
from uhc.t_c
group by &patid
order by rn;
quit;

data uhc.t_c;
set uhc.t_c;
drop outcome1 -- outcome8;
run;

title;

title "create frequency table";

proc sort data=uhc.t_c; by treatment; run;
proc freq data=uhc.t_c;
by treatment;
tables DIAG / out=out.treatment_freq_&in_data_t;
run;

%let n=&outcome_dim; 
%do strata= 1 %to &n;

  proc sort data=uhc.t_c; by max_&n; run;
  proc freq data=uhc.t_c;
  by max_&n;
  tables DIAG / out=out.outcome&_freq_&in_data_t;
  run;
  
%end;

title;

proc sql;
create table uhc.t_c&in_data_t as
select distinct a.*, b.GDR_CD, b.state, b.yrdob
from uhc.t_c a
inner join uhc.mbr2000_2007 b
on a.&patid = b.&patid;
quit;

%mend; 


   
