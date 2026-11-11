#!/bin/tcsh
#SBATCH --output=./stdout/%x.%j
#SBATCH --job-name=Ortho_NWA3km_shiemom
#SBATCH --clusters=c6
#SBATCH --time=07:30:00
#SBATCH --nodes=105

# Script to run Regional SHiELD+MOM6 over the NWA region
# accepted resolution: 25km, 6km, 3km, Starting date: Sept, 20, 2024
# accepted resolution: 1km, Starting date: Sept 26, 2024
# The 1km domain is smaller than that of the coarse resolutions
# increase layout_x _y as needed
# Joseph.mouallem@noaa.gov

set echo

# NEEDS TO BE SET
################################
set res = 384 # 25km
set res = 738 # 13km
#set res = 1600 # 6km
set res = 3200 # 3km
#set res = 9600 # 1km
################################

echo "Cluster: $SLURM_CLUSTER_NAME"

if (${SLURM_CLUSTER_NAME} == "c7") then
set BASE_DIR    = "/gpfs/f7/bil-coastal-gfdl/scratch/Joseph.Mouallem/"           # Sim/work directory - to be set
set BUILD_DIR = "~${USER}/c7/SHiELD_build/"                  # Build directory - To be set
set INPUT_DATA = "/gpfs/f7/bil-coastal-gfdl/world-shared/SHiELD_INPUT_DATA/"
endif

if (${SLURM_CLUSTER_NAME} == "c6") then
set BASE_DIR    = "/gpfs/f6/bil-coastal-gfdl/scratch/Joseph.Mouallem/"           # Sim/work directory - to be set
set BUILD_DIR = "~${USER}/shiemom_clean/SHiELD_build/"                  # Build directory - To be set
set INPUT_DATA = "/gpfs/f6/bil-coastal-gfdl/proj-shared/gfdl_w/SHiELD_INPUT_DATA/"
endif

if (${SLURM_CLUSTER_NAME} == "c5") then
set BASE_DIR    = "/gpfs/f5/gfdl_w/scratch/Joseph.Mouallem/"                     # Sim/work directory - to be set
set BUILD_DIR = "~${USER}/shiemom_clean/SHiELD_build/"                  # Build directory - To be set
set INPUT_DATA = "/gpfs/f5/gfdl_w/proj-shared/SHiELD_INPUT_DATA/"
endif

if (${SLURM_CLUSTER_NAME} == "stellar") then
set BASE_DIR    = "/scratch/cimes/mouallem/shiemom_runs/test/"
set BUILD_DIR = "~${USER}/for_jinbo/SHiELD_build/"
set INPUT_DATA = "/scratch/cimes/mouallem/from_gaea/Coupled_SHiELD/INPUT/"
endif


unset echo
source ${BUILD_DIR}/site/environment.intel.csh
set echo

set RUN_DIR = "`pwd`"                           # For the diag_table, field_table, momsis input

if ( ! $?COMPILER ) then
  set COMPILER = "intel"
endif

set RELEASE = "SHiEMOM/Ortho_NWA_validation/"

# case specific details
set TYPE = "nh"          # choices:  nh, hydro
set MODE = "64bit"      # choices:  32bit, 64bit
set CASE = "C${res}"
set MONO = "non-mono"
set NAME = "20240920.00Z"
if (${res} == 9600) then
set NAME = "20240926.00Z"
endif
set MEMO = "$SLURM_JOB_NAME.res$res"
set PBL  = "TKE"        # choices:  TKE or YSU
set HYPT = "off"         # choices:  on, off  (controls hyperthreading)
set COMP = "repro"       # choices:  debug, repro, prod
set NO_SEND = "no_send"  # choices:  send, no_send
set EXE = "x"
# directory structure
set WORKDIR    = ${BASE_DIR}/${RELEASE}/${NAME}.${CASE}.${TYPE}.${MODE}.${COMPILER}.${MONO}.${MEMO}/
set executable = ${BUILD_DIR}/Build/bin/SHiEMOM_${TYPE}.${COMP}.${MODE}.${COMPILER}.${EXE}

