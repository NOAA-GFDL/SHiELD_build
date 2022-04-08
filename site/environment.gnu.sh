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


if [ `hostname | cut -c1-4` = "gaea" ] || [ `hostname | cut -c1-3` = "nid" ] ; then
   echo " gaea environment "

   . ${MODULESHOME}/init/sh
   module unload PrgEnv-pgi PrgEnv-intel PrgEnv-gnu
   module rm intel
   module load   PrgEnv-gnu
   module rm gcc
   module load gcc/9.2.0
   module load cray-netcdf
   module load craype-hugepages4M

   # make your compiler selections here
   export FC=ftn
   export CC=cc
   export CXX=CC
   export LD=ftn
   export TEMPLATE=site/gnu.mk
   export LAUNCHER=srun

   # highest level of AVX support
   export AVX_LEVEL=-xCORE-AVX2


elif [ `hostname | cut -c1-5` = "Orion" ] ; then
   echo " Orion environment "

   . ${MODULESHOME}/init/sh
   module load gcc/10.2.0
   module load impi/2021.2
   module load netcdf
   module load hdf5

   export CPATH="${NETCDF}/include:${CPATH}"
   export HDF5=${HDF5_ROOT}
   export LIBRARY_PATH="${LIBRARY_PATH}:${NETCDF}/lib:${HDF5}/lib"
   export NETCDF_DIR=${NETCDF}

   # make your compiler selections here
   export FC=mpif90
   export CC=mpicc
   export CXX=mpicxx
   export LD=mpif90
   export TEMPLATE=site/gnu.mk
   export LAUNCHER=srun

   # highest level of AVX support
   export AVX_LEVEL=-xSKYLAKE-AVX512


elif [ `hostname | cut -c1-2` = "fe" ] || [ `hostname | cut -c1` = "x" ] ; then
   echo " jet environment "

   . ${MODULESHOME}/init/sh
   module purge
   module load gnu/9.2.0
   module load impi/2020
   module load hdf5/1.10.5
   module load netcdf4/4.7.2

   export LIBRARY_PATH="${LIBRARY_PATH}:${NETCDF4}/lib:${HDF5}/lib"
   export NETCDF_DIR=${NETCDF4}

   # make your compiler selections here
   export FC=mpif90
   export CC=mpicc
   export CXX=mpicxx
   export LD=mpif90
   export TEMPLATE=site/gnu.mk
   export LAUNCHER=srun

elif [ `hostname | cut -c1` = "h" ] ; then
   echo " hera environment "

   source $MODULESHOME/init/sh
   module load gnu/9.2.0
   module load impi/2020
   module load netcdf/4.7.2
   module load hdf5/1.10.5

   export LIBRARY_PATH="${LIBRARY_PATH}:${NETCDF}/lib:${HDF5}/lib"
   export NETCDF_DIR=${NETCDF}

   # make your compiler selections here
   export FC=mpif90
   export CC=mpicc
   export CXX=mpicxx
   export LD=mpif90
   export TEMPLATE=site/gnu.mk
   export LAUNCHER=srun

   # highest level of AVX support
   export AVX_LEVEL=-xSKYLAKE-AVX512

elif [ `hostname | cut -c1-3` = "lsc" ] ; then
   echo " lsc environment "

   source $MODULESHOME/init/sh
   module load gcc/10.2.0
   module load impi/2020
   module load netcdf/4.8.0
   module load hdf5/1.12.0

   export CPATH="${NETCDF_ROOT}/include:${CPATH}"
   export NETCDF_DIR=${NETCDF_ROOT}

   # make your compiler selections here
   export FC=mpif90
   export CC=mpicc
   export CXX=mpicxx
   export LD=mpif90
   export TEMPLATE=site/gnu.mk
   export LAUNCHER=mpirun

   # highest level of AVX support
   export AVX_LEVEL=-xSKYLAKE-AVX512
#   export AVX_LEVEL=-march=core-avx2

else

   echo " no environment available based on the hostname "

fi

