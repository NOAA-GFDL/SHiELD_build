#!/bin/sh -xe

##############################################################################
## User set up variables
## Root directory for CI
dirRoot=/contrib/fv3
## Intel version to be used
intelVersion=2023.2.0
##############################################################################
## HPC-ME container
container=/contrib/containers/noaa-intel-prototype_2023.09.25.sif
container_env_script=/contrib/containers/load_spack_noaa-intel.sh
##############################################################################
## Set up the directories
# First argument should be $GITHUB_REF which is the reference to the PR/branch
# to be checked out for SHiELD_build
if [ -z "$1" ]
  then
    echo "No branch/PR supplied; using main"
    branch=main
  else
    echo Branch is ${1}
    branch=${1}
fi
# Second Argument should be $GITHUB_SHA which  is the commit hash of the
# branch or PR to trigger the CI, if run manually, you do not need a 2nd
# argument.  This is needed in the circumstance where a PR is created, 
# then the CI triggers, and before that CI has finished, the developer
# pushes a newer commit which triggers a second round of CI.  We would
# like unique directories so that both CI runs do not interfere.
if [ -z "$2" ]
  then
    echo "No second argument"
    commit=""
  else
    echo Commit is ${2}
    commit=${2}
fi

testDir=${dirRoot}/${intelVersion}/SHiELD_build/${branch}/${commit}
logDir=${testDir}/log
export MODULESHOME=/usr/share/lmod/lmod
#Define External Libs path
export EXTERNAL_LIBS=${dirRoot}/${intelVersion}/SHiELD_build/externallibs
mkdir -p ${EXTERNAL_LIBS}
## create directories
rm -rf ${testDir}
mkdir -p ${logDir}
# salloc commands to start up 
#2 tests layout 8,8 (16 nodes)
#2 tests layout 4,8 (8 nodes)
#9 tests layout 4,4 (18 nodes)
#5 tests layout 4,1 (5 nodes)
#17 tests layout 2,2 (17 nodes)
#salloc --partition=p2 -N 64 -J ${branch} sleep 20m &

## clone code
cd ${testDir}
git clone --recursive https://github.com/NOAA-GFDL/SHiELD_build.git  
## Check out the PR
cd ${testDir}/SHiELD_build && git fetch origin ${branch}:toMerge && git merge toMerge

##checkout components
cd ${testDir}/SHiELD_build && ./CHECKOUT_code
#Check if we already have FMS compiled
grep -m 1 "fms_release" ${testDir}/SHiELD_build/CHECKOUT_code > ${logDir}/release.txt
source ${logDir}/release.txt
echo ${fms_release}
echo `cat ${EXTERNAL_LIBS}/FMSversion`
if [[ ${fms_release} != `cat ${EXTERNAL_LIBS}/FMSversion` ]]
  then
    #remove libFMS if it exists
    if [ -d $EXTERNAL_LIBS/libFMS ]
      then
        rm -rf $EXTERNAL_LIBS/libFMS
    fi
    if [ -e $EXTERNAL_LIBS/FMSversion ]
      then
        rm $EXTERNAL_LIBS/FMSversion
    fi
    echo $fms_release > $EXTERNAL_LIBS/FMSversion
    echo $container > $EXTERNAL_LIBS/FMScontainerversion
    echo $container_env_script >> $EXTERNAL_LIBS/FMScontainerversion
    # Build FMS
    cd ${testDir}/SHiELD_build/Build
    set -o pipefail
    singularity exec -B /contrib ${container} ${container_env_script} "./BUILDlibfms intel"
 fi
