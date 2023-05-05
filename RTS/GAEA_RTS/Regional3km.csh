#!/bin/tcsh
#SBATCH --output=./stdout/%x.%j
#SBATCH --job-name=Regional3km
#SBATCH --clusters=c4
#SBATCH --time=00:30:00
#SBATCH --nodes=25

# change clusters to c5 and nodes to 8 to run on gaea c5
# see run_tests.sh for an example of how to run these tests

set echo

set BASEDIR    = "${SCRATCH}/${USER}/"
set INPUT_DATA = "/lustre/f2/dev/Lauren.Chilutti/Alaska_c3072"
set BUILD_AREA = "/ncrc/home1/${USER}/SHiELD_dev/SHiELD_build/"

if ( ! $?COMPILER ) then
  set COMPILER = "intel"
endif

set RELEASE = "`cat ${BUILD_AREA}/../SHiELD_SRC/release`"

source ${BUILD_AREA}/site/environment.${COMPILER}.sh

#set hires_oro_factor = 12
set res = 3072

# case specific details
set TYPE = "nh"          # choices:  nh, hydro
if ( ! $?MODE ) then
  set MODE = "32bit"      # choices:  32bit, 64bit
endif
set CASE = "C${res}_alaska"
set MONO = "non-mono"
set NAME = "20170114.00Z"
set MEMO = "$SLURM_JOB_NAME"
set HYPT = "on"         # choices:  on, off  (controls hyperthreading)
if ( ! $?COMP ) then
  set COMP = "repro"       # choices:  debug, repro, prod
endif
set NO_SEND = "no_send"  # choices:  send, no_send
set EXE = "x"
# directory structure
set WORKDIR    = ${BASEDIR}/SHiELD_${RELEASE}/${NAME}.${CASE}.${TYPE}.${COMP}.${MODE}.${COMPILER}.${MONO}.${MEMO}/
set executable = ${BUILD_AREA}/Build/bin/SHiELD_${TYPE}.${COMP}.${MODE}.${COMPILER}.${EXE}

# input filesets
set ICS  = ${INPUT_DATA}/${NAME}_IC/
set FIX  = /lustre/f2/pdata/gfdl/gfdl_W/fvGFS_INPUT_DATA/fix.v201810
set GFS  = /lustre/f2/pdata/gfdl/gfdl_W/fvGFS_INPUT_DATA/GFS_STD_INPUT.20160311.tar
set GRID = ${INPUT_DATA}/GRID/

# sending file to gfdl
#set gfdl_archive = /archive/${USER}/SHiELD_S2S/${NAME}.${CASE}.${TYPE}.${MODE}.${MONO}${MEMO}/
#set SEND_FILE = /home/${USER}/Util/send_file_slurm.csh
set TIME_STAMP = ${BUILD_AREA}/site/time_stamp.csh

# changeable parameters
    # dycore definitions
    set npx = "325" #325
    set npy = "193" #193
    set npz = "63"
    set layout_x = "39" #18
    set layout_y = "23" #16
    set io_layout = "1,1"
    set nthreads = "2"

    # blocking factor used for threading and general physics performance
    set blocksize = "33"

    # run length
    set months = "0"
    set days = "1"
    set hours = "0" 
    set minutes = "0"
    set seconds = "0"
    set dt_atmos = "60"
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
    set fhcyc = "24."

    # determines whether FV3 or GFS physics calculate geopotential
    set gfs_phil = ".false."


    # set various debug options
    set no_dycore = ".T."
    set dycore_only = ".F." # debug
    set chksum_debug = ".false."
    set print_freq = "10" # debug

    if (${TYPE} == "nh") then
      # non-hydrostatic options
      set make_nh = ".F."
      set hydrostatic = ".F."
      set phys_hydrostatic = ".F."     # can be tested
      set use_hydro_pressure = ".F."   # can be tested
      set consv_te = "1."
        # time step parameters in FV3
      set k_split = "4"
      set n_split = "5"
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
    if (${HYPT} == "on") then
      set hyperthread = ".true."
      set div = 2
    else
      set hyperthread = ".false."
      set div = 1
    endif

    @ skip = ${nthreads} / ${div}

