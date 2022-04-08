#!/bin/tcsh
#SBATCH --output=/home/jmoualle/ORION_RT/stdout/%x.%j
#SBATCH --job-name=C768r15n3
#SBATCH -A gfdlhires
#SBATCH --partition=orion
#SBATCH --time=00:20:00
#SBATCH --nodes=74
#SBATCH --exclusive
#SBATCH --mail-user=joseph.mouallem@noaa.gov
#SBATCH --mail-type=ALL

source ${MODULESHOME}/init/tcsh
module load intel/2020
module load netcdf/
module load hdf5/
module load impi/2020
set echo

set WORKDIR = "/work/noaa/gfdlscr/${USER}/"

set BASEDIR    = "$WORKDIR"
set INPUT_DATA = "/work/noaa/gfdlscr/pdata/gfdl/SHiELD/INPUT_DATA/"
set INPUT_DATA1 = "/work/noaa/gfdlscr/pdata/gfdl/SHiELD/INPUT_DATA1/"
# from YQS
set BUILD_AREA = "/home/${USER}/SHiELD_Lucas/SHiELD_build/"

# release number for the script
set RELEASE = "SHiELD_FMS2020.02"

# case specific details
set TYPE = "nh"         # choices:  nh, hydro
set MODE = "32bit"      # choices:  32bit, 64bit
set MONO = "non-mono"   # choices:  mono, non-mono
set CASE = "C768r15n3_hwt"
set NAME = "20170501.00Z"
set MEMO = "$SLURM_JOB_NAME"
set HYPT = "on"         # choices:  on, off  (controls hyperthreading)
set COMP = "repro"       # choices:  debug, repro, prod
set NO_SEND = "no_send"    # choices:  send, no_send
set EXE = "x"
# directory structure
set WORKDIR    = ${BASEDIR}/${RELEASE}/${NAME}.${CASE}.${TYPE}.${MODE}.${MONO}${MEMO}/
set executable = ${BUILD_AREA}/Build/bin/SHiELD_${TYPE}.${COMP}.${MODE}.${EXE}

# input filesets
set ICS  = ${INPUT_DATA1}/variable.v201810/${CASE}/${NAME}_IC/GFS_INPUT.tar
set FIX  = ${INPUT_DATA}/fix.v201810/
set GFS  = ${INPUT_DATA}/GFS_STD_INPUT.20160311.tar
set GRID = ${INPUT_DATA1}/variable.v201810/${CASE}/GRID/
set FIX_bqx  = ${INPUT_DATA}/climo_data.v201807

# sending file to gfdl
set gfdl_archive = /archive/${USER}/SHiELD_S2S/${NAME}.${CASE}.${TYPE}.${MODE}.${MONO}${MEMO}/
set SEND_FILE = /home/${USER}/Util/send_file_slurm.csh
set TIME_STAMP = /home/${USER}/Util/time_stamp.csh

