#!/bin/bash

#if [ $# == 0 ];
#then
#    echo "No arguments given"
#    exit 2
#fi

#config=$1
config="5x41"

basedir="/w/work5/home/garyp/eic/Generators/Topeg/HepMC/June_2022"

file=$basedir"/eA-"$config"-M3-Ph.hepmc"

if [ ! -f $file ];
then
    echo "File not found, check config."
    exit 2
fi

nseg=100
nevent=10000
for((seg=0; seg<$nseg; seg++));
do
    firstevent=$(($seg*$nevent))
    echo $firstevent
    outfile="/scratch/garyp/Topeg_eHe4_"$config"_"$seg
    abconv -p ip6_hidiv_41x5 -s $firstevent -l $nevent --plot-off $file -o $outfile
done

#abconv -p ip6_hidiv_41x5 -s 0 -e 99 --plot-off $file -o test