# when running with threads, need to use the following command
    @ npes = ${layout_x} * ${layout_y}
    set run_cmd = "srun --ntasks=$npes --cpus-per-task=$skip ./$executable:t"



    setenv MPICH_ENV_DISPLAY
    setenv MPICH_MPIIO_CB_ALIGN 2
    setenv MALLOC_MMAP_MAX_ 0
    setenv MALLOC_TRIM_THRESHOLD_ 536870912
    setenv NC_BLKSZ 1M
# necessary for OpenMP when using Intel
    setenv KMP_STACKSIZE 256m

rm -rf $WORKDIR/rundir

mkdir -p $WORKDIR/rundir
cd $WORKDIR/rundir

mkdir -p RESTART

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
#this file does not exist so no diag table is being used
cat ${BUILD_AREA}/tables/diag_table_hwt_simple >> diag_table

# copy over the other tables and executable
cp ${BUILD_AREA}/tables/data_table data_table
cp ${BUILD_AREA}/tables/field_table_6species field_table
data-table-to-yaml -f data_table
field-table-to-yaml -f field_table
cp $executable .

# GFS standard input data
tar xf ${GFS} 

# Grid and orography data
cp -rf ${GRID}/* INPUT/.

#tar xf ${ICS}
#tar xf /lustre/f1/unswept/Lucas.Harris/FV3_INPUT_DATA//regional/c768regUS/20180628.00Z_IC/GFS_INPUT.tar

#Nested grid fix for new files
#foreach i ( $PWD/INPUT/*.tile7.nc )
#    ln -s $i ${i:r:r}.nest02.tile7.nc
#end

cp -rf ${ICS}/* INPUT/.

mv INPUT/sfc_data.tile7.nc INPUT/sfc_data.nc
mv INPUT/gfs_data.tile7.nc INPUT/gfs_data.nc

mv INPUT/C${res}_mosaic.nc INPUT/grid_spec.nc

cp -rf INPUT/C${res}_grid.tile7.halo3.nc INPUT/C${res}_grid.tile7.nc
cp -rf INPUT/C${res}_grid.tile7.halo4.nc INPUT/grid.tile7.halo4.nc


cp -rf INPUT/C${res}_oro_data.tile7.halo0.nc INPUT/oro_data.nc
cp -rf INPUT/C${res}_oro_data.tile7.halo4.nc INPUT/oro_data.tile7.halo4.nc



cp $FIX/global_sfc_emissivity_idx.txt INPUT/sfc_emissivity_idx.txt
cp INPUT/aerosol.dat .
cp INPUT/co2historicaldata_201*.txt .
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
  
   foreach out1 (`ls *_table`)
     set split = ($out1:as/./ /)
     mv $out1 $split[2]
   end

   # reset values in input.nml for restart run
   set make_nh = ".F."
   set nggps_ic = ".F."
   set mountain = ".T."
   set external_ic = ".F."
   set warm_start = ".T."
   set n_zs_filter_nest = "0"
   set na_init = 0

endif


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
!conserve_water = .false.
           prepend_date = .F.
! this diag table creates a lot of files
! next three lines are necessary
    max_num_axis_sets = 100 
    max_files = 100
    max_axes = 240
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

 &fms_affinity_nml
      affinity=.false.
/

 &fv_grid_nml
       grid_file = 'INPUT/grid_spec.nc' ! This line is IMPORTANT for regional model
/


 &fv_core_nml
       layout   = $layout_x,$layout_y
       io_layout = $io_layout
       npx      = $npx ! 211
       npy      = $npy ! 193
       ntiles   = 1,
       npz    = $npz
       grid_type = 5
       make_nh =  .F.
       fv_debug = .F.
       range_warn = .T.
       reset_eta = .F.
       nudge_qv = .T.
       d2_bg_k1 = 0.20
       d2_bg_k2 = 0.15
       kord_tm = -11 ! 2019: slightly better inversion structures
       kord_mt =  11
       kord_wz =  11
       kord_tr =  11
       fill = .T.     ! 2019: enabled filling negatives from remapping
       fill_gfs = .F. !2019: disabled filling negatives from GFS physics
       hydrostatic = .F.
       phys_hydrostatic = .F.
       use_hydro_pressure = .F.
       beta = 0.
       a_imp = 1.
       p_fac = 0.1
       k_split  = $k_split
       n_split  = $n_split
       nwat = 6 
       na_init =$na_init 
       d_ext = 0.0
       dnats = 2 ! 2019: improved efficiency by not advecting o3
       fv_sg_adj = 1800 ! 2019: full-domain weak 2dz damping
       n_sponge = $npz
       d2_bg = 0.
       nord =  3  
       dddmp = 0.1
       d4_bg = 0.14
       vtdm4 = 0.02
       do_vort_damp = .T.
       external_ic = $external_ic
       nggps_ic = $nggps_ic 
       hrrrv3_ic= .F.
       mountain = $mountain 
       ncep_ic = .F.
       d_con = 1.0 ! 2019: Full-strength dissipative heating
       hord_mt = 6
       hord_vt = 6
       hord_tm = 6
       hord_dp = 6
       hord_tr = -5 
       adjust_dry_mass = .F.
       consv_te = 0.
       consv_am = .F.
       dwind_2d = .F.
       print_freq = $print_freq
       warm_start = $warm_start
       no_dycore = $no_dycore

       rf_fast = .F.
       tau = 5.
       rf_cutoff = 50.e2

       delt_max = 0.002

       regional = .true.
       bc_update_interval = 6

/

 &integ_phys_nml
       do_inline_mp = .T.
       do_sat_adj = .F.
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
       ldiag3d        = .true. !2019 enabled but not used in diagnostics
       fhcyc          = $fhcyc
       nst_anl        = .true.
       use_ufo        = .true.
       pre_rad        = .false.
       ncld           = 5
       zhao_mic       = .false.
       pdfcld         = .true. !2019 enabled for new cloud-rad interactions (LJZ)
       cloud_gfdl     = .true. !2019 enabled for new cloud-rad interactions (LJZ)
       fhswr          = 1200. ! 201907: reduced
       fhlwr          = 1200. ! 201907: reduced
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
       shal_cnv       = .true. !2019 enabled with hfvGFS tuning
       clam_shal      = 0.1
       c0s_shal       = 0.01
       c1_shal        = 1.
       cal_pre        = .false.
       redrag         = .true.
       dspheat        = .true. !2019 enabled
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
       do_deep        = .false.
       do_ocean       = .true. ! 2019: Using an hfvGFS-like setting
       ysupbl         = .true. ! 201907h6: restored YSU
       xkzminv        = 0.0  ! 2019: NO diffusion in inversion layers
       xkzm_h         = 0.2  ! 2019: YSU default (note divided by 2 inside scheme)
       xkzm_m         = 0.02 ! 2019: YSU default (note divided by 2 inside scheme)
       gwd_p_crit     = 50.e2
       do_z0_hwrf17_hwonly = .true. ! 201907
       !czil_sfc       = 1.0 ! 201907: increased to warm and dry clear-sky surface (delayed for now)
       lheatstrg = .true. ! 201907b: enable canopy heat storage



/


 &ocean_nml ! 201907: from SHiELD 2019 RT
     mld_option       = "obs"
     ocean_option     = "MLM" ! Ocean mixed layer model or SOM
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
       sedi_transport = .T.  ! 2019: enabled
       do_sedi_heat = .T.    ! 2019: enabled
       do_sedi_w = .T.       ! 2019: enabled
       rad_snow = .true.
       rad_graupel = .true.
       rad_rain = .true.
       const_vi = .F.
       const_vs = .F.
       const_vg = .F.
       const_vr = .F.
       vi_max = 1.0
       vs_max = 6.
       vg_max = 12.
       vr_max = 12.
       qi_lim = 2.
       prog_ccn = .false.
       do_qa = .true.
       fast_sat_adj = .F.
       tau_l2v = 180
       tau_v2l =  22.5 ! 201907d: short timescale introduced
       tau_g2v = 900. ! 2019: increased
       rthresh = 10.0e-6
       dw_land  = 0.16
       dw_ocean = 0.10
       ql_gen = 1.0e-3
       ql_mlt = 1.0e-3 ! 2019: added
       qi0_crt = 7.5e-5 ! 2019: decreased
       qs0_crt = 1.0e-3 ! 2019: decreased
       tau_i2s = 1000.
       c_psaci = 0.05 ! 2019: decreased
       c_pgacs = 0.2  ! 2019: increased substantially; improves rainfall coverage
       c_cracw = 0.75 ! 2019: decreased
       rh_inc = 0.30
       rh_inr = 0.30
       rh_ins = 0.30
       ccn_l = 300.   ! 2019: Increased
       ccn_o = 100.   ! 2019: increased
       use_ppm = .F.  ! 2019: Disabled
       use_ccn = .true.
       z_slope_liq  = .true.
       z_slope_ice  = .true.
       de_ice = .false.
       fix_negative = .true.
       icloud_f = 0     ! 2019: enabled
       do_hail = .true. ! 2019: enabled
       do_cond_timescale = .true. ! 201984zb
mp_time = $dt_atmos
/


 &gfdl_mp_nml
       do_sedi_heat = .T.    ! 2019: enabled
       do_sedi_w = .T.       ! 2019: enabled
       rad_snow = .true.
       rad_graupel = .true.
       rad_rain = .true.
       const_vi = .F.
       const_vs = .F.
       const_vg = .F.
       const_vr = .F.
       vi_max = 1.0
       vs_max = 6.
       vg_max = 12.
       vr_max = 12.
       qi_lim = 2.
       prog_ccn = .false.
       do_qa = .true.
       tau_l2v = 180
       tau_v2l =  22.5 ! 201907d: short timescale introduced
       rthresh = 10.0e-6
       dw_land  = 0.16
       dw_ocean = 0.10
       ql_gen = 1.0e-3
       ql_mlt = 1.0e-3 ! 2019: added
       qi0_crt = 7.5e-5 ! 2019: decreased
       qs0_crt = 1.0e-3 ! 2019: decreased
       tau_i2s = 1000.
       c_psaci = 0.05 ! 2019: decreased
       c_pgacs = 0.2  ! 2019: increased substantially; improves rainfall coverage
       rh_inc = 0.30
       rh_inr = 0.30
       rh_ins = 0.30
       ccn_l = 300.   ! 2019: Increased
       ccn_o = 100.   ! 2019: increased
       z_slope_liq  = .true.
       z_slope_ice  = .true.
       fix_negative = .true.
       icloud_f = 0     ! 2019: enabled
       do_hail = .true. ! 2019: enabled
       do_cond_timescale = .true. ! 201984zb

/

  &cld_eff_rad_nml
/



 &cloud_diagnosis_nml
       ql0_max = 2.0e-3
       qi0_max = 1.0e-4
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
       rermin = 10.0
       rermax = 10000.0
       resmin = 150.0
       resmax = 10000.0
       liq_ice_combine = .false.
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

   sleep 1
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

#sbatch --export=source=$WORKDIR/ascii/$begindate.ascii_out.tgz,destination=gfdl:$gfdl_archive/ascii/$begindate.ascii_out.tgz,extension=null,type=ascii --output=$HOME/STDOUT/%x.o%j $SEND_FILE


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

    cd $WORKDIR/rundir


 #   sbatch --export=source=$WORKDIR/history/$begindate,destination=gfdl:$gfdl_archive/history/$begindate,extension=tar,type=history --output=$HOME/STDOUT/%x.o%j $SEND_FILE


end # while ( $irun <= $nruns )
