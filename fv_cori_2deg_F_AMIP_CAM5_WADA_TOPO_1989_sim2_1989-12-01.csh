#!/bin/csh

set run_time       = 00:10:00
#set queue          = regular 
#set queue          = debug 
#set priority       = premium 
## Cori after update Jan. 2018
set priority       = debug
#set priority       = premium
#set priority       = regular 
#set account        = m2840
set account         = m3306

#set run_start_date = "2008-10-01"
set run_start_date = "1989-11-21"
set start_tod      = "00000"
set Np             = 1024 
set Np_else        = 128

set rdate         = "1989-12-01"
###foreach rdate ("1989-12-01 1989-12-11 1989-12-21 1989-12-31 1990-01-10 1990-01-20 1990-01-30 1990-02-09 1990-02-19")
#### ============
## Please 1.  modify scripts/ccsm_utils/Machines/config_compilers.xml to add -DTOPOTEST
## so that the TOPO condensational heating is imcluded in this TOPO run
## 2. for year 1989 vs other years, modify the ozone prescription UltraCAM-spcam2_0_cesm1_1_1/models/atm/cam/bld/namelist_files/use_cases/hp_1850-2013_cam5.xml
## =========== 
##

## ====================================================================
#   define case
## ====================================================================

setenv CCSMTAG     UltraCAM-spcam2_0_cesm1_1_1
#setenv CASE        F_2000_CAM5_HC_TOPOTEST11_run
#setenv CASE        F_AMIP_CAM5_WADA_TOPO_1989_sim2_1989-12-01
setenv CASE        F_AMIP_CAM5_WADA_TOPO_1989_sim2_1989-12-01_HCforcing_Modi_plus_macro
#setenv CASESET     F_2000_SPCAM_sam1mom_UP
#setenv CASESET     F_2000_SPCAM_sam1mom_SP
#setenv CASESET      F_2000_CAM5
setenv CASESET      F_AMIP_CAM5
setenv CASERES     f19_g16
#setenv PROJECT     m2840
setenv PROJECT     m3306

setenv REFCASE     F_AMIP_CAM5_WADA_CTR_1989_production_sim2

## ====================================================================
#   define directories
## ====================================================================

setenv MACH      corip1 
setenv CCSMROOT  $HOME/$CCSMTAG
setenv CASEROOT  $HOME/cases/$CASE
setenv PTMP      $SCRATCH
setenv RUNDIR    $PTMP/$CASE/run
setenv ARCHDIR   $PTMP/archive/$CASE
setenv DATADIR   /global/project/projectdirs/PNNL-PJR/csm/inputdata
setenv DIN_LOC_ROOT_CSMDATA $DATADIR
#setenv mymodscam $HOME/mymods/$CCSMTAG/CAM
#mkdir -p $mymodscam

## ====================================================================
#   create new case, configure, compile and run
## ====================================================================

rm -rf $CASEROOT
rm -rf $PTMP/$CASE

#------------------
## create new case
#------------------

cd  $CCSMROOT/scripts

./create_newcase -case $CASEROOT -mach $MACH -res $CASERES -compset $CASESET -compiler intel -v

#------------------
## set environment
#------------------

cd $CASEROOT

./xmlchange  -file env_mach_pes.xml -id  NTASKS_ATM  -val=$Np
./xmlchange  -file env_mach_pes.xml -id  NTASKS_LND  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ICE  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_OCN  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_CPL  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_GLC  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  NTASKS_ROF  -val=$Np_else
./xmlchange  -file env_mach_pes.xml -id  TOTALPES    -val=$Np

set-run-opts:
cd $CASEROOT

./xmlchange  -file env_run.xml -id  RESUBMIT      -val '0'
./xmlchange  -file env_run.xml -id  STOP_N        -val '4'
./xmlchange  -file env_run.xml -id  STOP_OPTION   -val 'ndays'
./xmlchange  -file env_run.xml -id  REST_N        -val '10'
./xmlchange  -file env_run.xml -id  REST_OPTION   -val ndays       # 'nhours' 'nmonths' 'nsteps' 'nyears' 
./xmlchange  -file env_run.xml -id  RUN_STARTDATE -val $run_start_date
./xmlchange  -file env_run.xml -id  START_TOD     -val $start_tod
./xmlchange  -file env_run.xml -id  DIN_LOC_ROOT  -val $DATADIR
./xmlchange  -file env_run.xml -id  DOUT_S_ROOT   -val $ARCHDIR
./xmlchange  -file env_run.xml -id  RUNDIR        -val $RUNDIR

# for branch setting, the setting RUN_STARTDATE is ignored, just leave it there
./xmlchange  -file env_run.xml -id  RUN_TYPE    -val branch
./xmlchange  -file env_run.xml -id  RUN_REFCASE -val $REFCASE
./xmlchange  -file env_run.xml -id  RUN_REFDATE -val $rdate


