#!/bin/sh

#All tests in GAEA_RTS assume that you have cloned SHiELD_build at this location:
#BUILD_AREA = "/ncrc/home1/${USER}/SHiELD_dev/SHiELD_build/"
#The run directories will be at (as defined by the test scripts):
#/gpfs/f5/${YourGroup}/scratch/${USER}/SHiELD_${RELEASE}
#where YourGroup is defined in the runscripts and
#RELEASE is defined in CHECKOUT_code when the code was compiled

export COMPILER="intel"
export MODE="64bit"
export COMP="repro"
ACCOUNT="gfdl_f"

mkdir -p stdout

sbatch C48_res.aquaplanet.csh --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT}
sbatch C48_res.baroclinic.csh --mail-user=${USER}@noaa.gov --mail-type=fail --account=${ACCOUNT}

