#!/bin/tcsh
#SBATCH --output=./stdout/%x.%j
#SBATCH --job-name=C48n4
#SBATCH --clusters=c4
#SBATCH --time=00:45:00
#SBATCH --nodes=10

# change c4 to c5 and set nodes to 3 for c5
# see run_tests.sh for an example of how to run these tests
set echo

set BASEDIR    = "${SCRATCH}/${USER}/"
set INPUT_DATA = "/lustre/f2/pdata/gfdl/gfdl_W/fvGFS_INPUT_DATA/"
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
set TYPE = "nh"          # choices:  nh, hydro
if ( ! $?MODE ) then
  set MODE = "32bit"       # choices:  32bit, 64bit
endif
set MONO = "non-mono"        # choices:  mono, non-mono
set CASE = "C48n4"
set NAME = "20150801.00Z"
set MEMO = "$SLURM_JOB_NAME"
set HYPT = "on"         # choices:  on, off  (controls hyperthreading)
if ( ! $?COMP ) then
  set COMP = "repro"       # choices:  debug, repro, prod
endif
set NO_SEND = "no_send"  # choices:  send, no_send
set EXE  = x

# directory structure
set WORKDIR    = ${BASEDIR}/SHiELD_${RELEASE}/${NAME}.${CASE}.${TYPE}.${COMP}.${MODE}.${COMPILER}.${MONO}.${MEMO}/
set executable = ${BUILD_AREA}/Build/bin/SHiELD_${TYPE}.${COMP}.${MODE}.${COMPILER}.${EXE}

# sending file to gfdl
#set gfdl_archive = /archive/${USER}/SHiELD_S2S/${NAME}.${CASE}.${TYPE}.${MODE}.${MEMO}/
#set SEND_FILE = ~/Util/send_file_slurm.csh
set TIME_STAMP = ${BUILD_AREA}/site/time_stamp.csh

# input filesets
#set ICS     = ${INPUT_DATA}/variable.v201810/C48n4_okc/20150801.00Z_IC/GFS_INPUT.tar
set ICS     = ${INPUT_DATA}/variable.v201810/C48n4_okc/20150801.00Z_IC/
set FIX     = ${INPUT_DATA}/fix.v201810/
set CLIMO_DATA = ${INPUT_DATA}/climo_data.v201807/
set GFS  = ${INPUT_DATA}/GFS_STD_INPUT.20160311.tar #This should remain a tarball
set GRID = ${INPUT_DATA}/variable.v201810/C48n4_okc/GRID/

# changeable parameters
    # dycore definitions
    set npx = "49"
    set npy = "49"
    set npx_g2 = "145"
    set npy_g2 = "145"
    set npz = "63"
    set layout_x = "6"
    set layout_y = "6"
    set layout_x_g2 = "10" 
    set layout_y_g2 = "11" 
    set io_layout = "1,1"
    set io_layout_g2 = "1,1"
    set nthreads = "2"

    # blocking factor used for threading and general physics performance
    set blocksize = "36"
    set blocksize_g2 = "34"

    # run length
    set months = "0"
    set days = "2"
    set hours = "0" 
    set minutes = "0"
    set seconds = "0"
    set dt_atmos = "450"
    set nruns = "1"

    # set the pre-conditioning of the solution
    # =0 implies no pre-conditioning
    # >0 means new adiabatic pre-conditioning
    # <0 means older adiabatic pre-conditioning
    set na_init = 1

    # variables for controlling initialization of NCEP/NGGPS ICs
    set filtered_terrain = ".true."
    set ncep_plevels = ".false."
    set ncep_levs = "64"
    set gfs_dwinds = ".true."
    set n_zs_filter_nest = "1"

    # variables for gfs diagnostic output intervals and time to zero out time-accumulated data
