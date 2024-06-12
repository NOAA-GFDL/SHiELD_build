#!/bin/tcsh -f

source $MODULESHOME/init/csh

cd ../SHiELD_SRC/
echo `pwd`



# ---------------- component 'mom6'
echo "Cloning https://github.com/NOAA-GFDL/ocean_BGC.git on branch/tag master"
set git_output=`git clone -q --recursive -b master https://github.com/NOAA-GFDL/ocean_BGC.git >& /dev/stdout`
if ( $? != 0 ) then
     echo "$git_output" | sed 's/^/**GIT ERROR** /' > /dev/stderr
     exit 1
endif
# Additional checkout commands from XML file

          ( cd ocean_BGC && git checkout 2023.01 )
          git clone -b dev/gfdl https://github.com/NOAA-GFDL/MOM6-examples.git mom6
          pushd mom6
          git checkout 3220014e
          git submodule update --recursive --init src/MOM6 src/SIS2 src/icebergs
          (cd src/icebergs && git checkout dev/gfdl)
          if ("fffb6f35" != "") then
            echo WARNING: Checking out from a fork! Work in progress
            (cd src/MOM6;git checkout fffb6f35; )
          endif
          if ("fac2ec43" != "") then
            echo WARNING: Checking out from a fork! Work in progress
            (cd src/SIS2;git checkout fac2ec43; )
          endif
          popd

          pushd mom6
          set platform_domain = `perl -T -e "use Net::Domain(hostdomain) ; print hostdomain"`
          if ("${platform_domain}" =~ *"MsState"* ) then
            ln -s /work/noaa/gfdlscr/pdata/gfdl/gfdl_O/datasets/ .datasets
          else
            ln -s /lustre/f2/pdata/gfdl/gfdl_O/datasets/ .datasets
          endif
          popd

          test -e mom6/.datasets
          if ($status != 0) then
            echo ""; echo "" ; echo "   WARNING:  .datasets link in MOM6 examples directory is invalid"; echo ""; echo ""
          endif

          git clone https://gitlab.gfdl.noaa.gov/ogrp/Gaea-stats-MOM6-examples.git
          pushd Gaea-stats-MOM6-examples/regressions/ice_ocean_SIS2
          foreach stat ( `find . -name "ocean.stats.*"` )
            cp $stat ../../../mom6/ice_ocean_SIS2/$stat
          end
          popd


## ---------------- component 'sis2'
#echo "Cloning https://github.com/NOAA-GFDL/ice_param.git on branch/tag 2021.03"
#set git_output=`git clone -q --recursive -b 2021.03 https://github.com/NOAA-GFDL/ice_param.git >& /dev/stdout`
#if ( $? != 0 ) then
#     echo "$git_output" | sed 's/^/**GIT ERROR** /' > /dev/stderr
#     exit 1
#endif
## Additional checkout commands from XML file

