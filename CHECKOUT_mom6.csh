#!/bin/tcsh -f

source $MODULESHOME/init/csh

cd ../SHiELD_SRC/
echo `pwd`

git clone -b dev/gfdl https://github.com/NOAA-GFDL/MOM6/
git clone -b dev/gfdl https://github.com/NOAA-GFDL/SIS2/
git clone -b dev/gfdl https://github.com/NOAA-GFDL/icebergs/

(cd icebergs && git checkout dev/gfdl)
if ("fffb6f35" != "") then
  echo WARNING: Checking out from a fork! Work in progress
  (cd MOM6; git submodule update --recursive --init; git checkout fffb6f35; )
endif
if ("fac2ec43" != "") then
  echo WARNING: Checking out from a fork! Work in progress
  (cd SIS2;git submodule update --recursive --init; git checkout fac2ec43; )
endif
