#!/bin/tcsh
# This scriptcompares the restarts fom the CI test results
# You need to manually update the path to run1 and run2 of which run1 should be your baseline and run2 should be your test
# Usually this is run after the checkrestarts script

module load fre/bronx-20

set run1 = "/lustre/f2/dev/Lauren.Chilutti/BASELINES"
set run2 = "/lustre/f2/scratch/Lauren.Chilutti/SHiELDCI_2022.04_330/CI/BATCH-CI"

cd $run1
foreach TEST ( C* d* )
    cd $TEST/RESTART
    echo "Comparing ${TEST}"
    foreach FILE ( *.nc )
        echo "Comparing ${FILE}"
        nccmp -d $FILE $run2/$TEST/RESTART/$FILE
    end
    cd ..
end

