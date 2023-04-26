eic_utilities
----------------------

#for a comprehensive set of tutorials
https://indico.bnl.gov/category/443/

#example farm/batch submission scripts
farm_scripts:
wrapper.sh - top level wrapper for jobs. user env variables set at this point
jobexec.sh - enters eic-shell on farm and submits simulation
ddsim.sh - simulation shell script
----------------------

#TBD EIC-Recon added to farm scripts
----------------------

#example analysis scripts
analysis_scripts:

----------------------

#remote location of Simulation outputs at BNL
#S3 storage, minio client mc
export S3_ACCESS_KEY=[ask in mattermost, teams or office]
export S3_SECRET_KEY=[ask in mattermost, teams or office]
mc config host add S3 https://eics3.sdcc.bnl.gov:9000 $S3_ACCESS_KEY $S3_SECRET_KEY
mc ls S3/eictest/EPIC/Tutorials
----------------------

S3 Directory:
https://dtn01.sdcc.bnl.gov:9001
----------------------