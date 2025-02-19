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
##############################################################################

#Parse Arguments
branch=main
commit=""
while [[ $# -gt 0 ]]; do
  case $1 in
    -b|--branch)
      branch="$2"
      shift # past argument
      shift # past value
      ;;
    -h|--hash)
      commit="$2"
      shift # past argument
      shift # past value
      ;;
    -t|--test)
      testname="$2"
      shift # past argument
      shift # past value
      ;;
    *)
      echo "unknown argument"
      exit 1
      ;;
  esac
done

if [ -z $testname ]
  then
    echo "must specify a test name with -t"
    exit 1
fi

echo "branch is $branch"
echo "commit is $commit"
echo "test is $testname"

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
./${testname} " --partition=p2 --mpi=pmi2 --job-name=${commit}_${testname} singularity exec -B /contrib ${container} ${container_env_script}" |& tee ${logDir}/run_${testname}.log

## Compare Restarts to Baseline
#The following tests are not expectred to have run-to-run reproducibility:
#d96_2k.solo.bubble
#d96_2k.solo.bubble.n0
#d96_2k.solo.bubble.nhK
if [[ ${testname} == "d96_2k.solo.bubble" || ${testname} == "d96_2k.solo.bubble.n0" || ${testname} == "d96_2k.solo.bubble.nhK" ]]
  then
    echo "${testname} is not expected to reproduce so answers were not compared"
  else
    source $MODULESHOME/init/sh
    export MODULEPATH=/mnt/shared/manual_modules:/usr/share/modulefiles/Linux:/usr/share/modulefiles/Core:/usr/share/lmod/lmod/modulefiles/Core:/apps/modules/modulefiles:/apps/modules/modulefamilies/intel
    module load intel/2022.1.2
    module load netcdf
    module load nccmp
    for resFile in `ls ${baselineDir}/${testname}`
    do
      nccmp -d ${baselineDir}/${testname}/${resFile} ${runDir}/${testname}/RESTART/${resFile}
    done
fi
