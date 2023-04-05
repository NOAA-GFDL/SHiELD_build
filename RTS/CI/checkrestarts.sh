#!/bin/bash
#This script counts the number of rundirs in the CI/BATCH-CI directory and lists the restart files output for each rundir.
#This is used as a sanity check to verify all tests have run and finished
count=0
for TEST in $(ls /lustre/f2/scratch/Lauren.Chilutti/SHiELDCI_c5_202204/CI/BATCH-CI)
do
    echo $TEST
    let count++
    ls /lustre/f2/scratch/Lauren.Chilutti/SHiELDCI_c5_202204/CI/BATCH-CI/$TEST/RESTART
done
printf "count=%d\n" $count
