libname uhc "/scratch/yf31/uhc";

proc sort data=uhc.t_c; by treatment; run;
proc freq data=uhc.t_c;
by treatment;
tables DIAG / out=uhc.treatment_freq;
run;
proc sort data=uhc.treatment_freq;
by descending count;
run;

data uhc.treatment_freq_1;
    set uhc.treatment_freq;
    rename count = count_1 percent = percent_1 treatment = treatment_1;
    if (treatment = 1) then output;
run;

data uhc.treatment_freq_0;
    set uhc.treatment_freq;
    if (treatment = 0) then output;
run;

proc sort data=uhc.treatment_freq_1; by DIAG; run;
proc sort data=uhc.treatment_freq_0; by DIAG; run;
data uhc.treatment_freq_merge;
merge uhc.treatment_freq_1 uhc.treatment_freq_0;
by DIAG;
RR = percent_1 / percent;
drop count_1 COUNT;
run;
