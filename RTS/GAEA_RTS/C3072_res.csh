#!/bin/tcsh
#SBATCH --output=./stdout/%x.%j
#SBATCH --job-name=X-SHiELD
#SBATCH --clusters=c4
#SBATCH --time=03:00:00
#SBATCH --nodes=331
#SBATCH --exclusive

# change c4 to c5 and set nodes to 93 for c5
# see run_tests.sh for an example of how to run these tests

set echo

set BASEDIR    = "${SCRATCH}/${USER}/"
set INPUT_DATA = "/lustre/f2/pdata/gfdl/gfdl_W/fvGFS_INPUT_DATA"
set BUILD_AREA = "/ncrc/home1/${USER}/SHiELD_dev/SHiELD_build/"

if ( ! $?COMPILER ) then
  set COMPILER = "intel"
endif

set RELEASE = "`cat ${BUILD_AREA}/../SHiELD_SRC/release`"

#set hires_oro_factor = 3
set res = 3072

set CPN = 40
# case specific details
set TYPE = "nh"         # choices:  nh, hydro
if ( ! $?MODE ) then
  set MODE = "32bit"      # choices:  32bit, 64bit
endif
set GRID = "C$res"
set MONO = "non-mono"   # choices:  mono, non-mono
set MEMO = "$SLURM_JOB_NAME" # trying prod executable
set HYPT = "on"         # choices:  on, off  (controls hyperthreading)
if ( ! $?COMP ) then
  set COMP = "repro"       # choices:  debug, repro, prod
endif
set NO_SEND = "no_send"    # choices:  send, no_send  # send option not available yet
set NUM_TOT = 8         # run cycle, 1: no restart # z2: increased
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
set gfdl_archive = /archive/${USER}/SHiELD_S2S/${NAME}.${CASE}.${TYPE}.${MODE}.${MEMO}/
set SEND_FILE = /home/jmoualle/Util/send_file_slurm.csh
set TIME_STAMP = /home/jmoualle/Util/time_stamp.csh


# input filesets
set ICDIR   = ${INPUT_DATA}/global.v202003/${GRID}_smooth/${DATE}_IC/  #CHECK
set ICS     = ${ICDIR}/GFS_INPUT.tar
set FIXDIR  = ${INPUT_DATA}/fix.v201810/
set CLIMO_DATA = ${INPUT_DATA}/climo_data.v201807/
set GFS_STD_INPUT  = ${INPUT_DATA}/GFS_STD_INPUT.20160311.tar #This should remain a tarball
set GRIDDIR = ${INPUT_DATA}/global.v202003/${GRID}_smooth/GRID/ #CHECK


# changeable parameters
    # dycore definitions
    set npx = "3073"
    set npy = "3073"
    set npz = "79"
    set layout_x = "32" 
    set layout_y = "62" 
    set io_layout = "2,2" #Want to increase this in a production run??
    set nthreads = "2"

    # blocking factor used for threading and general physics performance
    set blocksize = "32"

    # run length
    set months = "0"
    set days = "1" 
    set hours = "0"
    set seconds = "0"
    set dt_atmos = "180"  # z12: decreased

# variables for gfs diagnostic output intervals and time to zero out time-accumulated data
#set fdiag = "6.,12.,18.,24.,30.,36.,42.,48.,54.,60.,66.,72.,78.,84.,90.,96.,102.,108.,114.,120.,126.,132.,138.,144.,150.,156.,162.,168.,174.,180.,186.,192.,198.,204.,210.,216.,222.,228.,234.,240."
set fdiag = "3.0"
set fhzer = "3.0"
set fhcyc = "24."

if (${TYPE} == "nh") then
  # non-hydrostatic options
  set make_nh = ".T."
  set hydrostatic = ".F."
  set phys_hydrostatic = ".F."     # can be tested
  set use_hydro_pressure = ".F."   # can be tested
  set consv_te = "1."
else
  # hydrostatic options
  set make_nh = ".F."
  set hydrostatic = ".T."
  set phys_hydrostatic = ".F."     # will be ignored in hydro mode
  set use_hydro_pressure = ".T."   # have to be .T. in hydro mode
  set consv_te = "0."
endif

