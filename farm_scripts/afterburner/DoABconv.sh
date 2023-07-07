#!/bin/bash

print_usage(){
    echo " "
    echo "Usage: DoABconv.sh [path-to-files] [config] [n-segments] [nevents]"
    echo "n-segments: number of segments for file to be split into."
    echo "nevents: number of events per segment"
    echo " "
    echo " -h    print this message"
    echo " -c    print abconv help and config information"
    echo " -d    run script with default settings"
    
}

print_configs(){
    abconv -h
}


if [ "$1" == "-h" ];
then
    print_usage
    exit 0
elif [ "$1" == "-c" ];
then
    print_configs
    exit 0
elif [ "$1" == "-d" ];
then
    echo "Running defaults"
    #=0
elif [ $# == 0 ];
then
    echo "No arguments given. Running defaults."
    print_usage
    exit 2
fi


    
if [ $# -ge 1 ] && [ "$1" != "-d" ]
then
    basedir=$1
else
    basedir="/w/work5/eic/NHP_test/data"
fi

if [ $# -ge 2 ]
then
    config=$1
else 
    config=0 #default abconv config, 0==IP6 High divergence, auto read energy
fi

if [ $# -ge 3 ]
then 
    nseg=$3
else
    nseg=10
fi

if [ $# -ge 4 ]
then
    nevents=$4
else
    nevents=10000
fi
    
outdir=$basedir"/afterburned"
mkdir -p ${outdir}

for file in $basedir/*.hepmc
do
    if [ ! -f $file ];
    then
	echo "No Files not found, check config."
	exit 2
    fi
    
    basefile=${file##*/}
    basefile=${basefile%.hepmc}

    for((seg=0; seg<$nseg; seg++));
    do
	firstevent=$(($seg*$nevents))
	outfile=$outdir/"AB_"$basefile"_"$seg
	echo "segment: $seg    first event: $firstevent    output file: $outfile"
	abconv -p ip6_hidiv_41x5 -s $firstevent -l $nevents --plot-off $file -o $outfile
    done
done

    
