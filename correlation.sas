libname pro "/scratch/yf31/uhc/process";

proc corr
data = pro.betablocker_dummy
OUTP = pro.betablocker_cor;
VAR treatment;
WITH DIAG_012 -- DIAG_V86 max_1 -- max_8 yrdob;
run;

PROC VARCLUS
DATA = pro.betablocker_dummy
MAXEIGEN = 0.7
MAXCLUSTERS = 337
SHORT
HI;
VAR DIAG_012 -- DIAG_V86 max_1 -- max_8 yrdob;
ODS OUTPUT
RSQUARE = pro.betablocker_cluster;
RUN;

PROC REG
DATA = pro.betablocker_dummy;
MODEL treatment = DIAG_012 -- DIAG_V86 max_1 -- max_8 yrdob / VIF;
ODS OUTPUT
PARAMETERESTIMATES = pro.betablocker_reg;
QUIT;
