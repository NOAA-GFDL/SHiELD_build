#!/bin/sh


#All tests in GAEA_RTS assume that you have cloned SHiELD_build at this location:
#BUILD_AREA = "/ncrc/home1/${USER}/SHiELD_dev/SHiELD_build/"
#The run directories will be at (as defined by the test scripts):
#/gpfs/f5/${YourGroup}/scratch/${USER}/SHiELD_${RELEASE}
#where YourGroup is defined in the runscripts and
#RELEASE is defined in CHECKOUT_code when the code was compiled

set -x

export COMPILER="intel"
export MODE="64bit"
export COMP="repro"
export BUILD_AREA=`pwd`/../../

export cluster="c6"
export ACCOUNT="bil-coastal-gfdl"

#export cluster="c5"
#export ACCOUNT="gfdl_w"

mkdir -p stdout

sbatch --export=ALL,YourGroup=$ACCOUNT,cluster=$cluster --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT} --cluster=${cluster} C48_test.csh
sbatch --export=ALL,YourGroup=$ACCOUNT,cluster=$cluster --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT} --cluster=${cluster} C48_res.csh
sbatch --export=ALL,YourGroup=$ACCOUNT,cluster=$cluster --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT} --cluster=${cluster} C48n4.csh
sbatch --export=ALL,YourGroup=$ACCOUNT,cluster=$cluster --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT} --cluster=${cluster} C384.csh
sbatch --export=ALL,YourGroup=$ACCOUNT,cluster=$cluster --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT} --cluster=${cluster} C768.csh
sbatch --export=ALL,YourGroup=$ACCOUNT,cluster=$cluster --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT} --cluster=${cluster} C768r15n3.csh
sbatch --export=ALL,YourGroup=$ACCOUNT,cluster=$cluster --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT} --cluster=${cluster} C3072_res.csh
sbatch --export=ALL,YourGroup=$ACCOUNT,cluster=$cluster --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT} --cluster=${cluster} Regional3km.csh