# input filesets
set FIX  = ${INPUT_DATA}/fix.v201810
set GFS  = ${INPUT_DATA}/GFS_STD_INPUT.20160311.tar

if (${SLURM_CLUSTER_NAME} == "c6") then
  set ICS = /gpfs/f6/bil-coastal-gfdl/proj-shared/gfdl_w/SHiELD_INPUT_DATA/Coupled_SHiELD/INPUT/Regional_validation/NWA_A3km/IC/C${res}/${NAME}_IC/
  set GRID = /gpfs/f6/bil-coastal-gfdl/proj-shared/gfdl_w/SHiELD_INPUT_DATA/Coupled_SHiELD/INPUT/Regional_validation/NWA_A3km/GRID/C${res}/C${res}/
  #if (${res} == "9600") then
  #  set ICS = /gpfs/f6/bil-coastal-gfdl/proj-shared/Joseph.Mouallem/shiemom_pdata/Ortho_Helene/IC/C${res}/${NAME}_IC/
  #  set GRID = /gpfs/f6/bil-coastal-gfdl/proj-shared/Joseph.Mouallem/shiemom_pdata/Ortho_Helene/my_grids/C${res}/C${res}/ 
  #endif
endif

if (${SLURM_CLUSTER_NAME} == "c7") then
  set ICS = /gpfs/f7/bil-coastal-gfdl/world-shared/SHiELD_INPUT_DATA/Coupled_SHiELD/INPUT/Regional_validation/NWA_A3km/IC/C${res}/${NAME}_IC/
  set GRID = /gpfs/f7/bil-coastal-gfdl/world-shared/SHiELD_INPUT_DATA/Coupled_SHiELD/INPUT/Regional_validation/NWA_A3km/GRID/C${res}/C${res}/
endif

if (${SLURM_CLUSTER_NAME} == "c5") then
set ICS = /gpfs/f5/gfdl_w/scratch/Joseph.Mouallem/UFS_OUT/PRETOOLS/IC/C${res}/${NAME}_IC/
set GRID = /gpfs/f5/gfdl_w/scratch/Joseph.Mouallem/UFS_OUT/PRETOOLS/my_grids/C${res}/C${res}/ 
endif

if (${SLURM_CLUSTER_NAME} == "stellar") then
  set ICS = /scratch/cimes/mouallem/from_gaea/Coupled_SHiELD/INPUT/Regional_validation/NWA_A3km/IC/C${res}/${NAME}_IC/
  set GRID = /scratch/cimes/mouallem/from_gaea/Coupled_SHiELD/INPUT/Regional_validation/NWA_A3km/GRID/C${res}/C${res}/
endif

# sending file to gfdl
#set gfdl_archive = /archive/${USER}/${RELEASE}/${DATE}.${GRID}.${MEMO}/
#set SEND_FILE = ${USER}/Util/send_file_slurm.csh
set TIME_STAMP = ${USER}/Util/time_stamp.csh

set DIAG_TABLE  = ${BUILD_DIR}/tables/diag_table_6species
set FIELD_TABLE = ${BUILD_DIR}/tables/field_table_6species_atmland # will be changed later if tke-edmf is used

set layout_x = "18"
set layout_y = "16"
set io_layout = "1,1"
set nthreads = "1"

switch ($res) #assuming domain size=10deg, need to adjust timestep, move it here XXXX
case "384":
   set npx = "255" #halo0
   set npy = "125"
   set npx = "247" #halo0 NWA_A
   set npy = "123"
   set k_split = "1"
   set n_split = "5"
   set dt_atmos = "180"
   breaksw
case "738":
   set npx = "483" #halo0
   set npy = "244"
   set k_split = "1"
   set n_split = "8"
   set dt_atmos = "180"
   set layout_x = "30"
   set layout_y = "30"
   breaksw
case "1600":
   set npx = "1057" #halo0
   set npy = "541"
   set k_split = "2"
   set n_split = "8"
   set dt_atmos = "180"
   set layout_x = "60"
   set layout_y = "60"
   breaksw