./xmlchange  -file env_run.xml -id  DOUT_S_SAVE_INT_REST_FILES     -val 'TRUE'
./xmlchange  -file env_run.xml -id  DOUT_L_MS                      -val 'FALSE'

./xmlchange  -file env_run.xml -id  ATM_NCPL              -val '288'
#./xmlchange  -file env_run.xml -id  SSTICE_DATA_FILENAME  -val '/global/project/projectdirs/PNNL-PJR/csm/inputdata/atm/cam/sst/sst_HadOIBl_bc_1x1_clim_c101029.nc'

cat <<EOF >! user_nl_cam

&camexp
npr_yz = 32,2,2,32
/

&camexp
prescribed_aero_model='bulk'
/

&cam_inparm
phys_loadbalance = 2

!ncdata = '/global/u1/h/hparish/ICs/from_jerry/hp_interp_analyses/YOTC_interp_IC_files/1.9x2.5_L30_20081015_YOTC.cam2.i.2008-10-15-43200.nc'
!ncdata = '/global/u1/h/hparish/ICs/from_mike_YOTC/YOTC_interp_ICs_files/1.9x2.5_L30_Sc1_20081014_12hr_YOTC.cam2.i.2008-10-14-43200.nc'
!ncdata = '/global/u1/h/hparish/ICs/from_mike_YOTC/YOTC_interp_ICs_files/1.9x2.5_L125_Sc1_20081014_12hr_YOTC.cam2.i.2008-10-14-43200.nc'
!ncdata = '/global/u1/h/hparish/ICs/from_mike_YOTC/YOTC_interp_ICs_files/1.9x2.5_L30_Sc1_20081010_YOTC.cam2.i.2008-10-10-00000.nc'
!ncdata = '/global/u1/h/hparish/ICs/from_mike_YOTC/YOTC_interp_ICs_files/0.9x1.25_L125_20081001_12Z_YOTC.cam2.i.2008-10-01-43200.nc'
!ncdata = '/global/homes/h/hongcheq/Data/IC_files/SPCAM5/1.9x2.5_L30_20110101_ERA-I.cam2.i.2011-05-01-00000.nc'

!iradsw = 2 
!iradlw = 2
!iradae = 4 

empty_htapes = .false.

fincl2 = 'CLDICE:A','CLDLIQ:A','CLDLOW:A','CLDMED:A','CLDHGH:A','CLDTOT:A','CLOUD:A','CMFDT:A','DTCOND:A','DTV:A','FLDS:A','FLNS:A','FLNSC:A','FLNT:A','FLNTC:A','FLUT:A','FLUTC:A','FLDSC:A','FSDS:A','FSDSC:A','FSNS:A','FSNSC:A','FSNT:A','FSNTC:A','FSNTOA:A','FSNTOAC:A','FSUTOA:A','IWC:A','ICEFRAC:A','LANDFRAC:A','LHFLX:A','LWCF:A','OCNFRAC:A','OMEGA:A','OMEGAT:A','OMEGAU:A','OMEGAV:A','PBLH:A','PCONVB:A','PCONVT:A','PHIS:I','PRECC:A','PRECCDZM:A','PRECL:A','PRECSC:A','PRECSH:A','PRECSL:A','PRECT:A','PS:A','PSL:A','Q:A','QFLX:A','QREFHT:A','QRL:A','QRS:A','QT:A','QTFLX:A','RELHUM:A','RHREFHT:A','SOLIN:A','SHFLX:A','SRFRAD:A','SWCF:A','SST:A','T:A','TGCLDCWP:A','TGCLDIWP:A','TGCLDLWP:A','TKE:A','TMQ:A','TREFHT:A','TROP_P:A','TROP_PD:A','TROP_T:A','TROP_Z:A','TS:A','TTEND:A','U:A','UU:A','V:A','VV:A','VD01:A','VT:A','Z3:A','ZMDT:A',   'DTCORE:I','EVAPPREC:A','EVAPQCM:A','EVAPQZM:A','EVAPSNOW:A','EVAPTCM:A','EVAPTZM:A','HKEIHEAT:A','ZMEIHEAT:A','tten_PBL:A','TTGWORO:A','rhten_PBL:A','QAP:A','TAP:I','QBP:A','TBP:A','CLDLIQAP:A','CLDLIQBP:A','PCONVB:A','PCONVT:A','PTTEND:A','PTEQ:A','ZMMTT:A','HCforcing:A'

fincl3 = 'CLOUD:A','U:A','V:A','OMEGA:A','PBLH:A','rhten_PBL:A','tten_PBL:A','PRECT:A','PRECC:A','PRECL:A','PS:A','Q:A','RELHUM:A','T:A','TAP:I','PTTEND:A','DTV:A','DTCORE:I','QRL:A','QRS:A','DTCOND:A','TTGWORO:A','TKE:A','TS:A','Z3:A','HCforcing:A','ZMDT:A','EVAPTZM:A','ZMMTT:A','CMFDT:A','SHFLX:A',"LHFLX:A","SWCF:A","LWCF:A","FLNS:A","FSNS:A","FSDS:A","TREFHT:A"

