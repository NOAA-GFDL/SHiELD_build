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
   gaea5? | c5n* )
      echo " gaea C5 environment "
      . ${MODULESHOME}/init/sh
       module unload PrgEnv-pgi PrgEnv-intel PrgEnv-gnu
       module rm intel-classic
       module rm intel-oneapi
       module rm intel
       module load   PrgEnv-gnu
       module rm gcc
       module load gcc/10.3.0
       module load cray-hdf5/1.12.2.3
       module load cray-netcdf/4.9.0.3
       module load craype-hugepages4M
       module load cmake/3.23.1
       module load python/3.9
       module load libyaml/0.2.5

       # make your compiler selections here
       export FC=ftn
       export CC=cc
       export CXX=CC
       export LD=ftn
       export TEMPLATE=site/gnu.mk
       export LAUNCHER=srun

       # highest level of AVX support
       export AVX_LEVEL=-march=native

       echo -e ' '
       module list
       ;;
   gaea1? | nid* )
       echo " gaea C3/C4 environment "

       . ${MODULESHOME}/init/sh
       module unload PrgEnv-pgi PrgEnv-intel PrgEnv-gnu
       module rm intel-classic
       module rm intel-oneapi
       module rm intel
       module load   PrgEnv-gnu
       module rm gcc
       module load gcc/10.3.0
       module load cray-hdf5/1.12.1.3
       module load cray-netcdf/4.8.1.3
       module load craype-hugepages4M
       module load cmake/3.20.1
       module load python/3.9
       module load libyaml/0.2.5

       # make your compiler selections here
       export FC=ftn
       export CC=cc
       export CXX=CC
       export LD=ftn
       export TEMPLATE=site/gnu.mk
       export LAUNCHER=srun

       # highest level of AVX support
       export AVX_LEVEL=-march=native

       echo -e ' '
       module list
       ;;
   Orion* )
       echo " Orion environment "

       . ${MODULESHOME}/init/sh
       module load gcc/10.2.0
       module load impi/2021.2
       module load netcdf
       module load hdf5
       module load cmake/3.22.1

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
       export AVX_LEVEL=-march=native

       echo -e ' '
       module list
       ;;
   fe* | x* )
       echo " jet environment "

       . ${MODULESHOME}/init/sh
       module purge
       module load gnu/9.2.0
       module load impi/2020
       module load hdf5/1.10.5
       module load netcdf4/4.7.2
       module load cmake/3.20.1

       export LIBRARY_PATH="${LIBRARY_PATH}:${NETCDF4}/lib:${HDF5}/lib"
       export NETCDF_DIR=${NETCDF4}

       # make your compiler selections here
       export FC=mpif90
       export CC=mpicc
       export CXX=mpicxx
       export LD=mpif90
       export TEMPLATE=site/gnu.mk
       export LAUNCHER=srun

       # highest level of AVX support
       export AVX_LEVEL=-march=native

       echo -e ' '
       module list
       ;;
   h* )
       echo " hera environment "

       source $MODULESHOME/init/sh
       module load gnu/9.2.0
       module load impi/2020
       module load netcdf/4.7.2
       module load hdf5/1.10.5
       module load cmake/3.20.1

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
       export AVX_LEVEL=-march=native

       echo -e ' '
       module list
       ;;
   lsc* )
       echo " lsc environment "

       source $MODULESHOME/init/sh
       module load gcc/12.2.0
       module load openmpi/4.1.4
       module load netcdf/4.9.0
       module load hdf5/1.12.0
       module load cmake/3.18.2

       export CPATH="${NETCDF_ROOT}/include:${CPATH}"
       export NETCDF_DIR=${NETCDF_ROOT}

       # make your compiler selections here
       export FC=mpif90
       export CC=mpicc
       export CXX=mpicxx
       export LD=mpif90
       export TEMPLATE=site/gnu.mk
       export LAUNCHER="mpirun -tag-output"

       # highest level of AVX support
       export AVX_LEVEL=-march=native

       echo -e ' '
       module list
       ;;
   * )
       echo " no environment available based on the hostname "
       ;;
esac
