#!/bin/tcsh

module load fre/bronx-19

echo "This script compares RESTARTS"

set C768 = "y"
set C768RES = "20160801.00Z.C768.nh.32bit.non-mono.C768/restart/2016080101"

set C768r15n3 = "n"
set C768r15n3RES = "20170501.00Z.C768r15n3_hwt.nh.32bit.non-monoC768r15n3/rundir/RESTART"

set C48_RES = "y"
set C48_RESRES = "20160801.00Z.C48.nh.32bit.non-mono.C48_res/restart/2016080200"

set REGIONAL = "y"
set REGIONALRES = "20170114.00Z.C3072_alaska.nh.32bit.non-monoRegional3km/restart/2017011500"

set C48n4 = "y"
set C48n4RES = "20150801.00Z.C48n4.nh.32bit.non-mono.C48n4/restart/2015080300"

set C48_4n2 = "n"
set C48_4n2RES = "20200826.12Z.C48.nh.32bit.non-mono.C48_4n2/rundir/RESTART"

source fms_test.csh
set OLDDIR = "/lustre/f2/dev/Lauren.Chilutti/BASELINES"

set NEWDIR = ${SCRATCH}/${USER}/SHiELD_${COMPILER}_${DESCRIPTOR}_${BIT}

if ( $C768 == "y" ) then
  cd $OLDDIR/20160801.00Z.C768.nh.32bit.non-mono.C768
  echo "C768"
  foreach FILE ( *.nc )
      echo "Comparing ${FILE}"
      nccmp -df $FILE $NEWDIR/$C768RES/$FILE
  end
endif

if ( $C768r15n3 == "y" ) then
  cd $OLDDIR/20170501.00Z.C768r15n3_hwt.nh.32bit.non-monoC768r15n3
  echo "C768r15n3"
  foreach FILE ( *.nc )
      echo "Comparing ${FILE}"
      nccmp -df $FILE $NEWDIR/$C768r15n3RES/$FILE
  end
endif

if ( $C48_RES == "y" ) then
  cd $OLDDIR/20160801.00Z.C48.nh.32bit.non-mono.C48_res
  echo "C48_res"
  foreach FILE ( *.nc )
      echo "Comparing ${FILE}"
      nccmp -df $FILE $NEWDIR/$C48_RESRES/$FILE
  end
endif

if ( $REGIONAL == "y" ) then
  cd $OLDDIR/20170114.00Z.C3072_alaska.nh.32bit.non-monoRegional3km
  echo "Regional_3km"
  foreach FILE ( *.nc )
      echo "Comparing ${FILE}"
      nccmp -df $FILE $NEWDIR/$REGIONALRES/$FILE
  end
endif

if ( $C48n4 == "y" ) then
  cd $OLDDIR/20150801.00Z.C48n4.nh.32bit.non-mono.C48n4
  echo "C48n4"
  foreach FILE ( *.nc )
      echo "Comparing ${FILE}"
      nccmp -df $FILE $NEWDIR/$C48n4RES/$FILE
  end
endif

if ( $C48_4n2 == "y" ) then
  cd $OLDDIR/$C48_4n2RES
  echo "C48_4n2"
  foreach FILE ( *.nc )
      echo "Comparing ${FILE}"
      nccmp -df $FILE $NEWDIR/$C48_4n2RES/$FILE
  end
endif