nhtfrq = 0,-24,-1
mfilt  = 0,1,24
/
EOF

cat <<EOF >! user_nl_clm
&clmexp
hist_empty_htapes = .false.
hist_fincl2 = 'BTRAN','FCEV','FCOV','FCTR','FGEV','FGR','FGR_R','FGR_U','FIRA','FLDS',
              'FPSN','FSA','FSDS','FSH','FSH_G','FSH_R','FSH_U','FSH_V','FSNO','FSM','H2OCAN','H2OSNO','H2OSNO_TOP','H2OSOI','HC','HCSOI',
              'HK','PBOT','PSurf','Q2M','Qair','QBOT','Qanth','QCHARGE','QDRAI','QDRIP',
              'Qh','QINFL','QINTR','QIRRIG','Qle','QOVER'
              'QRGWL','QRUNOFF','QSNOMELT','QSOIL','Qstor','Qtau','QTOPSOIL','QVEGE','QVEGT','RAIN','Rainf','RH','RH2M','RH2M_R',
              'RH2M_U','Rnet','SNOW','SNOTTOPL','SNOWDP','SNOWICE','SNOWLIQ','SOILICE','SOILLIQ','SOILWATER_10CM','SWdown','SWup',
              'Tair','TAUX','TAUY','TBOT','TG','THBOT','TSA','TSA_R','TSA_U','TSOI','TV','U10','WA','WIND','WT','ZBOT','ZWT'
hist_nhtfrq = 0,-24
hist_mfilt  = 0,1
/
EOF

#---------
#cat <<EOF >! user_nl_cice
#stream_fldfilename = '/global/project/projectdirs/PNNL-PJR/csm/inputdata/atm/cam/sst/sst_HadOIBl_bc_1x1_clim_c101029.nc'
#EOF
#----------

#------------------
## configure
#------------------

config:
cd $CASEROOT
./cesm_setup
./xmlchange -file env_build.xml -id EXEROOT -val $PTMP/$CASE/bld

modify:
cd $CASEROOT
#if (-e $mymodscam) then
#    ln -s $mymodscam/* SourceMods/src.cam
#endif
#------------------
##  Interactively build the model
#------------------

build:
cd $CASEROOT
./$CASE.build

# For branch run only, put the REFCASE restart and other files into this branch case run directory
cp $PTMP/archive/$REFCASE/atm/rest/*.r*$rdate* $RUNDIR
cp $PTMP/archive/$REFCASE/cpl/rest/*.r*$rdate* $RUNDIR
cp $PTMP/archive/$REFCASE/ice/rest/*.r*$rdate* $RUNDIR
cp $PTMP/archive/$REFCASE/lnd/rest/*.r*$rdate* $RUNDIR
cp $PTMP/archive/$REFCASE/ocn/rest/*.r*$rdate* $RUNDIR

cp $PTMP/$REFCASE/run/rpointer.* $RUNDIR

cd $RUNDIR
sed -i 's/1990-03-11/'$rdate'/' rpointer.atm
sed -i 's/1990-03-11/'$rdate'/' rpointer.drv
sed -i 's/1990-03-11/'$rdate'/' rpointer.ice
sed -i 's/1990-03-11/'$rdate'/' rpointer.lnd
sed -i 's/1990-03-11/'$rdate'/' rpointer.ocn

cd  $CASEROOT
sed -i 's/^#SBATCH --time=.*/#SBATCH --time='$run_time' /' $CASE.run
#sed -i 's/^#SBATCH -p .*/#SBATCH -p '$queue' /' $CASE.run
sed -i 's/^#SBATCH -p .*/##SBATCH -p '$priority' /' $CASE.run
##2018 Cori update, see http://www.nersc.gov/users/announcements/new-policy-changes-in-allocation-year-2018/
sed -i 's/^#SBATCH --qos.*/#SBATCH -q '$priority' /' $CASE.run
sed -i 's/^#SBATCH -A .*/#SBATCH -A '$account' /' $CASE.run

cd  $CASEROOT
set bld_cmp   = `grep BUILD_COMPLETE env_build.xml`
set split_str = `echo $bld_cmp | awk '{split($0,a,"="); print a[3]}'`
set t_or_f    = `echo $split_str | cut -c 2-5`

if ( $t_or_f == "TRUE" ) then
    sbatch $CASE.run
    echo '-------------------------------------------------'
    echo '----Build and compile is GOOD, job submitted!----'
else
    set t_or_f = `echo $split_str | cut -c 2-6`
    echo 'Build not complete, BUILD_COMPLETE is:' $t_or_f
endif

# NOTE for documenting this case
cat <<EOF >> $CASEROOT/README.case

---------------------------------
USER NOTE (by hparish)
---------------------------------

--- Modifications:

EOF

