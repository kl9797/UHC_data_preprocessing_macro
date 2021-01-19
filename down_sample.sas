ibname uhc "/scratch/yf31/uhc";
libname pro "/scratch/yf31/uhc/process";

PROC SURVEYSELECT DATA=pro.betablocker_dummy OUT=pro.uhc_betablocker METHOD=SRS
  SAMPSIZE=5000000 SEED=1234567;
  RUN;
