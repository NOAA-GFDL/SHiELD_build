#!/bin/sh


#All tests in GAEA_RTS assume that you have cloned SHiELD_build at this location:
#BUILD_AREA = "/ncrc/home1/${USER}/SHiELD_dev/SHiELD_build/"
#The run directories will be at (as defined by the test scripts):
#/gpfs/f5/${YourGroup}/scratch/${USER}/SHiELD_${RELEASE}
#where YourGroup is defined in the runscripts and
#RELEASE is defined in CHECKOUT_code when the code was compiled

export COMPILER="intel"
export MODE="32bit"
export COMP="repro"
ACCOUNT="gfdl_f"

mkdir -p stdout

sbatch C768r15n3.csh --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT}
sbatch C3072_res.csh --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT}
sbatch C384.csh --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT}
sbatch C48_test.csh --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT}
sbatch C768.csh --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT}
sbatch C48n4.csh --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT}
sbatch C48_res.csh --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT}
sbatch Regional3km.csh --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT}
