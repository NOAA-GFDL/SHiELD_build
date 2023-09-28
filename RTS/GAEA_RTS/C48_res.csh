#!/bin/tcsh
#SBATCH --output=./stdout/%x.%j
#SBATCH --job-name=C48_res
#SBATCH --clusters=c4
#SBATCH --time=00:10:00
#SBATCH --nodes=6

# change c4 to c5 and set nodes to 2 for c5
# see run_tests.sh for an example of how to run these tests

set echo

set BASEDIR    = "${SCRATCH}/${USER}/"
set INPUT_DATA = "/lustre/f2/pdata/gfdl/gfdl_W/fvGFS_INPUT_DATA"
set BUILD_AREA = "/ncrc/home1/${USER}/SHiELD_dev/SHiELD_build/"

if ( ! $?COMPILER ) then
  set COMPILER = "intel"
endif

set RELEASE = "`cat ${BUILD_AREA}/../SHiELD_SRC/release`"

source ${BUILD_AREA}/site/environment.${COMPILER}.sh

#set hires_oro_factor = 3
set res = 48

set CPN = 40
# case specific details
set TYPE = "nh"         # choices:  nh, hydro
if ( ! $?MODE ) then
  set MODE = "32bit"      # choices:  32bit, 64bit
endif
set MONO = "non-mono"   # choices:  mono, non-mono
set GRID = "C$res"
set MEMO = "$SLURM_JOB_NAME" # trying prod executable
set HYPT = "on"         # choices:  on, off  (controls hyperthreading)
if ( ! $?COMP ) then
  set COMP = "repro"       # choices:  debug, repro, prod
endif
set NO_SEND = "no_send"    # choices:  send, no_send  # send option not available yet
set NUM_TOT = 4         # run cycle, 1: no restart 
if (! $?DATE) then
    set DATE=20160801.00Z
else
    echo $DATE
endif
set NAME = $DATE
set CASE = "C$res"
set EXE = "x"

# directory structure
set WORKDIR    = ${BASEDIR}/SHiELD_${RELEASE}/${NAME}.${CASE}.${TYPE}.${COMP}.${MODE}.${COMPILER}.${MONO}.${MEMO}/
set executable = ${BUILD_AREA}/Build/bin/SHiELD_${TYPE}.${COMP}.${MODE}.${COMPILER}.${EXE}

# sending file to gfdl
#set gfdl_archive = /archive/${USER}/SHiELD_S2S/${NAME}.${CASE}.${TYPE}.${MODE}.${MEMO}/
#set SEND_FILE = ~${USER}/Util/send_file_slurm.csh
set TIME_STAMP = ${BUILD_AREA}/site/time_stamp.csh

# input filesets
set ICDIR   = ${INPUT_DATA}/global.v201810/${CASE}/${NAME}_IC/  #CHECK
set ICS     = ${ICDIR}/GFS_INPUT.tar
set FIXDIR  = ${INPUT_DATA}/fix.v201810/
set CLIMO_DATA = ${INPUT_DATA}/climo_data.v201807/
set GFS_STD_INPUT  = ${INPUT_DATA}/GFS_STD_INPUT.20160311.tar #This should remain a tarball
set GRIDDIR = ${INPUT_DATA}/global.v201810/${CASE}/GRID/ #CHECK


# changeable parameters
    # dycore definitions
    set npx = "49"
    set npy = "49"
    set npz = "79"
    set layout_x = "2"
    set layout_y = "8"
    set io_layout = "1,1"
    set nthreads = "4"

    # blocking factor used for threading and general physics performance
    set blocksize = "36"

    # run length
    set months = "0"
    set days = "1"
    set hours = "0"
    set seconds = "0"
    set dt_atmos = "450"

# variables for gfs diagnostic output intervals and time to zero out time-accumulated data
#set fdiag = "6.,12.,18.,24.,30.,36.,42.,48.,54.,60.,66.,72.,78.,84.,90.,96.,102.,108.,114.,120.,126.,132.,138.,144.,150.,156.,162.,168.,174.,180.,186.,192.,198.,204.,210.,216.,222.,228.,234.,240."
set fdiag = "3.0"
set fhzer = "3.0"
set fhcyc = "24."