#    set fdiag = "6.,12.,18.,24.,30.,36.,42.,48.,54.,60.,66.,72.,78.,84.,90.,96.,102.,108.,114.,120.,126.,132.,138.,144.,150.,156.,162.,168.,174.,180.,186.,192.,198.,204.,210.,216.,222.,228.,234.,240."
    set fdiag = "1."
    set fhzer = "1."
    set fhcyc = "0."

    # determines whether FV3 or GFS physics calculate geopotential
    set gfs_phil = ".false."

    # determine whether ozone production occurs in GFS physics
    set ozcalc = ".true."

    # set various debug options
    set no_dycore = ".F."
    set dycore_only = ".F." 
    set chksum_debug = ".false."
    set print_freq = "3"

    if (${TYPE} == "nh") then
      # non-hydrostatic options
      set make_nh = ".T."
      set hydrostatic = ".F."
      set phys_hydrostatic = ".F."     # can be tested
      set use_hydro_pressure = ".F."   # can be tested
      set consv_te = "1."
        # time step parameters in FV3
      set k_split = "1"
      set n_split = "6"
      set k_split_g2 = "2"
      set n_split_g2 = "12"
    else
      # hydrostatic options
      set make_nh = ".F."
      set hydrostatic = ".T."
      set phys_hydrostatic = ".F."     # will be ignored in hydro mode
      set use_hydro_pressure = ".T."   # have to be .T. in hydro mode
      set consv_te = "0."
        # time step parameters in FV3
      set k_split = "2"
      set n_split = "6"
    endif

    if (${MONO} == "mono" || ${MONO} == "monotonic") then
      # monotonic options
      set d_con = "1."
      set do_vort_damp = ".false."
      if (${TYPE} == "nh") then
        # non-hydrostatic
        set hord_mt = " 10"
        set hord_xx = " 10"
      else
        # hydrostatic
        set hord_mt = " 10"
        set hord_xx = " 10"
      endif
    else
      # non-monotonic options
      set d_con = "1."
      set do_vort_damp = ".true."
      if (${TYPE} == "nh") then
        # non-hydrostatic
        set hord_mt = " 6"
        set hord_xx = " 6"
      else
        # hydrostatic
        set hord_mt = " 10"
        set hord_xx = " 10"
      endif
    endif

    if (${MONO} == "non-mono" && ${TYPE} == "nh" ) then
      set vtdm4 = "0.06"
    else
      set vtdm4 = "0.05"
    endif

    # variables for hyperthreading
    set cores_per_node = "40"
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
    @ npes_g1 = ${layout_x} * ${layout_y} * 6
    @ npes_g2 = ${layout_x_g2} * ${layout_y_g2} 
    @ npes = ${npes_g1} + ${npes_g2}
    @ skip = ${nthreads} / ${div}
    set run_cmd = "srun --ntasks=$npes --cpus-per-task=$skip ./$executable:t"

    setenv MPICH_ENV_DISPLAY
    setenv MPICH_MPIIO_CB_ALIGN 2
    setenv MALLOC_MMAP_MAX_ 0
    setenv MALLOC_TRIM_THRESHOLD_ 536870912
    setenv NC_BLKSZ 1M
# necessary for OpenMP when using Intel
    setenv KMP_STACKSIZE 256m
    setenv SLURM_CPU_BIND verbose

\rm -rf $WORKDIR/rundir

mkdir -p $WORKDIR/rundir
cd $WORKDIR/rundir

mkdir -p RESTART


# copy over the other tables and executable
cp ${BUILD_AREA}/tables/data_table data_table
cp ${BUILD_AREA}/tables/diag_table_no3d diag_table
cp ${BUILD_AREA}/tables/field_table_6species field_table
data-table-to-yaml -f data_table
field-table-to-yaml -f field_table
cp $executable .


# build the date for curr_date and diag_table from NAME
unset echo
set y = `echo ${NAME} | cut -c1-4`
set m = `echo ${NAME} | cut -c5-6`
set d = `echo ${NAME} | cut -c7-8`
set h = `echo ${NAME} | cut -c10-11`
set echo
set curr_date = "${y},${m},${d},${h},0,0"

# build the diag_table with the experiment name and date stamp
cat >! diag_table << EOF
${NAME}.${CASE}.${MODE}.${MONO}
$y $m $d $h 0 0 
EOF
#cat ${BUILD_AREA}/tables/diag_table_hwt_test >> diag_table

mkdir -p INPUT/

# GFS standard input data
tar xf ${GFS}

