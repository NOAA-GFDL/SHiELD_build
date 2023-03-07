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

if [ `hostname | cut -c1-3` = "lsc" ] ; then
   echo " lsc environment "

   source $MODULESHOME/init/sh
   module load nvhpc/23.1
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
   export TEMPLATE=site/nvhpc.mk
   export LAUNCHER="mpirun -tag-output"

   # highest level of AVX support
   if [ `hostname | cut -c4-6` = "amd" ] ; then
     export AVX_LEVEL=
   else
     export AVX_LEVEL=
   fi

   echo -e ' '
   module list

else

   echo " no environment available based on the hostname "

fi