# determines whether FV3 or GFS physics calculate geopotential
set gfs_phil = ".false." 

# determine whether ozone production occurs in GFS physics                                         
set ozcalc = ".true."                                                                              
                                                                                                           
# set various debug options                                                                        
set no_dycore = ".false."                                                                          
set dycore_only = ".false."                                                                        
set chksum_debug = ".false."                                                                       
set print_freq = "6"         

if (${TYPE} == "nh") then
  # non-hydrostatic options
  set make_nh = ".T."
  set hydrostatic = ".F."
  set phys_hydrostatic = ".F."     # can be tested
  set use_hydro_pressure = ".F."   # can be tested
  set consv_te = "1."
  set k_split = "2"
  set n_split = "6"
else
  # hydrostatic options
  set make_nh = ".F."
  set hydrostatic = ".T."
  set phys_hydrostatic = ".F."     # will be ignored in hydro mode
  set use_hydro_pressure = ".T."   # have to be .T. in hydro mode
  set consv_te = "0."
  set k_split = "2"
  set n_split = "6"
endif

if (${MONO} == "mono" || ${MONO} == "monotonic") then                                              
  # monotonic options                                                                              
  set d_con = "1."                                                                                 
  set do_vort_damp = ".false."                                                                     
else                                                                                               
  # non-monotonic options                                                                          
  set d_con = "1."                                                                                 
  set do_vort_damp = ".true."                                                                      
endif                                                                                              


# variables for hyperthreading
set cores_per_node = $CPN
if (${HYPT} == "on") then
  set hyperthread = ".true."
  set j_opt = "-j2"
  set div = 2
else
  set hyperthread = ".false."
  set j_opt = "-j1"
  set div = 1
endif

# when running with threads, need to use the following command
    @ npes = ${layout_x} * ${layout_y} * 6
    @ skip = ${nthreads} / ${div}
    set run_cmd = "srun --ntasks=$npes --cpus-per-task=$skip ./$executable:t"

    setenv MPICH_ENV_DISPLAY
    setenv MPICH_MPIIO_CB_ALIGN 2
    setenv MALLOC_TRIM_THRESHOLD_ 536870912
    setenv NC_BLKSZ 1M
# necessary for OpenMP when using Intel
    setenv KMP_STACKSIZE 256m
    setenv SLURM_CPU_BIND verbose


set SCRIPT_AREA = $PWD
#if ( "$PBS_JOBDATE" == "BATCH" | "$PBS_JOBNAME" == "STDIN" ) then
if ( "$SLURM_JOB_NAME" == "sh" ) then
  set SCRIPT = "${SCRIPT_AREA}/$0"
else
  set SCRIPT = "${SCRIPT_AREA}/$SLURM_JOB_NAME"
endif
#set RST_COUNT = ${SCRIPT}.rst.count
mkdir -p $WORKDIR/restart
set RST_COUNT = $WORKDIR/restart/rst.count
#######DEBUG
#\rm -f $RST_COUNT
#######END DEBUG
if ( -f ${RST_COUNT} ) then
  source ${RST_COUNT}
  #set num = `cat ${RST_COUNT} | tr -d -c '[0-9]'`
  if ( x"$num" == "x" || ${num} < 1 ) then
    set RESTART_RUN = "F"
    echo " Restart = F"
  else
    set RESTART_RUN = "T"
    echo " Restart = T"
  endif
else
  set num = 0
  set RESTART_RUN = "F"
    echo " Restart = FF"
endif

#set RESTART_RUN = "F"

