# SHiELD Build System

The scripts contained herein can be used to build GFDL's SHiELD and FV3 Solo models.

# What files are what

The top level directory structure groups source code and input files as follow:

| File/directory       | Purpose |
| --------------       | ------- |
| ```LICENSE.md```     | copy of the Gnu Lesser General Public license, version 3 |
| ```README.md```      | this file with basic pointers to more information |
| ```CHECKOUT_code```  | script to download necessary source for proper build GFDL's SHield and FV3 Solo models <sup>*</sup>|
| ```Build/```         | contains scripts used for building models listed above |
| ```mkmf/```          | submodule entry point for the externally managed [mkmf software](https://github.com/NOAA-GFDL/mkmf) |
| ```RTS/```           | contains scripts for use in CI software regression testing (see [RTS/README.md](https://github.com/NOAA-GFDL/SHiELD_build/blob/main/RTS/README.md))|
| ```site/```          | contains site specific scripts and compiler make templates |

<sup>*</sup>By default, ```CHECKOUT_code``` checks out the latest main branch from each repository, which may include experimental features

# Compiling

Be sure to download the mkmf submodule prior to beginning.  To use:

 1) Checkout code via CHECKOUT_code script
    - ./CHECKOUT_code will checkout necessary files for shields (running with either simple or full coupler)
    - ./CHECKOUT_code will automatically run ./CHECKOUT_mom6 for mom6/sis2 files

 2) cd Build and execute ./COMPILE script with the --help option to see usage

 3) COMPILE:
    - ./COMPILE shield:     will compile shield with simple coupler
    - ./COMPILE shieldfull: will compile shield with full coupler (utilizing null modules for ocean, land, ice)
    - ./COMPILE shiemom:    will compile mom6, sis2, fv3, gfs as libraries and link them to the full coupler (no null ocean and ice modules.)

      Example: ./COMPILE shield nh repro 32bit intel

For instructions on transitioning or running SHiELD with the FMS full coupler infrastructure, please refer to the documentation and resources available at [doi.org/10.25923/ezfm-az21][https://repository.library.noaa.gov/view/noaa/66759]

# Disclaimer

The United States Department of Commerce (DOC) GitHub project code is provided
on an "as is" basis and the user assumes responsibility for its use. DOC has
relinquished control of the information and no longer has responsibility to
protect the integrity, confidentiality, or availability of the information. Any
claims against the Department of Commerce stemming from the use of its GitHub
project will be governed by all applicable Federal law. Any reference to
specific commercial products, processes, or services by service mark,
trademark, manufacturer, or otherwise, does not constitute or imply their
endorsement, recommendation or favoring by the Department of Commerce. The
Department of Commerce seal and logo, or the seal and logo of a DOC bureau,
shall not be used in any manner to imply endorsement of any commercial product
or activity by DOC or the United States Government.

This project code is made available through GitHub but is managed by NOAA-GFDL
at https://gitlab.gfdl.noaa.gov.
