#!/bin/bash

# Convert all .hepmc files in the current directory to .hepmc3.tree.root
# to rootfiles/
# Afterburn all .hepmc files in the current directory
# to afterburned/

mkdir -p "rootfiles"
mkdir -p "afterburned"

if [ -z "$1" ]
then
    abconfig="0"
else
    abconfig=$1
fi

for f in *.hepmc; do
    # remove extension and append .root
    base="${f%.hepmc}"
    new="rootfiles/${base}.hepmc3.tree.root"
    
    ab="afterburned/ab_${base}"
    newab="${ab}.hepmc3.tree.root"

    # Example conversion command (replace with your actual converter)
    # e.g.: HepMC2Root "$f" "$new"
    echo "Converting $f -> $new,"
    echo "Afterburning $f -> $ab,"
    
    if [ ! -f $new ]
    then
	~/hepmc3ascii2root/install/bin/hepmc3ascii2root "$f" "$new"
    else
	echo "$new exists, skipping conversion"
    fi

    
    if [ ! -f $newab ]
    then
	abconv -p $abconfig $f -o $ab --plot-off
    else
	echo "$abfile exists, skipping abconv"
    fi

    

done
 