#NEED TO BE CAREFUL OF SETUP CODE WRT RESTARTS!!
if (${RESTART_RUN} == "F") then

  \rm -rf $WORKDIR/rundir

  mkdir -p $WORKDIR/rundir
  cd $WORKDIR/rundir

  mkdir -p RESTART
  mkdir -p INPUT

  # Date specific ICs
  cp -rf ${ICDIR}/* INPUT/

  # set variables in input.nml for initial run
  set ecmwf_ic = ".F." 
  set nggps_ic = ".T."
  set mountain = ".F."
  set external_ic = ".T."
  set warm_start = ".F."
  set na_init = 1

else

  cd $WORKDIR/rundir
  \rm -rf INPUT/*

  # move the restart data into INPUT/
  #mv RESTART/* INPUT/.
  cp -rf ${restart_dir}/coupler.res ${restart_dir}/[^0-9]*.nc ${restart_dir}/[^0-9]*.nc.???? INPUT/.

  # reset values in input.nml for restart run
  set make_nh = ".F."
  set nggps_ic = ".F."
  set ecmwf_ic = ".F."
  set mountain = ".T."
  set external_ic = ".F."
  set warm_start = ".T."
  set na_init = 0

endif
ls INPUT/
ls RESTART/

# copy over the other tables and executable
cp ${BUILD_AREA}/tables/data_table data_table
cp ${BUILD_AREA}/tables/diag_table_no3d diag_table
cp ${BUILD_AREA}/tables/field_table_6species field_table
cp $executable .

# GFS standard input data
tar xf ${GFS_STD_INPUT}

# Grid and orography data
 cp -rf ${GRIDDIR}/* INPUT/

# build the date for curr_date from DATE
set y = `echo ${DATE} | cut -c1-4`
set m = `echo ${DATE} | cut -c5-6`
set d = `echo ${DATE} | cut -c7-8`
set h = `echo ${DATE} | cut -c10-11`
set echo
set curr_date = "${y},${m},${d},${h},0,0"

# build the diag_table with the experiment name and date stamp
cat >! diag_table << EOF
${DATE}.${GRID}.${MODE}
$y $m $d $h 0 0 
EOF

rm -f $WORKDIR/rundir/INPUT/gk03_CF0.nc
cp $FIXDIR/global_sfc_emissivity_idx.txt INPUT/sfc_emissivity_idx.txt
cp INPUT/aerosol.dat .
cp INPUT/co2historicaldata_*.txt .
cp INPUT/sfc_emissivity_idx.txt .
cp INPUT/solarconstant_noaa_an.txt .

cp $FIXDIR/global_glacier.2x2.grb INPUT/
cp $FIXDIR/global_maxice.2x2.grb INPUT/
cp $FIXDIR/RTGSST.1982.2012.monthly.clim.grb INPUT/
cp $FIXDIR/global_snoclim.1.875.grb INPUT/
cp $CLIMO_DATA/mld/mld_DR003_c1m_reg2.0.grb INPUT/
cp $FIXDIR/global_snowfree_albedo.bosu.t1534.3072.1536.rg.grb INPUT/
cp $FIXDIR/global_albedo4.1x1.grb INPUT/
cp $FIXDIR/CFSR.SEAICE.1982.2012.monthly.clim.grb INPUT/
cp $FIXDIR/global_tg3clim.2.6x1.5.grb INPUT/
cp $FIXDIR/global_vegfrac.0.144.decpercent.grb INPUT/
cp $FIXDIR/global_vegtype.igbp.t1534.3072.1536.rg.grb INPUT/
cp $FIXDIR/global_soiltype.statsgo.t1534.3072.1536.rg.grb INPUT/
cp $FIXDIR/global_soilmgldas.t1534.3072.1536.grb INPUT/
cp $FIXDIR/seaice_newland.grb INPUT/
cp $FIXDIR/global_shdmin.0.144x0.144.grb INPUT/
cp $FIXDIR/global_shdmax.0.144x0.144.grb INPUT/
cp $FIXDIR/global_slope.1x1.grb INPUT/
cp $FIXDIR/global_mxsnoalb.uariz.t1534.3072.1536.rg.grb INPUT/


unset echo
cat >! input.nml <<EOF
 &amip_interp_nml
     interp_oi_sst = .true.
     use_ncep_sst = .true.
     use_ncep_ice = .false.
     no_anom_sst = .false.
     data_set = 'reynolds_oi',
     date_out_of_range = 'climo',
/

 &atmos_model_nml
     blocksize = $blocksize
     chksum_debug = .F.
     dycore_only = .F.
     fdiag = $fdiag
     first_time_step = .false.
/

 &fms_io_nml
       checksum_required   = .false.
       max_files_r = 100,
       max_files_w = 100,
/

 &fms_nml
       clock_grain = 'ROUTINE',
       domains_stack_size = 3000000,
       print_memory_usage = .false.
/

 &fms_affinity_nml
      affinity=.false.
/

 &fv_grid_nml
       grid_file = 'INPUT/grid_spec.nc'
/

 &fv_core_nml
       layout   = $layout_x,$layout_y
       io_layout = $io_layout
       npx      = $npx
       npy      = $npy
       ntiles   = 6
       npz    = $npz
       grid_type = -1
       make_nh = $make_nh
       fv_debug = .F.
       range_warn = .F.
       reset_eta = .F.
       n_sponge = 30
       nudge_qv = .T.
       rf_fast = .F.
       tau = 5.
       rf_cutoff = 7.5e2
       d2_bg_k1 = 0.15
       d2_bg_k2 = 0.02
       kord_tm = -9
       kord_mt =  9
       kord_wz =  9
       kord_tr =  9
       hydrostatic = $hydrostatic
       phys_hydrostatic = $phys_hydrostatic
       use_hydro_pressure = $use_hydro_pressure
       beta = 0.
       a_imp = 1.
       p_fac = 0.1
       k_split  = $k_split
       n_split  = $n_split
       nwat = 6
       na_init = $na_init
       d_ext = 0.0
       dnats = 1
       fv_sg_adj = 600
       d2_bg = 0.
       nord =  3
       dddmp = 0.2
       d4_bg = 0.15
       vtdm4 = 0.03
       delt_max = 0.002
       ke_bg = 0.
       do_vort_damp = $do_vort_damp
       external_ic = $external_ic
       gfs_phil = $gfs_phil
       !nggps_ic = $external_ic
       nggps_ic = $nggps_ic
       !ecmwf_ic = $ecmwf_ic
       !res_latlon_dynamics = 'INPUT/gk03_CF0.nc'
       mountain = $mountain
       ncep_ic = .F.
       d_con = $d_con
       hord_mt = 5
       hord_vt = 5
       hord_tm = 5
       hord_dp = -5
       hord_tr = -5
       adjust_dry_mass = .F.
       consv_te = $consv_te
       consv_am = .F.
       fill = .T.
       dwind_2d = .F.
       print_freq = $print_freq
       warm_start = $warm_start
       no_dycore = $no_dycore
       z_tracer = .T.
/

 &integ_phys_nml
       do_inline_mp = .T.
       do_sat_adj = .F.
/

!&fv_diag_column_nml
!    do_diag_debug = .F.
!    do_diag_sonde = .T.
!    sound_freq = 1
!    !diag_debug_names = 'ORD','Princeton'
!    !diag_debug_lon_in = 272.,285.33
!    !diag_debug_lat_in = 42.,  40.36
!    diag_sonde_names =  'OUN',  'Amarillo', 'DelRio', 'Jackson', 'ILX',  'AtlanticCity', 'DodgeCity',
!    diag_sonde_lon_in = -97.47,  -101.70,    -100.92,  -90.08,   -89.34,     -74.56,       -99.97,
!    diag_sonde_lat_in =  35.22,    35.22,      29.37,   32.32,    40.15,      39.45,        37.77,    
!    runname = ${GRID}.${MEMO}
!/


 &coupler_nml
!       debug_affinity=.true.
       months = $months
       days  = $days
       hours = $hours
       seconds = $seconds
       dt_atmos = $dt_atmos
       dt_ocean = $dt_atmos
       current_date =  $curr_date
       calendar = 'julian'
       !memuse_verbose = .false.
       atmos_nthreads = $nthreads
       use_hyper_thread = $hyperthread
!       ncores_per_node = $cores_per_node
/

 &external_ic_nml 
       filtered_terrain = .T.
       levp = 64
       gfs_dwinds = .T.
       checker_tr = .F.
       nt_checker = 0
/

 &gfs_physics_nml
       fhzero         = $fhzer
       ldiag3d        = .F.
       fhcyc          = $fhcyc
       nst_anl        = .true.
       use_ufo        = .true.
       pre_rad        = .false.
       ncld           = 5
       zhao_mic       = .false.
       pdfcld         = .false.
       fhswr          = 3600.
       fhlwr          = 3600.
       ialb           = 1
       iems           = 1
       IAER           = 111
       ico2           = 2
       isubc_sw       = 2
       isubc_lw       = 2
       isol           = 2
       lwhtr          = .true.
       swhtr          = .true.
       cnvgwd         = .true.
       do_deep        = .true.
       shal_cnv       = .true.
       cal_pre        = .false.
       redrag         = .true.
       dspheat        = .true.
       hybedmf        = .false.
       random_clds    = .false.
       trans_trac     = .true.
       cnvcld         = .false.
       imfshalcnv     = 2
       imfdeepcnv     = 2
       cdmbgwd        = 3.5, 0.25
       prslrd0        = 0.
       ivegsrc        = 1
       isot           = 1
       debug          = .false.
       ysupbl         = .true.
       xkzminv        = 1.0
       xkzm_m         = 0.001
       xkzm_h         = 0.001
       cloud_gfdl     = .false.
       do_ocean       = .true.
/

 &ocean_nml
     mld_option       = "obs"
     ocean_option     = "MLM"
     restore_method   = 2
     mld_obs_ratio    = 1.
     use_rain_flux    = .true.
     sst_restore_tscale = 2.
     start_lat        = -30.
     end_lat          = 30.
     Gam              = 0.2
     use_old_mlm      = .true.
     do_mld_restore   = .true.
     mld_restore_tscale = 2.
     stress_ratio     = 1.
     eps_day          = 10.
/



&gfdl_cloud_microphysics_nml
       sedi_transport = .true.
       do_sedi_heat = .true.
       rad_snow = .true.
       rad_graupel = .true.
       rad_rain = .true.
       const_vi = .false.
       const_vs = .false.
       const_vg = .false.
       const_vr = .false.
       vi_fac = 1.
       vs_fac = 1.
       vg_fac = 1.
       vr_fac = 1.
       vi_max = 1.
       vs_max = 2.
       vg_max = 12.
       vr_max = 12.
       qi_lim = 1.
       prog_ccn = .false.
       do_qa = .true.
       fast_sat_adj = .false.
       tau_l2v = 300.
       tau_v2l = 150.
       tau_g2v = 900.
       rthresh = 10.e-6  ! This is a key parameter for cloud water
       dw_land  = 0.16
       dw_ocean = 0.10
       ql_gen = 1.0e-3
       ql_mlt = 1.0e-3
       qi0_crt = 8.0E-5
       qs0_crt = 1.0e-3
       tau_i2s = 1000.
       c_psaci = 0.05
       c_pgacs = 0.01
       rh_inc = 0.30
       rh_inr = 0.30
       rh_ins = 0.30
       ccn_l = 300.
       ccn_o = 100.
       c_paut = 0.5
       c_cracw = 0.8
       use_ppm = .false.
       use_ccn = .true.
       z_slope_liq  = .true.
       z_slope_ice  = .true.
       de_ice = .false.
       fix_negative = .false.
       mp_time = 150.
       mono_prof= .false.

/


 &gfdl_mp_nml
       do_sedi_heat = .true.
       rad_snow = .true.
       rad_graupel = .true.
       rad_rain = .true.
       const_vi = .false.
       const_vs = .false.
       const_vg = .false.
       const_vr = .false.
       vi_fac = 1.
       vs_fac = 1.
       vg_fac = 1.
       vr_fac = 1.
       vi_max = 1.
       vs_max = 2.
       vg_max = 12.
       vr_max = 12.
       qi_lim = 1.
       prog_ccn = .false.
       do_qa = .true.
       tau_l2v = 225.
       tau_v2l = 150.
       rthresh = 10.e-6  ! This is a key parameter for cloud water
       dw_land  = 0.16
       dw_ocean = 0.10
       ql_gen = 1.0e-3
       ql_mlt = 1.0e-3
       qi0_crt = 8.0E-5
       qs0_crt = 1.0e-3
       tau_i2s = 1000.
       c_psaci = 0.05
       c_pgacs = 0.01
       rh_inc = 0.30
       rh_inr = 0.30
       rh_ins = 0.30
       ccn_l = 300.
       ccn_o = 100.
       c_paut = 0.5
       z_slope_liq  = .true.
       z_slope_ice  = .true.
       fix_negative = .false.
       icloud_f = 0
/

&cloud_diagnosis_nml
      ql0_max = 2.0e-3
      qi0_max = 2.0e-4
      ccn_o = 100.
      ccn_l = 300.
      qmin = 1.0e-12
      beta = 1.22
      rewflag = 1
      reiflag = 1
      rewmin = 5.0
      rewmax = 10.0
      reimin = 10.0
      reimax = 150.0
      liq_ice_combine = .true.
/

 &diag_manager_nml
       prepend_date = .F.
/

  &interpolator_nml
       interp_method = 'conserve_great_circle'
/

&namsfc
       FNGLAC   = "INPUT/global_glacier.2x2.grb",
       FNMXIC   = "INPUT/global_maxice.2x2.grb",
       FNTSFC   = "INPUT/RTGSST.1982.2012.monthly.clim.grb",
       FNSNOC   = "INPUT/global_snoclim.1.875.grb",
       FNMLDC   = "INPUT/mld_DR003_c1m_reg2.0.grb",
       FNZORC   = "igbp",
       FNALBC   = "INPUT/global_snowfree_albedo.bosu.t1534.3072.1536.rg.grb",
       FNALBC2  = "INPUT/global_albedo4.1x1.grb",
       FNAISC   = "INPUT/CFSR.SEAICE.1982.2012.monthly.clim.grb",
       FNTG3C   = "INPUT/global_tg3clim.2.6x1.5.grb",
       FNVEGC   = "INPUT/global_vegfrac.0.144.decpercent.grb",
       FNVETC   = "INPUT/global_vegtype.igbp.t1534.3072.1536.rg.grb",
       FNSOTC   = "INPUT/global_soiltype.statsgo.t1534.3072.1536.rg.grb",
       FNSMCC   = "INPUT/global_soilmgldas.t1534.3072.1536.grb",
       FNMSKH   = "INPUT/seaice_newland.grb",
       FNTSFA   = "",
       FNACNA   = "",
       FNSNOA   = "",
       FNVMNC   = "INPUT/global_shdmin.0.144x0.144.grb",
       FNVMXC   = "INPUT/global_shdmax.0.144x0.144.grb",
       FNSLPC   = "INPUT/global_slope.1x1.grb",
       FNABSC   = "INPUT/global_mxsnoalb.uariz.t1534.3072.1536.rg.grb",
       LDEBUG   =.false.,
       FSMCL(2) = 99999
       FSMCL(3) = 99999
       FSMCL(4) = 99999
       FTSFS    = 90
       FAISS    = 99999
       FSNOL    = 99999
       FSICL    = 99999
       FTSFL    = 99999,
       FAISL    = 99999,
       FVETL    = 99999,
       FSOTL    = 99999,
       FvmnL    = 99999,
       FvmxL    = 99999,
       FSLPL    = 99999,
       FABSL    = 99999,
       FSNOS    = 99999,
       FSICS    = 99999,
/

  &cld_eff_rad_nml
/

EOF

# run the executable
${run_cmd} | tee fms.out || exit
@ num ++
echo "set num = ${num}" >! ${RST_COUNT}

#########################################################################
# generate date for file names
########################################################################

set begindate = `$TIME_STAMP -bhf digital`
if ( $begindate == "" ) set begindate = tmp`date '+%j%H%M%S'`

set enddate = `$TIME_STAMP -ehf digital`
if ( $enddate == "" ) set enddate = tmp`date '+%j%H%M%S'`
set fyear = `echo $enddate | cut -c -4`

cd $WORKDIR/rundir
cat time_stamp.out

########################################################################
# save ascii output files
########################################################################

if ( ! -d $WORKDIR/ascii ) mkdir $WORKDIR/ascii
if ( ! -d $WORKDIR/ascii ) then
 echo "ERROR: $WORKDIR/ascii is not a directory."
 exit 1
endif

mkdir -p $WORKDIR/ascii/$begindate
foreach out (`ls *.out *.results input*.nml *_table`)
  mv $out $WORKDIR/ascii/$begindate/
end

cd $WORKDIR/ascii/$begindate
tar cvf - *\.out *\.results | gzip -c > $WORKDIR/ascii/$begindate.ascii_out.tgz

#if ($NO_SEND == "send") sbatch --export=source=$WORKDIR/ascii/$begindate.ascii_out.tgz,destination=gfdl:$gfdl_archive/ascii/$begindate.ascii_out.tgz,extension=null,type=ascii $SEND_FILE

########################################################################
# move restart files
########################################################################

cd $WORKDIR

#if ( ! -d $WORKDIR/restart ) mkdir -p $WORKDIR/restart

if ( ! -d $WORKDIR/restart ) then
  echo "ERROR: $WORKDIR/restart is not a directory."
  exit
endif

set resfile_list = $WORKDIR/rundir/file.restart.list.txt
find $WORKDIR/rundir/RESTART -iname '*.res*' >! $resfile_list
find $WORKDIR/rundir/RESTART -iname '*_data*' >> $resfile_list
set resfiles     = `wc -l $resfile_list | awk '{print $1}'`

if ( $resfiles > 0 ) then

  set dateDir = $WORKDIR/restart/$enddate
  set restart_dir = $dateDir

  if ( ! -d $dateDir ) mkdir -p $dateDir

  if ( ! -d $dateDir ) then
    echo "ERROR: $dateDir is not a directory."
    exit
  endif

  xargs mv -t $restart_dir < $resfile_list
  echo "set restart_dir = $restart_dir" >> $RST_COUNT

#  if ($NO_SEND == "send") sbatch --export=source=$WORKDIR/restart/$enddate,destination=gfdl:$gfdl_archive/restart/$enddate,extension=tar,type=restart $SEND_FILE

endif


########################################################################
# move history files
########################################################################

cd $WORKDIR

if ( ! -d $WORKDIR/history ) mkdir -p $WORKDIR/history
if ( ! -d $WORKDIR/history ) then
  echo "ERROR: $WORKDIR/history is not a directory."
  exit 1
endif

set dateDir = $WORKDIR/history/$begindate
if ( ! -d  $dateDir ) mkdir $dateDir
if ( ! -d  $dateDir ) then
  echo "ERROR: $dateDir is not a directory."
  exit 1
endif

find $WORKDIR/rundir -maxdepth 1 -type f -regex '.*.nc'      -exec mv {} $dateDir \;
find $WORKDIR/rundir -maxdepth 1 -type f -regex '.*.nc.....' -exec mv {} $dateDir \;

cd $dateDir

#sbatch --export=source=$WORKDIR/history/${begindate},destination=gfdl:$gfdl_archive/history/${begindate},extension=untar,type=history $SEND_FILE


cd $WORKDIR/rundir


if ($num < $NUM_TOT) then
  echo "resubmitting... "
  if ( "$SLURM_JOB_NAME" == "sh" ) then
   cd $SCRIPT_AREA
    ./$SCRIPT:t
  else
    cd $SCRIPT_AREA
    #sbatch --export=ALL,DATE=${DATE} $SCRIPT:t
    #sbatch -J ${DATE}.`basename $SLURM_JOB_NAME` --export=ALL,DATE=${DATE} $SCRIPT:t
  echo "sleeping ... "
    sleep 20
  endif
endif