# Grid and orography data
#tar xf ${GRID}
cp -rf ${GRID}/* INPUT/
 
# Date specific ICs
#tar xf ${ICS}
cp -rf ${ICS}/* INPUT/


#Nested grid fix for new files
foreach i ( $PWD/INPUT/*.tile7.nc )
    mv $i ${i:r:r}.nest02.tile7.nc
end

cp $FIX/global_sfc_emissivity_idx.txt INPUT/sfc_emissivity_idx.txt
cp INPUT/aerosol.dat .
cp INPUT/co2historicaldata_201*.txt .
cp INPUT/sfc_emissivity_idx.txt .
cp INPUT/solarconstant_noaa_an.txt .
set irun = 1

while ( $irun <= $nruns )


if ( $irun == 1 ) then

   set nggps_ic = ".T."
   set mountain = ".F."
   set external_ic = ".T."
   set warm_start = ".F."

else

   # move the restart data into INPUT/
   if ($NO_SEND == "no_send") then
    mv RESTART/* INPUT/.
   else
    ln -s $restart_file/* INPUT/.
   endif

   # reset values in input.nml for restart run
   set make_nh = ".F."
   set nggps_ic = ".F."
   set mountain = ".T."
   set external_ic = ".F."
   set warm_start = ".T."
   set n_zs_filter_nest = "0"
   set na_init = 0

endif
cp $FIX/global_sfc_emissivity_idx.txt INPUT/sfc_emissivity_idx.txt
cp INPUT/aerosol.dat .
cp INPUT/co2historicaldata_*.txt .
cp INPUT/sfc_emissivity_idx.txt .
cp INPUT/solarconstant_noaa_an.txt .

 cp $FIX/global_glacier.2x2.grb INPUT/
 cp $FIX/global_maxice.2x2.grb INPUT/
 cp $FIX/RTGSST.1982.2012.monthly.clim.grb INPUT/
 cp $FIX/global_snoclim.1.875.grb INPUT/
 cp $FIX/global_snowfree_albedo.bosu.t1534.3072.1536.rg.grb INPUT/
 cp $FIX/global_albedo4.1x1.grb INPUT/
 cp $FIX/CFSR.SEAICE.1982.2012.monthly.clim.grb INPUT/
 cp $FIX/global_tg3clim.2.6x1.5.grb INPUT/
 cp $FIX/global_vegfrac.0.144.decpercent.grb INPUT/
 cp $FIX/global_vegtype.igbp.t1534.3072.1536.rg.grb INPUT/
 cp $FIX/global_soiltype.statsgo.t1534.3072.1536.rg.grb INPUT/
 cp $FIX/global_soilmgldas.t1534.3072.1536.grb INPUT/
 cp $FIX/seaice_newland.grb INPUT/
 cp $FIX/global_shdmin.0.144x0.144.grb INPUT/
 cp $FIX/global_shdmax.0.144x0.144.grb INPUT/
 cp $FIX/global_slope.1x1.grb INPUT/
 cp $FIX/global_mxsnoalb.uariz.t1534.3072.1536.rg.grb INPUT/

unset echo

cat >! column_table <<EOF
#Use space-delineated fields (no commas)
DEBUG index  ORD  2 30 5
DEBUG index  Princeton 2 37 5
DEBUG lonlat ORD2 272. 42.
DEBUG lonlat Princeton 285.33 40.36
DEBUG lonlat NP 0. 90.
DEBUG lonlat SP 0. -90.
sonde lonlat OUN          -97.47 35.22
sonde lonlat Amarillo    -101.70 35.22
sonde lonlat DelRio      -100.92 29.37
sonde lonlat Jackson      -90.08 32.32
sonde lonlat ILX          -89.34 40.15
sonde lonlat AtlanticCity -74.56 39.45
sonde lonlat DodgeCity    -99.97 37.77
EOF

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
     chksum_debug = $chksum_debug
     dycore_only = $dycore_only
     fdiag = $fdiag
/

&diag_manager_nml
!flush_nc_files = .true.
           prepend_date = .F.
          do_diag_field_log = .T.
/

 &fms_io_nml
       checksum_required   = .false.
       max_files_r = 100,
       max_files_w = 100,
/

 &fms_nml
       clock_grain = 'ROUTINE',
       domains_stack_size = 3000000,
       print_memory_usage = .F.
/

 &fms_affinity_nml
      affinity=.false.
/

 &fv_grid_nml
       !grid_file = 'INPUT/grid_spec.nc'
/

 &fv_core_nml
       layout   = $layout_x,$layout_y
       io_layout = $io_layout
       npx      = $npx
       npy      = $npy
       ntiles   = 6,
       npz    = $npz
       !grid_type = -1
       make_nh = $make_nh
       fv_debug = .F.
       range_warn = .T.
       reset_eta = .F.
       n_sponge = 4
       nudge_qv = .T.
       rf_fast = .F.
       tau =  5.
       rf_cutoff = 8.e2
       d2_bg_k1 = 0.16
       d2_bg_k2 = 0.02
       kord_tm = -10
       kord_mt =  10
       kord_wz =  10
       kord_tr =  10
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
       fv_sg_adj = 900
       d2_bg = 0.
       nord =  2
       dddmp = 0.2
       d4_bg = 0.15 
       vtdm4 = $vtdm4
       delt_max = 0.002
       ke_bg = 0.
       do_vort_damp = $do_vort_damp
       external_ic = $external_ic
       gfs_phil = $gfs_phil
       nggps_ic = $nggps_ic
       mountain = $mountain
       ncep_ic = .F.
       d_con = $d_con
       hord_mt = $hord_mt
       hord_vt = $hord_xx
       hord_tm = $hord_xx
       hord_dp = $hord_xx
       hord_tr = 8
       adjust_dry_mass = .F.
       consv_te = $consv_te
       consv_am = .F.
       fill = .T.
       dwind_2d = .F.
       print_freq = $print_freq
       warm_start = $warm_start
       no_dycore = $no_dycore
       z_tracer = .T.

       do_schmidt = .true.
       target_lat = 35.5
       target_lon = -97.5
       stretch_fac = 1.

       write_3d_diags = .T.
/

 &integ_phys_nml
       do_inline_mp = .T.
       do_sat_adj = .F.
/

&fv_diag_column_nml
    do_diag_debug = .F.
    do_diag_sonde = .T.
    sound_freq = 3
    diag_sonde_lon_in = 121.51, 103.98, -155.05, -65.99
    diag_sonde_lat_in =  25.03,   1.36,   19.72,  18.43
    diag_sonde_names = 'Taipei', 'Singapore', 'Hilo', 'SanJuan', 
    runname = ${CASE}.${TYPE}.${MODE}.${MONO}${MEMO}
/

!&nest_nml
!    ngrids = 2
!    nest_pes = $npes_g1,$npes_g2
!    p_split = 1
!/



&fv_nest_nml
    grid_pes = $npes_g1,$npes_g2
    !grid_coarse = 0,1
    num_tile_top = 6
    tile_coarse = 0,6
    nest_refine = 0,4
    nest_ioffsets = 999,6
    nest_joffsets = 999,6
    p_split = 1
/





 &coupler_nml
       months = $months
       days  = $days
       hours = $hours
       minutes = $minutes
       seconds = $seconds
       dt_atmos = $dt_atmos
       dt_ocean = $dt_atmos
       current_date =  $curr_date
       calendar = 'julian'
       !memuse_verbose = .T.
       atmos_nthreads = $nthreads
       use_hyper_thread = $hyperthread
/

 &external_ic_nml 
       filtered_terrain = $filtered_terrain
       levp = $ncep_levs
       gfs_dwinds = $gfs_dwinds
       checker_tr = .F.
       nt_checker = 0
/


 &gfs_physics_nml
       fhzero         = $fhzer
       ldiag3d        = .false.
       fhcyc          = $fhcyc
       nst_anl        = .true.
       use_ufo        = .true.
       pre_rad        = .false.
       ncld           = 5
       zhao_mic       = .false.
       pdfcld         = .false.
       fhswr          = 3600.
       fhlwr          = 3600.
       ialb           = 1	!1
       iems           = 1	!1
       IAER           = 111
       ico2           = 2	!2
       isubc_sw       = 2	!2
       isubc_lw       = 2	!2
       isol           = 2	!2
       lwhtr          = .true.
       swhtr          = .true.
       cnvgwd         = .true.
       shal_cnv       = .true.
       cal_pre        = .false.
       redrag         = .true.
       dspheat        = .true.
       hybedmf        = .true.
       random_clds    = .false.
       trans_trac     = .true.
       cnvcld         = .false.
       imfshalcnv     = 2	!2
       imfdeepcnv     = 2	!2
       cdmbgwd        = 3.5, 0.25
       prslrd0        = 0.
       ivegsrc        = 1	!1
       isot           = 1	!1
       debug          = .false.
/

 &gfdl_mp_nml
       do_sedi_heat = .F.   
       rad_snow = .true.
       rad_graupel = .true.
       rad_rain = .true.
       const_vi = .F.
       const_vs = .F.
       const_vg = .F.
       const_vr = .F.
       vi_fac = 1.0 ! for non-constant
       vg_fac = 2.0 ! TEST: Increased
       vi_max = 3.  ! increased 
       vs_max = 6.  ! increased
       vg_max = 20. ! **Really** increased 
       vr_max = 16. ! increased 
       qi_lim = 1. ! old Fast MP
       prog_ccn = .false.
       do_qa = .true.
       tau_l2v = 180
       tau_v2l =  90.
       rthresh = 10.0e-6  ! This is a key parameter for cloud water ! use 10 for shallow conv
       dw_land  = 0.16
       dw_ocean = 0.10
       ql_gen = 1.0e-3
       qi0_crt = 1.2e-4 
       qi0_max = 2.0e-4 
       qs0_crt = 1.0e-3 ! 10x smaller, increase snow --> graupel AC
       tau_i2s = 1000.   !ice to snow autoconversion time
       c_psaci = 0.1   
       c_pgacs = 0.1 ! 100x increased rain --> graupel accretion
       rh_inc = 0.30
       rh_inr = 0.30
       rh_ins = 0.30
       ccn_l = 270. !for CONUS
       ccn_o = 90.
       z_slope_liq  = .true.
       z_slope_ice  = .true.
       fix_negative = .true.
       icloud_f = 1
       do_hail = .F.
/

  &cld_eff_rad_nml
/

  &interpolator_nml
       interp_method = 'conserve_great_circle'
/

&namsfc
       FNGLAC   = "INPUT/global_glacier.2x2.grb",
       FNMXIC   = "INPUT/global_maxice.2x2.grb",
       FNTSFC   = "INPUT/RTGSST.1982.2012.monthly.clim.grb",
       FNSNOC   = "INPUT/global_snoclim.1.875.grb",
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
EOF

cat >! input_nest02.nml <<EOF
 &amip_interp_nml
     interp_oi_sst = .true.
     use_ncep_sst = .true.
     use_ncep_ice = .false.
     no_anom_sst = .false.
     data_set = 'reynolds_oi',
     date_out_of_range = 'climo',
/

 &atmos_model_nml
     blocksize = $blocksize_g2
     chksum_debug = $chksum_debug
     dycore_only = $dycore_only
     fdiag = $fdiag
/

&diag_manager_nml
!flush_nc_files = .true.
           prepend_date = .F.
   !diag_manager_forecast_mode = .T.
/

 &fms_io_nml
       checksum_required   = .false.
       max_files_r = 100,
       max_files_w = 100,
/

 &fms_nml
       clock_grain = 'ROUTINE',
       domains_stack_size = 3000000,
       print_memory_usage = .F.
/

 &fv_grid_nml
       !grid_file = 'INPUT/grid_spec.nc'
/

 &fv_core_nml
       layout   = $layout_x_g2,$layout_y_g2
       io_layout = $io_layout_g2
       npx      = $npx_g2
       npy      = $npy_g2
       ntiles   = 1,
       npz    = $npz
       !grid_type = -1
       make_nh = $make_nh
       fv_debug = .F.
       range_warn = .T.
       reset_eta = .F.
       n_sponge = 4
       nudge_qv = .T.
       tau = 3.
       rf_cutoff = 8.e2
       d2_bg_k1 = 0.16
       d2_bg_k2 = 0.02
       kord_tm = -10
       kord_mt =  10
       kord_wz =  10
       kord_tr =  10
       hydrostatic = $hydrostatic
       phys_hydrostatic = $phys_hydrostatic
       use_hydro_pressure = $use_hydro_pressure
       beta = 0.
       a_imp = 1.
       p_fac = 0.1
       k_split  = $k_split_g2
       n_split  = $n_split_g2
       nwat = 6
       na_init = $na_init
       d_ext = 0.0
       dnats = 1
       fv_sg_adj = 900
       d2_bg = 0.
       nord =  2
       dddmp = 0.2
       d4_bg = 0.16
       vtdm4 = 0.06
       ke_bg = 0.
       do_vort_damp = .T.
       external_ic = $external_ic
       gfs_phil = $gfs_phil
       nggps_ic = $nggps_ic
       mountain = $mountain
       ncep_ic = .F.
       d_con = 0.0
       hord_mt = 5
       hord_vt = 5
       hord_tm = 5
       hord_dp = 5
       hord_tr = 8
       adjust_dry_mass = .F.
       consv_te = 0.
       consv_am = .F.
       fill = .T.
       dwind_2d = .F.
       print_freq = $print_freq
       warm_start = $warm_start
       no_dycore = $no_dycore

       !nested = .true.
       twowaynest = .true. 
       !parent_grid_num = 1
       !parent_tile = 6
       !refinement = 4
       !ioffset = 6
       !joffset = 6
       nestupdate = 7

       full_zs_filter = .F.

       !write_3d_diags = .T.

/

 &integ_phys_nml
       do_inline_mp = .T.
       do_sat_adj = .F.
/

&fv_diag_column_nml
    do_diag_debug = .F.
    do_diag_sonde = .T.
    sound_freq = 3
    !diag_debug_names = 'ORD','Princeton'
    !diag_debug_lon_in = 272.,285.33
    !diag_debug_lat_in = 42.,  40.36
    diag_sonde_names =  'OUN',  'Amarillo', 'DelRio', 'Jackson', 'ILX',  'AtlanticCity', 'DodgeCity',
    diag_sonde_lon_in = -97.47,  -101.70,    -100.92,  -90.08,   -89.34,     -74.56,       -99.97,
    diag_sonde_lat_in =  35.22,    35.22,      29.37,   32.32,    40.15,      39.45,        37.77,    
    runname = ${CASE}.${TYPE}.${MODE}.${MONO}${MEMO}
/


!&nest_nml
!    ngrids = 2
!    nest_pes = $npes_g1,$npes_g2
!    p_split = 1
!/


&surf_map_nml
    zero_ocean = .F.
    cd4 = 0.12
    cd2 = -1
    n_del2_strong = 0
    n_del2_weak = 2
    n_del4 = 1
    max_slope = 0.4
    peak_fac = 1.
/



 &coupler_nml
       months = $months
       days  = $days
       hours = $hours
       minutes = $minutes
       seconds = $seconds
       dt_atmos = $dt_atmos
       dt_ocean = $dt_atmos
       current_date =  $curr_date
       calendar = 'julian'
       memuse_verbose = .T.
       atmos_nthreads = $nthreads
       use_hyper_thread = $hyperthread
       ncores_per_node = $cores_per_node
/

 &external_ic_nml 
       filtered_terrain = $filtered_terrain
       levp = $ncep_levs
       gfs_dwinds = $gfs_dwinds
       checker_tr = .F.
       nt_checker = 0
/

 &gfs_physics_nml
       fhzero         = $fhzer
       ldiag3d        = .false.
       fhcyc          = $fhcyc
       nst_anl        = .true.
       use_ufo        = .true.
       pre_rad        = .false.
       ncld           = 5
       zhao_mic       = .false.
       pdfcld         = .false.
       fhswr          = 3600.
       fhlwr          = 3600.
       ialb           = 1	!1
       iems           = 1	!1
       IAER           = 111
       ico2           = 2	!2
       isubc_sw       = 2	!2
       isubc_lw       = 2	!2
       isol           = 2	!2
       lwhtr          = .true.
       swhtr          = .true.
       cnvgwd         = .true.
       shal_cnv       = .true.
       cal_pre        = .false.
       redrag         = .true.
       dspheat        = .true.
       hybedmf        = .true.
       random_clds    = .false.
       trans_trac     = .true.
       cnvcld         = .false.
       imfshalcnv     = 2	!2
       imfdeepcnv     = 2	!2
       cdmbgwd        = 3.5, 0.25
       prslrd0        = 0.
       ivegsrc        = 1	!1
       isot           = 1	!1
       debug          = .false.
/

 &gfdl_mp_nml
       do_sedi_heat = .F.   
       rad_snow = .true.
       rad_graupel = .true.
       rad_rain = .true.
       const_vi = .F.
       const_vs = .F.
       const_vg = .F.
       const_vr = .F.
       vi_fac = 1.0 ! for non-constant
       vg_fac = 2.0 ! TEST: Increased
       vi_max = 3.  ! increased 
       vs_max = 6.  ! increased
       vg_max = 20. ! **Really** increased 
       vr_max = 16. ! increased 
       qi_lim = 1. ! old Fast MP
       prog_ccn = .false.
       do_qa = .true.
       tau_l2v = 180
       tau_v2l =  90.
       rthresh = 10.0e-6  ! This is a key parameter for cloud water ! use 10 for shallow conv
       dw_land  = 0.16
       dw_ocean = 0.10
       ql_gen = 1.0e-3
       qi0_crt = 1.2e-4 
       qi0_max = 2.0e-4 
       qs0_crt = 1.0e-3 ! 10x smaller, increase snow --> graupel AC
       tau_i2s = 1000.   !ice to snow autoconversion time
       c_psaci = 0.1   
       c_pgacs = 0.1 ! 100x increased rain --> graupel accretion
       rh_inc = 0.30
       rh_inr = 0.30
       rh_ins = 0.30
       ccn_l = 270. !for CONUS
       ccn_o = 90.
       z_slope_liq  = .true.
       z_slope_ice  = .true.
       fix_negative = .true.
       icloud_f = 1
       do_hail = .F.
/

  &cld_eff_rad_nml
/

  &interpolator_nml
       interp_method = 'conserve_great_circle'
/

&namsfc
       FNGLAC   = "INPUT/global_glacier.2x2.grb",
       FNMXIC   = "INPUT/global_maxice.2x2.grb",
       FNTSFC   = "INPUT/RTGSST.1982.2012.monthly.clim.grb",
       FNSNOC   = "INPUT/global_snoclim.1.875.grb",
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
EOF

# run the executable

   sleep 5
   ${run_cmd} | tee fms.out
   if ( $? != 0 ) then
	exit
   endif
    @ irun++

#if ($NO_SEND == "no_send") then
#  continue
#endif

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

    foreach out (`ls *.out *.results *.nml *_table`)
      mv $out $begindate.$out
    end

    tar cvf - *\.out *\.results *\.nml *_table | gzip -c > $WORKDIR/ascii/$begindate.ascii_out.tgz

#    msub -v source=$WORKDIR/ascii/$begindate.ascii_out.tgz,destination=gfdl:$gfdl_archive/ascii/$begindate.ascii_out.tgz,extension=null,type=ascii $SEND_FILE

########################################################################
# move restart files
########################################################################

    cd $WORKDIR

    if ( ! -d $WORKDIR/restart ) mkdir -p $WORKDIR/restart

    if ( ! -d $WORKDIR/restart ) then
      echo "ERROR: $WORKDIR/restart is not a directory."
      exit
    endif

    find $WORKDIR/rundir/RESTART -iname '*.res*' > $WORKDIR/rundir/file.restart.list.txt
    set resfiles     = `wc -l $WORKDIR/rundir/file.restart.list.txt | awk '{print $1}'`

   if ( $resfiles > 0 ) then

      set dateDir = $WORKDIR/restart/$enddate
      set restart_file = $dateDir

      set list = `ls -C1 $WORKDIR/rundir/RESTART`
#      if ( $irun < $segmentsPerJob ) then
#        rm -r $workDir/INPUT/*.res*
#        foreach index ($list)
#          cp $workDir/RESTART/$index $workDir/INPUT/$index
#        end
#      endif

      if ( ! -d $dateDir ) mkdir -p $dateDir

      if ( ! -d $dateDir ) then
        echo "ERROR: $dateDir is not a directory."
        exit
      endif

      foreach index ($list)
        mv $WORKDIR/rundir/RESTART/$index $restart_file/$index
      end

#      msub -v source=$WORKDIR/restart/$enddate,destination=gfdl:$gfdl_archive/restart/$enddate,extension=tar,type=restart $SEND_FILE

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
      if ( ! -d ${begindate}_nggps3d ) mkdir -p ${begindate}_nggps3d
      mv *nggps3d*.nc* ${begindate}_nggps3d
      mv ${begindate}_nggps3d ../.
      if ( ! -d ${begindate}_tracer3d ) mkdir -p ${begindate}_tracer3d
      mv *tracer3d*.nc* ${begindate}_tracer3d
      mv ${begindate}_tracer3d ../.

    cd $WORKDIR/rundir

#    msub -v source=$WORKDIR/history/$begindate,destination=gfdl:$gfdl_archive/history/$begindate,extension=tar,type=history $SEND_FILE
#    msub -v source=$WORKDIR/history/${begindate}_nggps3d,destination=gfdl:$gfdl_archive/history/${begindate}_nggps3d,extension=tar,type=history $SEND_FILE
#    msub -v source=$WORKDIR/history/${begindate}_tracer3d,destination=gfdl:$gfdl_archive/history/${begindate}_tracer3d,extension=tar,type=history $SEND_FILE
end # while ( $irun <= $nruns )
