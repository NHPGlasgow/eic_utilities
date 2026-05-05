#!/bin/bash
# Convert all .hepmc files in the current directory to .root

mkdir -p "rootfiles"
mkdir -p "afterburned"

if [ -z "$1"]
then
    abconfig="0"
else
    abconfig=$1
fi

for f in *.hepmc; do
    # remove extension and append .root
    base="${f%.hepmc}"
    new="${base}.hepmc3.tree.root"
    
    ab="ab_${base}"
    abfile="ab_${base}.hepmc"
    newab="ab_${base}.hepmc3.tree.root"

    # Example conversion command (replace with your actual converter)
    # e.g.: HepMC2Root "$f" "$new"
    echo "Converting $f -> $new,"
    echo "Afterburning $f -> $ab,"
    echo "Converting $abfile -> $newab."
    
    if [ ! -f "rootfiles/"$new ]
    then
	~/hepmc3ascii2root/install/bin/hepmc3ascii2root "$f" "$new"
    else
	echo "$new exists, skipping conversion"
    fi
    
    if [ ! -f "afterburned"/$abfile ]
    then
	#echo "abconv -p $abconfig $f -o $ab"
	abconv -p $abconfig $f -o $ab
    else
	echo "$abfile exists, skipping abconv"
    fi

    if [ ! -f "afterburned/"$newab ]
    then
	~/hepmc3ascii2root/install/bin/hepmc3ascii2root "$abfile" "$newab"
    else
	echo "$new exists, skipping conversion"
    fi

done

mv ab_* afterburned/
mv *.root rootfiles/
 
