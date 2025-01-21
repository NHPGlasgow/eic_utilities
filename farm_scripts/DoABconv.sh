#!/bin/bash

if [ $# -lt 1 ];
then
    echo "No arguments given. Provide full path to hepmc file to be afterburned,and optionally a number of segments and number of events per segement (otherwise defaults to all events split into 10k segments."
    exit 2
fi

file=$1

if [ ! -f $file ];
then
    echo "File not found, check config."
    exit 2
fi


if [ $# -gt 1 ]
then
    nseg=$2
else
    nseg=$(grep -c "E " $file)/10000
fi


if [ $# -gt 2 ]
then
    nevent=$3
else
    nevent=10000
fi

basedir=${file%/*}
basefile=${file##*/}
basefile=${basefile%.hepmc}

for((seg=0; seg<$nseg; seg++));
do
    firstevent=$(($seg*$nevent))
    ##IMPORTANT!! outfile in abconv takes no extension (i.e. do not add .hepmc or .root, or your output file will be "$outfile.root.root", etc!)
    outfile=$basedir"_"$seg
    #echo $outfile
    #abconv -p ip6_hidiv_41x5 -s $firstevent -l $nevent --plot-off $file -o $outfile
done

#abconv -p ip6_hidiv_41x5 -s 0 -e 99 --plot-off $file -o test
