libname pro "/scratch/yf31/uhc/process";

data pro.betablocker_ipw;
set pro.betablocker_dummy;
keep DIAG_786 DIAG_272 DIAG_401 DIAG_729 DIAG_250 DIAG_787 DIAG_V58 DIAG_599 DIAG_784 DIAG_530 DIAG_722 DIAG_726 DIAG_715 DIAG_244 DIAG_414 DIAG_785 DIAG_790 DIAG_427 DIAG_733 DIAG_702 DIAG_285 DIAG_627 DIAG_366 DIAG_564 DIAG_276 DIAG_110 DIAG_346 DIAG_238 DIAG_793 DIAG_794 DIAG_518 DIAG_211 DIAG_V45 DIAG_365 DIAG_424 DIAG_600 DIAG_562 DIAG_721 DIAG_V67 DIAG_362 max_1 max_2 max_3 max_4 max_5 max_6 max_7 max_8 yrdob GDR_CD state patid treatment;
run;

data pro.betablocker_ipw;
set pro.betablocker_ipw;
if GDR_CD = "F" then gender = 1;
if GDR_CD = "M" then gender = 0;

proc logistic descending data = pro.betablocker_ipw;
 title ?~@~XPropensity Score Estimation?~@~Y;
 model treatment = DIAG_110 -- DIAG_V67 max_1 -- max_8 yrdob gender/lackfit outroc = pro.ps_r;
 output out= pro.ps_p XBETA=ps_xb STDXBETA= ps_sdxb PREDICTED = ps_pred;
run;

proc rank data = pro.ps_p out= pro.ps_strataranks groups=5;
 var ps_pred;
 ranks ps_pred_rank;
run;

proc sort data = pro.ps_strataranks;
by ps_pred_rank;

/*inverse probability weighting*/

data pro.ps_weight;
set pro.ps_p;
if treatment = 1 then ps_weight = 1/ps_pred;
else ps_weight = 1/(1-ps_pred);
run;
proc means noprint data = pro.ps_weight;
var ps_weight;
output out = pro.q mean = mn_wt;
run;
data pro.ps_weight2;
if _n_ = 1 then set pro.q;
retain mn_wt;
set pro.ps_weight;
 wt2 = ps_weight/mn_wt; * Normalized weight;
run;

proc reg data = pro.ps_weight2 outest=pro.estimate;
model max_1 = treatment;
model max_2 = treatment;
model max_3 = treatment;
model max_4 = treatment;
model max_5 = treatment;
model max_6 = treatment;
model max_7 = treatment;
model max_8 = treatment;
weight wt2;
run;