case "3200":
   set npx = "2124"
   set npy = "1091"
   set k_split = "5"
   set n_split = "8"
   set dt_atmos = "180"
   set layout_x = "100"
   set layout_y = "100"
   breaksw
case "9600":
   set npx = "4609"
   set npy = "3073"
   set k_split = "8"
   set n_split = "10"
   set dt_atmos = "90"
   set layout_x = "120"
   set layout_y = "120"
endsw

@ NIGLOBAL = ${npx} - 1 #remove the corners
@ NJGLOBAL = ${npy} - 1 #remove the corners
#@ NIGLOBAL = 790 #remove the corners
#@ NJGLOBAL = 756 #remove the corners

set npz = "75"
set rough = "hwrf17" # hwrf17; coare3.5; beljaars; charnock

# blocking factor used for threading and general physics performance
set blocksize = "32"

# run length
set months = "0"
set days = "9"
set hours = "1"
set minutes = "0"
set seconds = "0"

# PBL related settings
switch ($PBL)
case "TKE":
    set FIELD_TABLE = ${FIELD_TABLE}_tke
    set satmedmf = ".true."
    set ysupbl = ".false."
    breaksw
case "YSU":
    set satmedmf = ".false."
    set ysupbl = ".true."
endsw


#fms yaml
set use_yaml=".F." #if True, requires data_table.yaml and field_table.yaml

# set the pre-conditioning of the solution
# =0 implies no pre-conditioning
# >0 means new adiabatic pre-conditioning
# <0 means older adiabatic pre-conditioning
set na_init = 0

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
#set fhcyc = "0."

# determines whether FV3 or GFS physics calculate geopotential
set gfs_phil = ".false."

# set various debug options
set no_dycore = ".F."
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
else
  # hydrostatic options
  set make_nh = ".F."
  set hydrostatic = ".T."
  set phys_hydrostatic = ".F."     # will be ignored in hydro mode
  set use_hydro_pressure = ".T."   # have to be .T. in hydro mode
  set consv_te = "0."
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
set run_cmd = "srun --label --ntasks=$npes --cpus-per-task=$skip ./$executable:t"

if (${SLURM_CLUSTER_NAME} == "stellar") then
set run_cmd = "srun --label --ntasks=$npes --export=ALL --cpus-per-task=$skip --cpu-bind=cores ./$executable:t"
endif
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

# specify the start and end time for WW3
set start_yyyymmdd = `date -u -d "${y}-${m}-${d} ${h}:00:00Z" "+%Y%m%d"`
set start_hhmmss   = `date -u -d "${y}-${m}-${d} ${h}:00:00Z" "+%H%M%S"`
set end_yyyymmdd = `date -u -d "${y}-${m}-${d} ${h}:00:00Z +${months} months +${days} days +${hours} hours +${minutes} minutes +${seconds} seconds" "+%Y%m%d"`
set end_hhmmss   = `date -u -d "${y}-${m}-${d} ${h}:00:00Z +${months} months +${days} days +${hours} hours +${minutes} minutes +${seconds} seconds" "+%H%M%S"`

# build the diag_table with the experiment name and date stamp
cat >! diag_table << EOF
${NAME}.${CASE}.${MODE}.${MONO}
$y $m $d $h 0 0 
EOF
#this file does not exist so no diag table is being used
#cat ${BUILD_DIR}/tables/diag_table_hwt_simple >> diag_table
cat ${DIAG_TABLE} >> diag_table

## copy over the other tables and executable
#if ( ${use_yaml} == ".T." ) then
#  cp ${BUILD_DIR}/tables/data_table.yaml data_table.yaml
#  cp ${BUILD_DIR}/tables/field_table_6species.yaml field_table.yaml
#else
#  cp ${BUILD_DIR}/tables/data_table data_table
#  cp ${BUILD_DIR}/tables/field_table_6species field_table
#endif


cp ${RUN_DIR}/data_table data_table
cp ${FIELD_TABLE} field_table
cp $executable .

# GFS standard input data
tar xf ${GFS} 

