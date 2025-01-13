#!/bin/tcsh -f

source $MODULESHOME/init/csh

cd ../SHiELD_SRC/
echo `pwd`

git clone -b dev/gfdl https://github.com/NOAA-GFDL/MOM6/
git clone -b dev/gfdl https://github.com/NOAA-GFDL/SIS2/
git clone -b dev/gfdl https://github.com/NOAA-GFDL/icebergs/

(cd MOM6; git submodule update --recursive --init)
(cd SIS2; git submodule update --recursive --init)
