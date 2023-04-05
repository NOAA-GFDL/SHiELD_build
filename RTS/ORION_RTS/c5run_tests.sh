#!/bin/sh

#sbatch C768r15n3.csh
sbatch c5C768.csh --mail-user=Lauren.Chilutti@noaa.gov --mail-type=fail
sbatch c5C48n4.csh --mail-user=Lauren.Chilutti@noaa.gov --mail-type=fail
sbatch c5C48_res.csh --mail-user=Lauren.Chilutti@noaa.gov --mail-type=fail
sbatch c5Regional3km.csh --mail-user=Lauren.Chilutti@noaa.gov --mail-type=fail