ln -sf ${GRID}/C${res}_oro_data.tile7.halo3.nc INPUT/oro_data.nc
ln -sf ${GRID}/C${res}_grid.tile7.halo4.nc INPUT/grid.tile7.halo4.nc
ln -sf ${GRID}/C${res}_grid.tile7.halo0.nc INPUT/grid.tile7.halo0.nc
ln -sf ${GRID}/C${res}_oro_data.tile7.halo3.nc INPUT/oro_data.nc
ln -sf ${GRID}/C${res}_oro_data.tile7.halo4.nc INPUT/oro_data.tile7.halo4.nc

ln -sf ${ICS}/* INPUT/

mv INPUT/sfc_data.tile7.nc INPUT/sfc_data.nc
mv INPUT/gfs_data.tile7.nc INPUT/gfs_data.nc

mv INPUT/C${res}_mosaic.nc INPUT/grid_spec.nc

cp $FIX/global_sfc_emissivity_idx.txt INPUT/sfc_emissivity_idx.txt
cp INPUT/aerosol.dat .
cp INPUT/co2historicaldata_201*.txt .
cp INPUT/sfc_emissivity_idx.txt .
cp INPUT/solarconstant_noaa_an.txt .

ln -sf $FIX/global_glacier.2x2.grb INPUT/
ln -sf $FIX/global_maxice.2x2.grb INPUT/
ln -sf $FIX/RTGSST.1982.2012.monthly.clim.grb INPUT/
ln -sf $FIX/global_snoclim.1.875.grb INPUT/
ln -sf $FIX/global_snowfree_albedo.bosu.t1534.3072.1536.rg.grb INPUT/
ln -sf $FIX/global_albedo4.1x1.grb INPUT/
ln -sf $FIX/CFSR.SEAICE.1982.2012.monthly.clim.grb INPUT/
ln -sf $FIX/global_tg3clim.2.6x1.5.grb INPUT/
ln -sf $FIX/global_vegfrac.0.144.decpercent.grb INPUT/
ln -sf $FIX/global_vegtype.igbp.t1534.3072.1536.rg.grb INPUT/
ln -sf $FIX/global_soiltype.statsgo.t1534.3072.1536.rg.grb INPUT/
ln -sf $FIX/global_soilmgldas.t1534.3072.1536.grb INPUT/
ln -sf $FIX/seaice_newland.grb INPUT/
ln -sf $FIX/global_shdmin.0.144x0.144.grb INPUT/
ln -sf $FIX/global_shdmax.0.144x0.144.grb INPUT/
ln -sf $FIX/global_slope.1x1.grb INPUT/
ln -sf $FIX/global_mxsnoalb.uariz.t1534.3072.1536.rg.grb INPUT/

########################################################################
########################################################################
######################### ADD MOM6 input files
########################################################################
########################################################################
cp ${RUN_DIR}/MOMSIS_INPUTFILES/MOM_input .
cp ${RUN_DIR}/MOMSIS_INPUTFILES/SIS_input .
############### copy ocean and mosaic files
ln -sf ${GRID}/ocean_and_mosaic_highres/* INPUT/
if (${res} == 384) then
ln -sf ${GRID}/ocean_and_mosaic/* INPUT/
endif
#ln -sf ${GRID}/ocean_and_mosaic_highres_3ocn/* INPUT/  # for 1km atm 3km ocn
 
ln -sf ${ICS}/../Ocean_${y}-${m}-${d}.${h}Z_IC/MOM6_IC_${start_yyyymmdd}${h}_C${res}.nc   INPUT/
ln -sf ${ICS}/../Ocean_${y}-${m}-${d}.${h}Z_IC/${start_yyyymmdd}/*                       INPUT/


cat >! MOM_override <<EOF
! Blank file in which we can put "overrides" for parameters
!VERBOSITY = 9
#override NIGLOBAL = ${NIGLOBAL}
#override NJGLOBAL = ${NJGLOBAL}
#override COORD_CONFIG = "ALE"
#override INTERPOLATION_SCHEME = "PPM_H4"
#override REGRIDDING_COORDINATE_MODE = "Z*"
#override ALE_COORDINATE_CONFIG = "FNC1:2,6500,6,.01"
ROTATION = "2omegasinlat"
F_0 = 5.E-5 !about 22.5N
BETA = 0.0
#override INIT_LAYERS_FROM_Z_FILE = True
#override TEMP_SALT_Z_INIT_FILE = ""      ! default = "temp_salt_z.nc"
#override TEMP_Z_INIT_FILE = "MOM6_IC_${start_yyyymmdd}${h}_C${res}.nc"
#override SALT_Z_INIT_FILE = "MOM6_IC_${start_yyyymmdd}${h}_C${res}.nc"
#override Z_INIT_FILE_PTEMP_VAR = "temp" ! default = "ptemp"
#override Z_INIT_FILE_SALT_VAR = "salt"   ! default = "salt"
#override Z_INIT_ALE_REMAPPING = True     !   [Boolean] default = False
#override Z_INIT_REMAP_GENERAL = True     !   [Boolean] default = False
#override Z_INIT_REMAP_OLD_ALG = False    !   [Boolean] default = True
#override Z_INIT_REMAP_FULL_COLUMN = True
#override DEPRESS_INITIAL_SURFACE = True
#override SURFACE_HEIGHT_IC_FILE = "MOM6_IC_${start_yyyymmdd}${h}_C${res}.nc"
#override SURFACE_HEIGHT_IC_VAR = "ssh"
#override VELOCITY_CONFIG = "file"
#override VELOCITY_FILE = "MOM6_IC_${start_yyyymmdd}${h}_C${res}.nc"
#override U_IC_VAR = "u"
#override V_IC_VAR = "v"
!TEST
#override DT=90.
#override DT_THERM=900.
#override SAVE_INITIAL_CONDS = True
#override REENTRANT_X = False
#override REENTRANT_Y = False
#override SAVE_INITIAL_CONDS = True
#override REENTRANT_X = False
#override REENTRANT_Y = False
#override ! === module MOM_open_boundary ===
#override ! Controls where open boundaries are located, what kind of boundary condition to impose, and what data to apply,
#override ! if any.
#override OBC_NUMBER_OF_SEGMENTS = 3      ! default = 0
#override                                 ! The number of open boundary segments.
#override OBC_FREESLIP_VORTICITY = False !None
#override OBC_FREESLIP_STRAIN = False !None
#override OBC_COMPUTED_VORTICITY = True !None
#override OBC_COMPUTED_STRAIN = True !None
#override OBC_ZERO_BIHARMONIC = True !None
#override OBC_SEGMENT_001 = "J=0,I=0:N,FLATHER,ORLANSKI,NUDGED,ORLANSKI_TAN,NUDGED_TAN" !
#override                                 ! Documentation needs to be dynamic?????
#override OBC_SEGMENT_001_VELOCITY_NUDGING_TIMESCALES = 3.0, 360.0 !   [days]
#override                                 ! Timescales in days for nudging along a segment, for inflow, then outflow.
#override                                 ! Setting both to zero should behave like SIMPLE obcs for the baroclinic
#override                                 ! velocities.
#override OBC_SEGMENT_002 = "J=N,I=N:0,FLATHER,ORLANSKI,NUDGED,ORLANSKI_TAN,NUDGED_TAN" !
#override                                 ! Documentation needs to be dynamic?????
#override OBC_SEGMENT_002_VELOCITY_NUDGING_TIMESCALES = 3.0, 360.0 !   [days]
#override                                 ! Timescales in days for nudging along a segment, for inflow, then outflow.
#override                                 ! Setting both to zero should behave like SIMPLE obcs for the baroclinic
#override                                 ! velocities.
#override OBC_SEGMENT_003 = "I=N,J=0:N,FLATHER,ORLANSKI,NUDGED,ORLANSKI_TAN,NUDGED_TAN" !
#override                                 ! Documentation needs to be dynamic?????
#override OBC_SEGMENT_003_VELOCITY_NUDGING_TIMESCALES = 3.0, 360.0 !   [days]
#override                                 ! Timescales in days for nudging along a segment, for inflow, then outflow.
#override                                 ! Setting both to zero should behave like SIMPLE obcs for the baroclinic
#override                                 ! velocities.
#override OBC_TRACER_RESERVOIR_LENGTH_SCALE_IN = 9000.0 !   [m] default = 0.0
#override OBC_TRACER_RESERVOIR_LENGTH_SCALE_OUT = 9000.0 !   [m] default = 0.0
#override                                 ! An effective length scale for restoring the tracer concentration at the
#override                                 ! boundaries to externally imposed values when the flow is exiting the domain.
#override BRUSHCUTTER_MODE = True         !   [Boolean] default = False
#override                                 ! If true, read external OBC data on the supergrid.
#override! === module MOM_state_initialization ===
#override OBC_SEGMENT_001_DATA = "U=file:uv_001.nc(u),V=file:uv_001.nc(v),SSH=file:zos_001.nc(zos),TEMP=file:thetao_001.nc(thetao),SALT=file:so_001.nc(so)" !
#override                                ! OBC segment docs
#override OBC_SEGMENT_002_DATA = "U=file:uv_002.nc(u),V=file:uv_002.nc(v),SSH=file:zos_002.nc(zos),TEMP=file:thetao_002.nc(thetao),SALT=file:so_002.nc(so)" !
#override                                ! OBC segment docs
#override OBC_SEGMENT_003_DATA = "U=file:uv_003.nc(u),V=file:uv_003.nc(v),SSH=file:zos_003.nc(zos),TEMP=file:thetao_003.nc(thetao),SALT=file:so_003.nc(so)" !
#override                                ! OBC segment docs


EOF

####cat >! MOM_layout <<EOF
####LAYOUT   = ${layout_x},${layout_y}
####EOF

cat >! SIS_override <<EOF
! Blank file in which we can put "overrides" for parameters
#override ADD_DIURNAL_SW = False ! This must ONLY be used in the ice-ocean mode, NOT fully coupled mode.
#override NIGLOBAL = ${NIGLOBAL}
#override NJGLOBAL = ${NJGLOBAL}
#override REENTRANT_Y = False
#override REENTRANT_X = False
EOF

set irun = 1
set nruns = 1

while ( $irun <= $nruns )

if ( $irun == 1 ) then

   set nggps_ic = ".T."
   set mountain = ".F."
   set external_ic = ".T."
   set warm_start = ".F."
   set input_filename = 'n' # for mom6/sis2
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
   set input_filename = 'r' #for mom6/sis2

endif

ls -ll INPUT/

cat >! input.nml <<EOF

 &SIS_input_nml
       output_directory = './',
       input_filename = ${input_filename}
       restart_input_dir = 'INPUT/',
       restart_output_dir = 'RESTART/',
       parameter_filename = 'SIS_input',
                            'SIS_override' 
/

 &MOM_input_nml
       output_directory = '.',
       input_filename = ${input_filename}
       restart_input_dir = 'INPUT',
       restart_output_dir = 'RESTART',
       parameter_filename = 'MOM_input',
                             'MOM_override'
/

 &ice_albedo_nml
       t_range = 10. 
/

 &ice_model_nml
/

 &icebergs_nml
/

 &monin_obukhov_nml
       ! joseph: to set this to false, compile land_null/land_model.F90 with land2cplr%rough_mom = 0.01
       neutral = .false. ! KGao: should not use true for coupled mode
/

 &ocean_albedo_nml
       ocean_albedo_option = 2
/

 &ocean_rough_nml
       rough_scheme = $rough
/

 &sat_vapor_pres_nml
       construct_table_wrt_liq = .true.
       construct_table_wrt_liq_and_ice = .true.
/

 &surface_flux_nml
       ncar_ocean_flux = .false. ! KGao: must be false for the coupled mode
       raoult_sat_vap = .true.
       do_iter_monin_obukhov = .true. ! KGao: turn this on for hwrf17 rough scheme
       niter_monin_obukhov = 2 ! KGao: 2 should work great
/

 &fms_affinity_nml
       affinity=.F.
/

 &atmos_model_nml
     blocksize = $blocksize
     chksum_debug = $chksum_debug
     dycore_only = $dycore_only
     fdiag = $fdiag
     fullcoupler_fluxes=1
/

&diag_manager_nml
    prepend_date = .F.
    max_num_axis_sets = 100 
    max_files = 100
    max_axes = 240
/

 &fms_io_nml
       checksum_required = .false.
       max_files_r = 100,
       max_files_w = 100,
/

 &fms_nml
       clock_grain = 'ROUTINE',
       domains_stack_size = 3000000,
       print_memory_usage = .F.
/

 &fv_grid_nml
       grid_file = 'INPUT/atmos_mosaic.new.nc' ! This line is IMPORTANT for regional model
/

 &fv_core_nml
       layout   = $layout_x,$layout_y
       io_layout = $io_layout
       npx      = $npx
       npy      = $npy
       ntiles   = 1
       npz    = $npz
       grid_type = 5
       make_nh =  .F.
       fv_debug = .F.
       range_warn = .F.
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
       fv_sg_adj = 300 ! 2019: full-domain weak 2dz damping
       n_sponge = 23
       d2_bg = 0.
       nord =  3  
       dddmp = 0.1
       d4_bg = 0.12 ! joseph: changed from 0.14 for the new grid
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
       full_zs_filter = .true.
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
       current_date =  $curr_date
       calendar = 'julian'
       atmos_nthreads = $nthreads
       use_hyper_thread = $hyperthread
       do_ocean=.T.               !off with shield, on with shieldfull
       dt_cpld = $dt_atmos        !off with shield, on with shieldfull
       do_flux=.T.
       do_land=.False.
       do_ice=.T.
       do_debug=.false.
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
       pdfcld         = .true.
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
       do_deep        = .false.
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
       ysupbl         = $ysupbl
       satmedmf       = $satmedmf 
       isatmedmf      = 1
       !use_lup_only   = .T.
       rlmx           = 150.
       cs0            = 0.25 
       clam_deep      = 0.1 
       clam_shal      = 0.1 
       !c0s_deep       = 0.01
       !c0s_shal       = 0.01
       !c1_deep        = 1.
       !c1_shal        = 1.
       xkzminv        = 1.0
       xkzm_m         = 1.0
       xkzm_h         = 1.0
       cloud_gfdl     = .true.
       do_ocean       = .false.
/

 &gfdl_mp_nml
       use_rhc_revap = .true.
       rhc_revap = .8
       do_sedi_uv = .true.
       do_sedi_w = .true.
       do_sedi_heat = .false.
       rad_snow = .true.
       rad_graupel = .true.
       rad_rain = .true.
       const_vi = .F.
       const_vs = .F.
       const_vg = .F.
       const_vr = .F.
       vi_max = 0.6
       vs_max = 8.
       vg_max = 10.
       vr_max = 12.
       qi_lim = 2.
       prog_ccn = .false.
       do_qa = .true.
       tau_l2v = 180. !225.
       tau_v2l = 90.  !150.
       rthresh = 10.e-6  ! This is a key parameter for cloud water
       dw_land  = 0.16
       dw_ocean = 0.10
      ! ql_gen = 1.0e-3
       ql_mlt = 1.0e-3
       qi0_crt = 1.2e-4
       qi0_max = 2.0e-4 
       qs0_crt = 1.0e-2
       tau_i2s = 1000.
       c_psaci = 0.1
       c_pgacs = 0.001
       rh_inc = 0.30
       rh_inr = 0.30
      ! rh_ins = 0.30
       ccn_l = 270. !300.
       ccn_o = 90. !200.
       c_paut = 0.5
       c_pracw = 0.75
       z_slope_liq  = .true.
       z_slope_ice  = .true.
       fix_negative = .true.
       icloud_f = 1
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

if ( ${use_yaml} == ".T." ) then
  cat >> input.nml << EOF

 &field_manager_nml
       use_field_table_yaml = $use_yaml
/

 &data_override_nml
       use_data_table_yaml = $use_yaml
/
EOF
endif

# run the executable

   sleep 1
   ${run_cmd} | tee fms.out
   if ( $? != 0 ) then
	exit
   endif
    @ irun++

if ($NO_SEND == "no_send") then
  continue
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
