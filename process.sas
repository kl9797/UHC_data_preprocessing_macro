libname uhc "/scratch/yf31/uhc";
libname phar "/scratch/yf31/uhc/phar_dat";
libname outcome "/scratch/yf31/uhc/outcome";

data uhc.treatment;
set phar.phar_betablocker;
fill_dt = intnx('day',chk_dt,-DAYS_SUP);
keep patid fill_dt chk_dt BRND_NM;
run;

proc sql;
create table uhc.treatment as
select patid, min(fill_dt) as start, max(chk_dt) as finish
from uhc.treatment
group by patid;
format start finish mmddyy10. ;
quit;

proc sort data=uhc.med_phar_dat; by patid; run;
proc sort data=uhc.treatment; by patid; run;

data uhc.t_c;
merge uhc.med_phar_dat uhc.treatment;
by patid;
run;

data uhc.t_c;
set uhc.t_c;
if finish ne . then treatment = 1;
else treatment = 0;
call streaminit(123);
b = "01JUN2007"d;
a = "01JAN2000"d;
if missing(finish) then finish = a + floor((b-a) * rand("uniform"));
duration_1= intck('month',fst_dt,finish) ;
duration_2= intck('month',fill_dt,finish) ;
format fst_dt lst_dt fill_dt chk_dt a b start finish mmddyy10. ;
run;

data uhc.t_c;
set uhc.t_c;
where (6 >= duration_1 >= -6) or fst_dt = .;
where (18 >= duration_2 >= 0) or chk_dt = .;
format fst_dt lst_dt fill_dt chk_dt a b start finish mmddyy10. ;
run;

data uhc.t_c;
set uhc.t_c;
array var{*} DIAG1 -- DIAG5;
do i=1 to dim(var);
DIAG1 = var[i];
output;
end;
run;

data uhc.t_c;
set uhc.t_c;
if cmiss(of DIAG1) = 1 then delete;
DIAG = substr(DIAG1,1,3);
drop DIAG2 -- DIAG5 i;
run;

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
drop start finish fst_dt lst_dt chk_dt fill_dt DAYS_SUP duration_1 duration_2 a b i BRND_NM;
run;

proc sql;
create table uhc.t_c(drop=rn) as
select *,max(outcome1) as max_1, max(outcome2) as max_2, max(outcome3) as max_3, max(outcome4) as max_4, max(outcome5) as max_5, max(outcome6) as max_6, max(outcome7) as max_7, max(outcome8) as max_8, monotonic() as rn
from uhc.t_c
group by patid
order by rn;
quit;

data uhc.t_c;
set uhc.t_c;
drop outcome1 -- outcome8;
run;

proc sort data=uhc.t_c; by treatment; run;
proc freq data=uhc.t_c;
by treatment;
tables DIAG / out=uhc.treatment_freq;
run;

proc sort data=uhc.t_c; by max_1; run;
proc freq data=uhc.t_c;
by max_1;
tables DIAG / out=uhc.outcome1_freq;
run;

proc sort data=uhc.t_c; by max_2; run;
proc freq data=uhc.t_c;
by max_2;
tables DIAG / out=uhc.outcome2_freq;
run;
          
