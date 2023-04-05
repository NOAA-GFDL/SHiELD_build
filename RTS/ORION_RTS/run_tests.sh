#!/bin/sh

#sbatch C768r15n3.csh
sbatch C768.csh --mail-user=Lauren.Chilutti@noaa.gov --mail-type=fail
sbatch C48n4.csh --mail-user=Lauren.Chilutti@noaa.gov --mail-type=fail
sbatch C48_res.csh --mail-user=Lauren.Chilutti@noaa.gov --mail-type=fail
sbatch Regional3km.csh --mail-user=Lauren.Chilutti@noaa.gov --mail-type=fail
