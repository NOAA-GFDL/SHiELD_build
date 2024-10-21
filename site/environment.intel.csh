#!/bin/csh
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


set hostname=`hostname`

switch ($hostname)
   case gaea6?:
   case c6n*:
      echo " gaea C6 environment "

      source ${MODULESHOME}/init/csh
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
      setenv FMS_CPPDEFS "-DHAVE_GETTID"

      # make your compiler selections here
      setenv FC "ftn"
      setenv CC "cc"
      setenv CXX "CC"
      setenv LD "ftn"
      setenv TEMPLATE "site/intel.mk"
      setenv LAUNCHER "srun"

      # highest level of AVX support
      setenv AVX_LEVEL "-march core-avx2"
      echo -e ' '
      module list
      breaksw
   case gaea5?:
   case c5n*:
      echo " gaea C5 environment "

      source ${MODULESHOME}/init/csh
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
      setenv FMS_CPPDEFS "-DHAVE_GETTID"
      # Needed with the new Environment on C5 as of 10/16/2024
      setenv FI_VERBS_PREFER_XRC 0

      # make your compiler selections here
      setenv FC "ftn"
      setenv CC "cc"
      setenv CXX "CC"
      setenv LD "ftn"
      setenv TEMPLATE "site/intel.mk"
      setenv LAUNCHER "srun"

      # highest level of AVX support
      setenv AVX_LEVEL "-march core-avx2"
      echo -e ' '
      module list
      breaksw
   default:
      echo " no environment available based on the hostname "
      breaksw
endsw