# variables for hyperthreading
set cores_per_node = $CPN
if (${HYPT} == "on") then
  set hyperthread = ".true."
  set div = 2
else
  set hyperthread = ".false."
  set div = 1
endif
@ skip = ${nthreads} / ${div}

# when running with threads, need to use the following command
    @ npes = ${layout_x} * ${layout_y} * 6
    set run_cmd = "srun --ntasks=$npes --cpus-per-task=$skip ./$executable:t"

    setenv MPICH_ENV_DISPLAY
    setenv MPICH_MPIIO_CB_ALIGN 2
    setenv MALLOC_MMAP_MAX_ 0
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
  else
    set RESTART_RUN = "T"
  endif
else
  set num = 0
  set RESTART_RUN = "F"
endif

set RESTART_RUN = "F"

#NEED TO BE CAREFUL OF SETUP CODE WRT RESTARTS!!
if (${RESTART_RUN} == "F") then

  \rm -rf $WORKDIR/rundir

  mkdir -p $WORKDIR/rundir
  cd $WORKDIR/rundir

  mkdir -p RESTART
  mkdir -p INPUT

  # Date specific ICs
  #tar xf ${ICS}
  #if ( -e ${ICS} ) then
  if ( -e ${ICDIR}/gfs_data.tile1.nc ) then
    ln -s ${ICDIR}/* INPUT/
  else
    tar xf ${ICS}
  endif

  # set variables in input.nml for initial run
  set ecmwf_ic = ".F." 
  set mountain = ".F."
  set external_ic = ".T."
  set warm_start = ".F."
  set na_init = 1

else

  cd $WORKDIR/rundir
  \rm -rf INPUT/*

  # move the restart data into INPUT/
  #mv RESTART/* INPUT/.
  ln -s ${restart_dir}/coupler.res ${restart_dir}/[^0-9]*.nc ${restart_dir}/[^0-9]*.nc.???? INPUT/.

  # reset values in input.nml for restart run
  set make_nh = ".F."
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
cp ${BUILD_AREA}/tables/field_table_6species_tke_clock field_table  # Clock tracers started 10 days after initialization
cp $executable .

# GFS standard input data
tar xf ${GFS_STD_INPUT}

# Grid and orography data
 ln -sf ${GRIDDIR}/* INPUT/

# build the date for curr_date from DATE
unset echo
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
### xic: please verify your diag table is consistent with DYAMOND protocal
cat ${BUILD_AREA}/tables/diag_table_hwt_dyamond >> diag_table

rm -f $WORKDIR/rundir/INPUT/gk03_CF0.nc
cp $FIXDIR/global_sfc_emissivity_idx.txt INPUT/sfc_emissivity_idx.txt
cp INPUT/aerosol.dat .
cp INPUT/co2historicaldata_201*.txt .
cp INPUT/sfc_emissivity_idx.txt .
cp INPUT/solarconstant_noaa_an.txt .

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
       domains_stack_size = 16000000,
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
       npz_type = 'gcrm'
       grid_type = -1
       make_nh = $make_nh
       fv_debug = .F.
       range_warn = .T.
       reset_eta = .F.
       !n_sponge = 48 
       sg_cutoff = 200.e2 ! z12: replaced n_sponge
       nudge_qv = .T.
       RF_fast = .T.
       tau_h2o = 0.
       tau = 5. ! z12: decreased (now increased to 5 again)
       rf_cutoff = 30.e2
!  do_f3d = .F.
       d2_bg_k1 = 0.20
       d2_bg_k2 = 0.10 ! z2: increased
       kord_tm = -9
       kord_mt = 9
       kord_wz = 9
       kord_tr = 9
       hydrostatic = $hydrostatic
       phys_hydrostatic = $phys_hydrostatic
       use_hydro_pressure = $use_hydro_pressure
       beta = 0.
       a_imp = 1.
       p_fac = 0.05
       k_split = 5 !z12: adjusted for dt_atmos = 180 (mdt = 36 s)
       n_split = 8 !z12: increased (dt = 4.5 s)
       nwat = 6 
       na_init = $na_init
       d_ext = 0.0
       dnats = 1
       fv_sg_adj = 600 ! z12: decreased further (now restored to 600---improves stability?)
       d2_bg = 0.
       nord = 3 ! z8: 2 --> 3
       dddmp = 0.5 
       d4_bg = 0.15 ! z8: increased with nord change
       vtdm4 = 0.06 ! z10: increased
       delt_max = 0.002
       ke_bg = 0.
       do_vort_damp = .T.
       external_ic = $external_ic
       gfs_phil = .F.
       nggps_ic = $external_ic
       !ecmwf_ic = $ecmwf_ic
       !res_latlon_dynamics = 'INPUT/gk03_CF0.nc'
       mountain = $mountain
       ncep_ic = .F.
       d_con = 1.
       hord_mt = 5
       hord_vt = 5
       hord_tm = 5
       hord_dp = -5
       hord_tr = -5 ! z2: changed
       adjust_dry_mass = .F.
       consv_te = 0.
       consv_am = .F.
       fill = .T.
       dwind_2d = .F.
       print_freq = 1
       warm_start = $warm_start
       z_tracer = .T.
       fill_dp = .T. 

/

 &integ_phys_nml
       do_sat_adj = .F.
       do_inline_mp = .T.
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
       ldiag3d        = .true.
       fhcyc          = $fhcyc
       nst_anl        = .true.
       use_ufo        = .true.
       pre_rad        = .false.
       ncld           = 5
       zhao_mic       = .false.
       pdfcld         = .false. ! z11a: disabled
       cloud_gfdl     = .false. ! z11a: disabled
       fhswr          = 1800.
       fhlwr          = 1800.
       ialb           = 1
       iems           = 1
       IAER           = 111
       ico2           = 2
       isubc_sw       = 2
       isubc_lw       = 2
       isol           = 2
       lwhtr          = .true.
       swhtr          = .true.
       cnvgwd         = .false.
       shal_cnv       = .true.
       !parameters....
       c0s_shal = 0.01   ! default=0.002
       c1_shal  = 0.005  ! default=5.e-4 
!      asolfac_shal = 0.85    ! c0_land_shal = c0s_shal * asolfac_shal
!       clam_shal = 0.3 ! z2: disabled (causes stability problems??)
       do_deep = .false.
       cal_pre        = .false.
       redrag         = .true.
       dspheat        = .true. ! z11 enabled
       hybedmf        = .true.
       satmedmf       = .false. ! z11 enabled
       isatmedmf       = 1 !z11c updated version of TKE-EDMF
       random_clds    = .false.
       trans_trac     = .true.
       cnvcld         = .false.
       imfshalcnv     = 2
       imfdeepcnv     = 2
       cdmbgwd        = 0.0, 0.0 ! z11 disabled
       prslrd0        = 0.
       ivegsrc        = 1
       isot           = 1
       debug          = .F.
       xkzminv        = 0.0 ! z12: Using stronger diffusion
    do_ocean  = .T.
    !use_ec_sst     = .T.
       !gwd_p_crit     = 20.e2 ! z11 unnecessary
    cloud_gfdl = .T.
/

  &ocean_nml !z2: using Yongqiang/Kun's MJO settings

     mld_option       = "obs"
     ocean_option     = "MLM"
     restore_method   = 1 ! z2: to climatology not anomalies
     mld_obs_ratio    = 1.
     use_rain_flux    = .true.
     sst_restore_tscale = 15.
     start_lat        = -45. !z2: higher latitude
     end_lat          = 45.
     Gam              = 0.12
     use_old_mlm      = .true.
     do_mld_restore   = .true.
     mld_restore_tscale = 15.
     stress_ratio     = 0.75
     eps_day          = 10.
/

 &gfdl_mp_nml
       do_sedi_heat = .F.
       do_sedi_w = .T.
       rad_snow = .true.
       rad_graupel = .true.
       rad_rain = .true.
       const_vi = .F.
       const_vs = .F.
       const_vg = .F.
       const_vr = .F.
       vi_max = 1.
       vs_max = 2.
       vg_max = 16.
       vr_max = 16.
       qi_lim = 1.
       prog_ccn = .false.
       do_qa = .true.
       tau_l2v = 300.
       tau_v2l = 90. ! z7: enabled
       do_cond_timescale = .true. ! z7: enabled
       rthresh = 10.e-6  !   10.e-6  ! This is a key parameter for cloud water
      dw_land  = 0.15
      dw_ocean = 0.10
       ql_gen = 1.0e-3
    ql_mlt = 2.0e-3
    qs_mlt = 1.e-6
       qi0_crt = 8.E-5
       qs0_crt = 3.0e-3
       tau_i2s = 1000.
       c_psaci = 0.05
       c_pgacs = 0.01
       rh_inc = 0.20
       rh_inr = 0.30
       rh_ins = 0.30
       ccn_l = 300.
       ccn_o = 100.
       c_paut =  0.5
       z_slope_liq  = .T.
       z_slope_ice  = .T.
       fix_negative = .true.
       irain_f = 0
       icloud_f = 0
/

!# From LJZ mar 2019
 &cloud_diagnosis_nml
       reiflag        = 4 
        rewmin = 5.0
        rewmax = 10.0
        reimin = 10.0
        reimax = 150.0
/


! &cloud_diagnosis_nml
!       ql0_max = 2.0e-3
!       qi0_max = 2.0e-4
!       ccn_o = 100.
!       ccn_l = 300.
!       qmin = 1.0e-12
!       beta = 1.22
!       rewflag = 1
!       reiflag = 4
!       rewmin = 5.0
!       rewmax = 10.0
!       reimin = 10.0
!       reimax = 150.0
!       liq_ice_combine = .true.
!/

 &diag_manager_nml 
!      flush_nc_files = .false.
       prepend_date = .F.
       max_num_axis_sets = 100
       max_files = 106
       max_axes = 240
/

  &interpolator_nml
       interp_method = 'conserve_great_circle'
/

&namsfc
       FNGLAC   = "$FIXDIR/global_glacier.2x2.grb",
       FNMXIC   = "$FIXDIR/global_maxice.2x2.grb",
       FNTSFC   = "$FIXDIR/RTGSST.1982.2012.monthly.clim.grb",
       FNSNOC   = "$FIXDIR/global_snoclim.1.875.grb",
       FNMLDC   = "$CLIMO_DATA/mld/mld_DR003_c1m_reg2.0.grb",
       FNZORC   = "igbp",
       FNALBC   = "$FIXDIR/global_snowfree_albedo.bosu.t1534.3072.1536.rg.grb",
       FNALBC2  = "$FIXDIR/global_albedo4.1x1.grb",
       FNAISC   = "$FIXDIR/CFSR.SEAICE.1982.2012.monthly.clim.grb",
       FNTG3C   = "$FIXDIR/global_tg3clim.2.6x1.5.grb",
       FNVEGC   = "$FIXDIR/global_vegfrac.0.144.decpercent.grb",
       FNVETC   = "$FIXDIR/global_vegtype.igbp.t1534.3072.1536.rg.grb",
       FNSOTC   = "$FIXDIR/global_soiltype.statsgo.t1534.3072.1536.rg.grb",
       FNSMCC   = "$FIXDIR/global_soilmgldas.t1534.3072.1536.grb",
       FNMSKH   = "$FIXDIR/seaice_newland.grb",
       FNTSFA   = "",
       FNACNA   = "",
       FNSNOA   = "",
       FNVMNC   = "$FIXDIR/global_shdmin.0.144x0.144.grb",
       FNVMXC   = "$FIXDIR/global_shdmax.0.144x0.144.grb",
       FNSLPC   = "$FIXDIR/global_slope.1x1.grb",
       FNABSC   = "$FIXDIR/global_mxsnoalb.uariz.t1534.3072.1536.rg.grb",
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

if ($NO_SEND == "send") sbatch --export=source=$WORKDIR/ascii/$begindate.ascii_out.tgz,destination=gfdl:$gfdl_archive/ascii/$begindate.ascii_out.tgz,extension=null,type=ascii $SEND_FILE

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

  if ($NO_SEND == "send") sbatch --export=source=$WORKDIR/restart/$enddate,destination=gfdl:$gfdl_archive/restart/$enddate,extension=tar,type=restart $SEND_FILE

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
    sleep 60
  endif
endif
