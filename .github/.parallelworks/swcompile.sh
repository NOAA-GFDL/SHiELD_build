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
if [ -z "$1" ]
  then
    echo "No branch/PR supplied; using main"
    branch=main
  else
    echo Branch is ${1}
    branch=${1}
fi
if [ -z "$2" ]
  then
    echo "No second argument"
    commit=none
  else
    echo Commit is ${2}
    commit=${2}
fi
testDir=${dirRoot}/${intelVersion}/SHiELD_build/${branch}/${commit}
logDir=${testDir}/log
# Set up build
cd ${testDir}/SHiELD_build/Build
#Define External Libs path
export EXTERNAL_LIBS=${dirRoot}/externallibs
# Build SHiELD
set -o pipefail
singularity exec -B /contrib ${container} ${container_env_script} "./COMPILE solo sw 64bit repro intel clean"

