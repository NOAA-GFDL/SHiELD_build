#!/bin/sh
#***********************************************************************
#*                   GNU Lesser General Public License
#*
#* This file is part of the SHiELD Build System.
#*
#* The SHiELD Build System free software: you can redistribute it
#* and/or modify it under the terms of the
#* GNU Lesser General Public License as published by the
#* Free Software Foundation, either version 3 of the License, or
#* (at your option) any later version.
#*
#* The SHiELD Build System distributed in the hope that it will be
#* useful, but WITHOUT ANYWARRANTY; without even the implied warranty
#* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#* See the GNU General Public License for more details.
#*
#* You should have received a copy of the GNU Lesser General Public
#* License along with theSHiELD Build System
#* If not, see <http://www.gnu.org/licenses/>.
#***********************************************************************
#
#  DISCLAIMER: This script is provided as-is and as such is unsupported.
#


hostname=`hostname`

case $hostname in
   gaea6? | c6n* )
      echo " gaea C6 environment "

      . ${MODULESHOME}/init/sh
      module unload PrgEnv-pgi PrgEnv-intel PrgEnv-gnu
      module unload darshan-runtime
      module load   PrgEnv-intel
      module rm intel-classic
      module rm intel-oneapi
      module rm intel
      module rm gcc
      module load intel-classic/2023.2.0
      module unload cray-libsci
      module load cray-hdf5
      module load cray-netcdf
      module load craype-hugepages4M
      #module load cmake/3.23.1
      #module load libyaml/0.2.5

      # Add -DHAVE_GETTID to the FMS cppDefs
      export FMS_CPPDEFS=-DHAVE_GETTID

      # make your compiler selections here
      export FC=ftn
      export CC=cc
      export CXX=CC
      export LD=ftn
      export TEMPLATE=site/intel.mk
      export LAUNCHER=srun

      # highest level of AVX support
      export AVX_LEVEL=-march=core-avx-i
      echo -e ' '
      module list
      ;;
   gaea5? | c5n* )
      echo " gaea C5 environment "

      . ${MODULESHOME}/init/sh
      module unload PrgEnv-pgi PrgEnv-intel PrgEnv-gnu
      module unload darshan-runtime
      module load   PrgEnv-intel
      module rm intel-classic
      module rm intel-oneapi
      module rm intel
      module rm gcc
      module load intel-classic/2023.2.0
      module unload cray-libsci
      module load cray-hdf5/1.12.2.11
      module load cray-netcdf/4.9.0.11
      module load craype-hugepages4M
      module load cmake/3.23.1
      module load libyaml/0.2.5

      # Add -DHAVE_GETTID to the FMS cppDefs
      export FMS_CPPDEFS=-DHAVE_GETTID
      # Needed with the new Environment on C5 as of 10/16/2024
      export FI_VERBS_PREFER_XRC=0

      # make your compiler selections here
      export FC=ftn
      export CC=cc
      export CXX=CC
      export LD=ftn
      export TEMPLATE=site/intel.mk
      export LAUNCHER=srun

      # highest level of AVX support
      export AVX_LEVEL=-march=core-avx-i
      echo -e ' '
      module list
      ;;
   Orion* )
      echo " Orion environment "

      . ${MODULESHOME}/init/sh
      module load intel/2020
      module load impi/2020
      module load netcdf
      module load hdf5
      module load cmake/3.22.1

      export CPATH="${NETCDF}/include:${CPATH}"
      export HDF5=${HDF5_ROOT}
      export LIBRARY_PATH="${LIBRARY_PATH}:${NETCDF}/lib:${HDF5}/lib"
      export NETCDF_DIR=${NETCDF}
      export FMS_CPPDEFS=""

      # make your compiler selections here
      export FC=mpiifort
      export CC=mpiicc
      export CXX=mpicpc
      export LD=mpiifort
      export TEMPLATE=site/intel.mk
      export LAUNCHER=srun

      # highest level of AVX support
      export AVX_LEVEL=-xSKYLAKE-AVX512
      echo -e ' '
      module list
      ;;
   fe* | x* )
      echo " jet environment "

      . ${MODULESHOME}/init/sh
      module purge
      module load newdefaults
      module load intel/2016.2.181 # Jet's default is 15.0.3.187, but this one is 16.0.2.181
      module load szip/2.1
      module load hdf5/1.8.9
      module load netcdf4/4.2.1.1
      module load mvapich2/2.1
      module load cmake/3.20.1

      export LIBRARY_PATH="${LIBRARY_PATH}:${NETCDF4}/lib:${HDF5}/lib"
      export NETCDF_DIR=${NETCDF4}
      export FMS_CPPDEFS=""

      # make your compiler selections here
      export FC=mpiifort
      export CC=mpiicc
      export CXX=mpicpc
      export LD=mpiifort
      export TEMPLATE=site/intel.mk
      export LAUNCHER=srun
      echo -e ' '
      module list
      ;;
   h* )
      echo " hera environment "

      source $MODULESHOME/init/sh
      module load intel/15.1.133
      module load netcdf/4.3.0
      module load hdf5/1.8.14
      module load cmake/3.20.1

      export LIBRARY_PATH="${LIBRARY_PATH}:${NETCDF}/lib:${HDF5}/lib"
      export NETCDF_DIR=${NETCDF}
      export FMS_CPPDEFS=""

      # make your compiler selections here
      export FC=mpiifort
      export CC=mpiicc
      export CXX=mpicpc
      export LD=mpiifort
      export TEMPLATE=site/intel.mk
      export LAUNCHER=srun

      # highest level of AVX support
      export AVX_LEVEL=-xSKYLAKE-AVX512
      echo -e ' '
      module list
      ;;
   lsc* )
      echo " lsc environment "

      source $MODULESHOME/init/sh
      module load oneapi/2023.0
      module load compiler/2023.0.0
      module load mpi/2021.8.0
      module load netcdf/4.9.0
      module load hdf5/1.12.0
      module load cmake/3.18.2

      export CPATH="${NETCDF_ROOT}/include:${CPATH}"
      export NETCDF_DIR=${NETCDF_ROOT}
      export FMS_CPPDEFS=""

      # make your compiler selections here
      export FC=mpiifort
      export CC=mpiicc
      export CXX=mpicpc
      export LD=mpiifort
      export TEMPLATE=site/intel.mk
      export LAUNCHER="mpirun -prepend-rank"

      # highest level of AVX support
      if [ `hostname | cut -c4-6` = "amd" ] ; then
        export AVX_LEVEL=-march=core-avx2
      else
        export AVX_LEVEL=-xSKYLAKE-AVX512
      fi
      echo -e ' '
      module list
      ;;
   stellar* )
     echo " Stellar environment "                                                                                                                            

      . ${MODULESHOME}/init/sh
      module purge
      module load cmake/3.19.7
      module load intel/2021.1.2
      module load openmpi/intel-2021.1/4.1.2
      module load netcdf/intel-2021.1/hdf5-1.10.6/4.7.4
      module load hdf5/intel-2021.1/1.10.6

      export FMS_CPPDEFS=""

      # make your compiler selections here
      export FC=mpif90
      export CC=mpicc
      export CXX=mpicxx
      export LD=mpif90
      export TEMPLATE=site/intel.mk
      export LAUNCHER=srun

      # highest level of AVX support
      export AVX_LEVEL=-march=core-avx2
      echo -e ' '
      module list  
 
      ;;
   * )
      echo " no environment available based on the hostname "
      ;;
esac