# changeable parameters
    # dycore definitions
    set npx = "769"
    set npy = "769"
    set npx_g2 = "2017"
    set npy_g2 = "1081"
    set npz = "63"
    set npz_g2 = "63"
    set layout_x = "18" 
    set layout_y = "19" 
    set layout_x_g2 = "28" #28
    set layout_y_g2 = "32" #32 
    set io_layout = "1,1"
    set io_layout_g2 = "1,1"
    set nthreads = "2" # DEBUG "2"

    # blocking factor used for threading and general physics performance
    set blocksize = "32"
    set blocksize_g2 = "24"

    # run length
    set months = "0"
    if (! $?days) then
        set days = "0"
    endif
    set hours = "1" # "3"
    set minutes = "0"
    set seconds = "0"
    set dt_atmos = "90" 

    # set the pre-conditioning of the solution
    # =0 implies no pre-conditioning
    # >0 means new adiabatic pre-conditioning
    # <0 means older adiabatic pre-conditioning
    set na_init = 1 # 1

    # variables for controlling initialization of NCEP/NGGPS ICs
    set filtered_terrain = ".true."
    
    set ncep_levs = "64"
    set gfs_dwinds = ".true."

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
    set print_freq = "-6"

    if (${TYPE} == "nh") then
      # non-hydrostatic options
      set make_nh = ".T."
      set hydrostatic = ".F."
      set phys_hydrostatic = ".F."     # can be tested
      set use_hydro_pressure = ".F."   # can be tested
      set consv_te = "1."
        # time step parameters in FV3
      set k_split = "1"
      set n_split = "7" #LMH: Reduce n_split
      set k_split_g2 = "4"
      set n_split_g2 = "5"  #LMH: Reduce n_split
    else
      # hydrostatic options
      set make_nh = ".F."
      set hydrostatic = ".T."
      set phys_hydrostatic = ".F."     # will be ignored in hydro mode
      set use_hydro_pressure = ".T."   # have to be .T. in hydro mode
      set consv_te = "0."
        # time step parameters in FV3
      set k_split = "1"
      set n_split = "6"
    endif

    if (${MONO} == "mono" || ${MONO} == "monotonic") then
      # monotonic options
      set d_con = "1."
      set do_vort_damp = ".false."
      if (${TYPE} == "nh") then
        # non-hydrostatic
        set hord_mt = "10"
        set hord_xx = "10"
      else
        # hydrostatic
        set hord_mt = "10"
        set hord_xx = "10"
      endif
    else
      # non-monotonic options
      set d_con = "1."
      set do_vort_damp = ".true."
      if (${TYPE} == "nh") then
        # non-hydrostatic
        set hord_mt = "6"
        set hord_xx = "6"
      else
        # hydrostatic
        set hord_mt = "10"
        set hord_xx = "10"
      endif
    endif

    if (${MONO} == "non-mono" && ${TYPE} == "nh" ) then
      set vtdm4 = "0.02"
    else
      set vtdm4 = "0.05"
    endif

    # variables for hyperthreading
    set cores_per_node = "36"
    if (${HYPT} == "on") then
      set hyperthread = ".true."
      set div = 2
    else
      set hyperthread = ".false."
      set div = 1
    endif
    @ skip = ${nthreads} / ${div}

# when running with threads, need to use the following command
    @ npes_g1 = ${layout_x} * ${layout_y} * 6
    @ npes_g2 = ${layout_x_g2} * ${layout_y_g2} 
    @ npes = ${npes_g1} + ${npes_g2}
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

# build the date for curr_date and diag_table from DATE
unset echo
set y = `echo ${NAME} | cut -c1-4`
set m = `echo ${NAME} | cut -c5-6`
set d = `echo ${NAME} | cut -c7-8`
set h = `echo ${NAME} | cut -c10-11`
set echo
set curr_date = "${y},${m},${d},${h},0,0"

# build the diag_table with the experiment name and date stamp
cat >! diag_table << EOF
${NAME}.${GRID}.${MODE}.${MONO}
$y $m $d $h 0 0 
EOF
#cat ${BUILD_AREA}/FV3GFS/RUN/RETRO/diag_table_hwt_test >> diag_table

# copy over the other tables and executable
cp ${BUILD_AREA}/RUN/RETRO/data_table data_table
cp ${BUILD_AREA}/RUN/RETRO/diag_table_hwt_test diag_table
cp ${BUILD_AREA}/RUN/RETRO/field_table_6species field_table
cp $executable .

mkdir -p INPUT/

# GFS standard input data (still a tarball)
tar xf ${GFS} 

