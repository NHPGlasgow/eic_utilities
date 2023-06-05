#!/bin/python

import subprocess
import os
import math
import mmap
import numpy as np
import time

workdir = "/w/work5/eic/NHP_test/"
#inDir
workdatadir = workdir + "data/"
#simBase
worklogdir = workdir + "logs/"
workoutdir = workdir + "rootfiles/"
#reconBase
workrecondir = workdir + "recon/"

user = os.environ['USER']
farmlogdir = "/home/" + user + "/ddsim_farm_logs"

pwd = os.environ['PWD']
os.environ['SIM_DIR'] = pwd

if not os.path.exists(workdatadir):
    print("Data directory not valid. Check Paths")
    sys.exit(1)

if not os.path.exists(worklogdir):
    os.makedirs(worklogdir)
if not os.path.exists(workoutdir):
    os.makedirs(worklogdir)
if not os.path.exists(workrecondir):
    os.makedirs(workrecondir)
if not os.path.exists(farmlogdir):
    os.makedirs(farmlogdir)

nskip= 0
neventsim = 10000

os.environ['doSimulation']     = "1"
os.environ['doReconstruction'] = "1"
seedseed    = 12

for file in sorted(os.listdir(workdatadir)):
   # print(file)
    
    os.environ['BASEFILE'] = file
    base = file.split(".")[0]
    os.environ['base']   = base
    #print(file, " ", base)
    totalEvents = 0
    
    if totalEvents==0:
        with open(workdatadir+file,'r') as f:
            contents = mmap.mmap(f.fileno(),0,prot=mmap.PROT_READ)
        
            i = contents.rfind('\nE ')   # search for last occurrence of 'word'
            contents.seek(i+1)             # seek to the location
            line = contents.readline()   #
            totalEvents = int(line.split()[1])+1
        
            print("Total Events: ",totalEvents)
            
            nProc          = int(math.ceil(float(totalEvents)/float(neventsim)))
            print("Submitting ",nProc, " jobs for MC base:", base)
            for i in range(nProc):
            
                print(" Base: ",base," Job: ",i," Start Event: ",str(int(i*neventsim))+"/"+str(totalEvents))
                
                jobName = "EPIC_"+base+"_"+str(i)
                os.environ['JOBNAME'] = jobName
                os.environ['NSKIP']  = str(i*neventsim)
                os.environ['JOB']= str(i)
                os.environ['JUGGLER_N_EVENTS'] = str(neventsim)
                
                outfile = workoutdir + base+"_"+str(i)+".edm4hep.root"
                #if file exists check
                if os.path.isfile(outfile):
                    print("Simulation output file exists already, skipping step.")
                    os.environ['doSimulation'] = 0

                outRecon = workrecondir + base+"_"+str(i)+".root"
                #if file exists check
                if os.path.isfile(outRecon):
                    print("Recon output file exists already, skipping step.")
                    os.environ['doReconstruction'] = 0
                
                #os.environ['runNo']       = str(i)
                #os.environ['eventStart']  = str(int(i*neventsim))
                #os.environ['nEvent']      = str(int(neventsim))
                #os.environ['inFile']      = inFile
                #os.environ['outRecon']     = outRecon
                
                os.environ['seed']        = str(seedseed)
                seedseed = seedseed+1
            
                subprocess.call(["qsub","-V","-q","clas12","-e",farmlogdir,"-o",farmlogdir,"-N",jobName, "jobexec.sh"])
                time.sleep(5)
