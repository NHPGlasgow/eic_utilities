#PBS -N EPIC
#PBS -V 
#PBS -l walltime=99:00:00,file=200000000kb

#echo $PWD
cd $SIM_DIR
cvmfs_config probe
singularity exec --bind /w,/scratch /cvmfs/singularity.opensciencegrid.org/eicweb/jug_xl:nightly ddsim.sh