# Grid and orography data
#tar xf ${GRID}
ln -s ${GRID}/* INPUT/

#ln -s /home/jmoualle/gfs_ctrl.nc INPUT/
ln -s ${INPUT_DATA}/gfs_ctrl.nc INPUT/


# Date specific ICs (still a tarball)
tar xf ${ICS}
#Nested grid fix for new files
foreach i ( $PWD/INPUT/*.tile7.nc )
    ln -s $i ${i:r:r}.nest02.tile7.nc
end

#cp $FIX/global_sfc_emissivity_idx.txt INPUT/sfc_emissivity_idx.txt
cp $FIX/global_sfc_emissivity_idx.txt INPUT/sfc_emissivity_idx.txt
cp INPUT/aerosol.dat .
cp INPUT/co2historicaldata_201*.txt .
cp INPUT/sfc_emissivity_idx.txt .
cp INPUT/solarconstant_noaa_an.txt .

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
     chksum_debug = $chksum_debug
     dycore_only = $dycore_only
     fdiag = $fdiag
/

&diag_manager_nml
flush_nc_files = .true.
           prepend_date = .F.
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
       layout   = $layout_x,$layout_y
       io_layout = $io_layout
       npx      = $npx
       npy      = $npy
       ntiles   = 6,
       npz    = $npz
       !grid_type = -1
       make_nh = .T.
       fv_debug = .F.
       range_warn = .T.
       reset_eta = .F.
       n_sponge = 30
       nudge_qv = .T.
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
       nord =  2
       dddmp = 0.1
       d4_bg = 0.12
       vtdm4 = $vtdm4
       delt_max = 0.002
       ke_bg = 0.
       do_vort_damp = $do_vort_damp
       external_ic = .T.
       gfs_phil = $gfs_phil
       nggps_ic = .T.
       mountain = .F. 
       ncep_ic = .F.
       d_con = $d_con
       hord_mt = 6 !But watch out for grid imprinting!!
       hord_vt = 6
       hord_tm = 6
       hord_dp = 6
       hord_tr = 8
       adjust_dry_mass = .F.
       consv_te = $consv_te
       do_sat_adj = .F.
       consv_am = .F.
       fill = .T.
       dwind_2d = .F.
       print_freq = $print_freq
       warm_start = .F.
       no_dycore = $no_dycore
       z_tracer = .T.

       do_schmidt = .true.
       target_lat = 36.5
       target_lon = -97.5
       stretch_fac = 1.5

       write_3d_diags = .T.
/

&fv_nest_nml
    grid_pes = $npes_g1,$npes_g2
    grid_coarse = 0,1
    tile_coarse = 0,6
    nest_refine = 0,3
    nest_ioffsets = 999,49
    nest_joffsets = 999,174
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
       memuse_verbose = .false.
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
       zhao_mic       = .true.
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
       cal_pre        = .true.
       redrag         = .true.
       dspheat        = .true.
       satmedmf       = .false.
       ysupbl         = .false.
       hybedmf        = .true.
       random_clds    = .true.
       trans_trac     = .true.
       cnvcld         = .true.
       imfshalcnv     = 2
       imfdeepcnv     = 2
       cdmbgwd        = 3.5, 0.25
       prslrd0        = 0.
       ivegsrc        = 1
       isot           = 1
       debug          = .false.
       xkzminv        = 0.3
       xkzm_m         = 1.0
       xkzm_h         = 1.0
/

 &ocean_nml
     mld_option       = "obs"
     ocean_option     = "MLM" ! Ocean mixed layer model or SOM
     restore_method   = 2
     mld_obs_ratio    = 1.
     use_old_mlm      = .true. ! fvGFS-2018 sets to true
     stress_ratio     = 0.75   ! how much of actual wind stress is applied to ocean; WRF actually use 0.25 (strange)
     Gam              = 0.05 ! temperature lapse rate
     use_rain_flux    = .true. ! use rainfall induced cooling flux
     mld_restore_tscale = 0.05
     start_lat        = -45. ! -30 to 30??
     end_lat          = 45.
     eps_day = 10.
/

 &gfdl_cloud_microphysics_nml
       sedi_transport = .true.
       do_sedi_heat = .false.
       rad_snow = .true.
       rad_graupel = .true.
       rad_rain = .true.
       const_vi = .F.
       const_vs = .F.
       const_vg = .F.
       const_vr = .F.
       vi_max = 1.
       vs_max = 2.
       vg_max = 12.
       vr_max = 12.
       qi_lim = 1.
       prog_ccn = .false.
       do_qa = .true.
       fast_sat_adj = .F.
       tau_l2v = 180.
       tau_v2l =  90.
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
       mono_prof = .true.
       z_slope_liq  = .true.
       z_slope_ice  = .true.
       de_ice = .false.
       fix_negative = .true.
       mp_time = 90.
       icloud_f = 1
/

  &interpolator_nml
       interp_method = 'conserve_great_circle'
/

&namsfc
       FNGLAC   = "$FIX/global_glacier.2x2.grb",
       FNMXIC   = "$FIX/global_maxice.2x2.grb",
       FNTSFC   = "$FIX/RTGSST.1982.2012.monthly.clim.grb",
       FNSNOC   = "$FIX/global_snoclim.1.875.grb",
       FNZORC   = "igbp",
       FNALBC   = "$FIX/global_snowfree_albedo.bosu.t1534.3072.1536.rg.grb",
       FNALBC2  = "$FIX/global_albedo4.1x1.grb",
       FNAISC   = "$FIX/CFSR.SEAICE.1982.2012.monthly.clim.grb",
       FNTG3C   = "$FIX/global_tg3clim.2.6x1.5.grb",
       FNVEGC   = "$FIX/global_vegfrac.0.144.decpercent.grb",
       FNVETC   = "$FIX/global_vegtype.igbp.t1534.3072.1536.rg.grb",
       FNSOTC   = "$FIX/global_soiltype.statsgo.t1534.3072.1536.rg.grb",
       FNSMCC   = "$FIX/global_soilmgldas.t1534.3072.1536.grb",
       FNMSKH   = "$FIX/seaice_newland.grb",
       FNTSFA   = "",
       FNACNA   = "",
       FNSNOA   = "",
       FNVMNC   = "$FIX/global_shdmin.0.144x0.144.grb",
       FNVMXC   = "$FIX/global_shdmax.0.144x0.144.grb",
       FNSLPC   = "$FIX/global_slope.1x1.grb",
       FNABSC   = "$FIX/global_mxsnoalb.uariz.t1534.3072.1536.rg.grb",
       FNMLDC   = "$FIX/../mld/mld_DR003_c1m_reg2.0.grb",       
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
flush_nc_files = .true.
           prepend_date = .F.
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
       npz    = $npz_g2
       npz_type = "meso"
       !grid_type = -1
       make_nh =  .F.
       fv_debug = .F.
       range_warn = .T.
       reset_eta = .F.
       n_sponge = 10 ! reduced for new vertical level setup
       nudge_qv = .T.
       tau = 3.
       rf_cutoff = 50.e2
       d2_bg_k1 = 0.20
       d2_bg_k2 = 0.10
       kord_tm = -11
       kord_mt =  11
       kord_wz =  11
       kord_tr =  11
       hydrostatic = $hydrostatic
       phys_hydrostatic = $phys_hydrostatic
       use_hydro_pressure = $use_hydro_pressure
       beta = 0.
       a_imp = 1.
       p_fac = 0.1
       k_split  = $k_split_g2
       n_split  = $n_split_g2
       nwat = 6 !LMH: Increase nwat
       na_init = $na_init
       d_ext = 0.0
       dnats = 1
       fv_sg_adj = 300
       d2_bg = 0.
       nord =  3
       dddmp = 0.2
       d4_bg = 0.15
       vtdm4 = 0.03 ! doubled
       ke_bg = 0.
       do_vort_damp = .T.
       external_ic = .T.
       gfs_phil = $gfs_phil
       nggps_ic = .T.
       mountain = .F.
       ncep_ic = .F.
       d_con = 1.0 ! restored
       delt_max = 0.008 
       hord_mt = 5
       hord_vt = 5
       hord_tm = 5
       hord_dp = 5
       hord_tr = 8
       adjust_dry_mass = .F.
       consv_te = 0.
       do_sat_adj = .F.
       consv_am = .F.
       fill = .T.
       dwind_2d = .F.
       print_freq = $print_freq
       warm_start = .F.
       no_dycore = $no_dycore

       !nested = .true.
       twowaynest = .false.
       !parent_grid_num = 1
       !parent_tile = 6
       !refinement = 3
       !ioffset = 49
       !joffset = 174
       nestupdate = 7

       full_zs_filter = .T.
/

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
       memuse_verbose = .false.
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
       ldiag3d        = .true.
       fhcyc          = $fhcyc
       nst_anl        = .true.
       use_ufo        = .true.
       pre_rad        = .false.
       ncld           = 1
       zhao_mic       = .true.
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
       cnvgwd         = .false.
       shal_cnv       = .true.
       cal_pre        = .true.
       redrag         = .true.
       dspheat        = .true. 
       hybedmf        = .true.
       random_clds    = .true.
       trans_trac     = .true.
       cnvcld         = .true.
       imfshalcnv     = 2
       imfdeepcnv     = 2
       cdmbgwd        = 3.5, 0.25 ! restored
       prslrd0        = 0.
       ivegsrc        = 1
       isot           = 1
       debug          = .false.
       do_deep        = .false.
       xkzminv        = 1.0 
       xkzm_h         = 0.00 ! LJZ/SJL suggestion
       xkzm_m         = 0.00 
/

 &gfdl_cloud_microphysics_nml
       sedi_transport = .F. 
       do_sedi_heat = .F.   
       rad_snow = .true.
       rad_graupel = .true.
       rad_rain = .true.
       const_vi = .F.
       const_vs = .F.
       const_vg = .F.
       const_vr = .F.
       vi_fac = 1.0 ! for non-constant
       vi_max = 3.  ! increased 
       vs_max = 6.  ! increased
       vg_max = 20. ! **Really** increased 
       vr_max = 16. ! increased 
       qi_lim = 1. ! old Fast MP
       prog_ccn = .false.
       do_qa = .true.
       fast_sat_adj = .F.
       tau_l2v = 180
       tau_v2l =  90.
       tau_g2v = 600.
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
       c_cracw = 1.0 
       rh_inc = 0.30
       rh_inr = 0.30
       rh_ins = 0.30
       ccn_l = 270. !for CONUS
       ccn_o = 90.
       use_ppm = .T.  ! set to true
       use_ccn = .true.
       z_slope_liq  = .true.
       z_slope_ice  = .true.
       de_ice = .false.
       fix_negative = .true.
       icloud_f = 1
       mp_time = $dt_atmos
/


  &interpolator_nml
       interp_method = 'conserve_great_circle'
/

&namsfc
       FNGLAC   = "$FIX/global_glacier.2x2.grb",
       FNMXIC   = "$FIX/global_maxice.2x2.grb",
       FNTSFC   = "$FIX/RTGSST.1982.2012.monthly.clim.grb",
       FNSNOC   = "$FIX/global_snoclim.1.875.grb",
       FNZORC   = "igbp",
       FNALBC   = "$FIX/global_snowfree_albedo.bosu.t1534.3072.1536.rg.grb",
       FNALBC2  = "$FIX/global_albedo4.1x1.grb",
       FNAISC   = "$FIX/CFSR.SEAICE.1982.2012.monthly.clim.grb",
       FNTG3C   = "$FIX/global_tg3clim.2.6x1.5.grb",
       FNVEGC   = "$FIX/global_vegfrac.0.144.decpercent.grb",
       FNVETC   = "$FIX/global_vegtype.igbp.t1534.3072.1536.rg.grb",
       FNSOTC   = "$FIX/global_soiltype.statsgo.t1534.3072.1536.rg.grb",
       FNSMCC   = "$FIX/global_soilmgldas.t1534.3072.1536.grb",
       FNMSKH   = "$FIX/seaice_newland.grb",
       FNTSFA   = "",
       FNACNA   = "",
       FNSNOA   = "",
       FNVMNC   = "$FIX/global_shdmin.0.144x0.144.grb",
       FNVMXC   = "$FIX/global_shdmax.0.144x0.144.grb",
       FNSLPC   = "$FIX/global_slope.1x1.grb",
       FNABSC   = "$FIX/global_mxsnoalb.uariz.t1534.3072.1536.rg.grb",
       FNMLDC   = "$FIX/../mld/mld_DR003_c1m_reg2.0.grb",       
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

if ($NO_SEND == "no_send") then
  exit
endif

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

    msub -v source=$WORKDIR/ascii/$begindate.ascii_out.tgz,destination=gfdl:$gfdl_archive/ascii/$begindate.ascii_out.tgz,extension=null,type=ascii $SEND_FILE

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

      msub -v source=$WORKDIR/restart/$enddate,destination=gfdl:$gfdl_archive/restart/$enddate,extension=tar,type=restart $SEND_FILE

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

    msub -v source=$WORKDIR/history/$begindate,destination=gfdl:$gfdl_archive/history/$begindate,extension=tar,type=history $SEND_FILE
    msub -v source=$WORKDIR/history/${begindate}_nggps3d,destination=gfdl:$gfdl_archive/history/${begindate}_nggps3d,extension=tar,type=history $SEND_FILE
    msub -v source=$WORKDIR/history/${begindate}_tracer3d,destination=gfdl:$gfdl_archive/history/${begindate}_tracer3d,extension=tar,type=history $SEND_FILE
