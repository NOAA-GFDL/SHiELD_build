#!/bin/sh

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
