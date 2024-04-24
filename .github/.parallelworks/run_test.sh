#!/bin/bash -xe
ulimit -s unlimited
##############################################################################
## User set up veriables
## Root directory for CI
dirRoot=/contrib/fv3
## Intel version to be used
intelVersion=2023.2.0
##############################################################################
## HPC-ME container
container=/contrib/containers/noaa-intel-prototype_2023.09.25.sif
container_env_script=/contrib/containers/load_spack_noaa-intel.sh

##Parse Arguments
#first argument should be the name of the test and is mandatory
if [ -z "$1" ]
  then
    echo "Please run this script with an argument indicating what test to run.  For example:"
    echo "./run_test.sh C128r20.solo.superC"
  else
    echo Test is ${1}
    test=${1}
fi
#second argument is the branch name. This is optional. Default is main branch if none supplied
if [ -z "$2" ]
  then
    echo "No branch supplied; using main"
    branch=main
  else
    echo Branch is ${2}
    branch=${2}
fi
#third argument is the commit hash if running from CI.  This is optional
if [ -z "$3" ]
  then
    echo "No commit being used in file path"
    commit=""
  else
    echo Commit is ${3}
    commit=${3}
fi

## Set up the directories
MODULESHOME=/usr/share/lmod/lmod
testDir=${dirRoot}/${intelVersion}/SHiELD_build/${branch}/${commit}
logDir=${testDir}/log
baselineDir=${dirRoot}/baselines/intel/${intelVersion}

## Run the CI Test
# Define the builddir testscriptdir and rundir 
# Set the BUILDDIR for the test script to use
export BUILDDIR="${testDir}/SHiELD_build"
testscriptDir=${BUILDDIR}/RTS/CI
runDir=${BUILDDIR}/CI/BATCH-CI

# Run CI test scripts
cd ${testscriptDir}
set -o pipefail
# Execute the test piping output to log file
./${test} " --partition=p2 --mpi=pmi2 --job-name=${commit}_${test} singularity exec -B /contrib ${container} ${container_env_script}" |& tee ${logDir}/run_${test}.log

## Compare Restarts to Baseline
#The following tests are not expectred to have run-to-run reproducibility:
#d96_2k.solo.bubble
#d96_2k.solo.bubble.n0
#d96_2k.solo.bubble.nhK
if [[ ${test} == "d96_2k.solo.bubble" || ${test} == "d96_2k.solo.bubble.n0" || ${test} == "d96_2k.solo.bubble.nhK" ]]
  then
    echo "${test} is not expected to reproduce so answers were not compared"
  else
    source $MODULESHOME/init/sh
    export MODULEPATH=/mnt/shared/manual_modules:/usr/share/modulefiles/Linux:/usr/share/modulefiles/Core:/usr/share/lmod/lmod/modulefiles/Core:/apps/modules/modulefiles:/apps/modules/modulefamilies/intel
    module load intel/2022.1.2
    module load netcdf
    module load nccmp
    for resFile in `ls ${baselineDir}/${test}`
    do
      nccmp -d ${baselineDir}/${test}/${resFile} ${runDir}/${test}/RESTART/${resFile}
    done
fi
