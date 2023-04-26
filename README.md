# eic_utilities

eic_utilities is a collection of example and template scripts to help Glasgow users quickly integrate into the EIC workflow. \
For a more comprehensive set of tutorials see: \
[BNL Indico](https://indico.bnl.gov/category/443/)

## farm_scripts
Example batch and farm submission wrapper scripts \
wrapper.sh - top level wrapper for jobs. user env variables set at this point \
jobexec.sh - enters eic-shell on farm and submits simulation \
ddsim.sh - simulation shell script \

## analysis_scripts:
SimpleAna.sh - 

## S3 storage, minio client mc
[S3 Directory](https://dtn01.sdcc.bnl.gov:9001)
```bash
export S3_ACCESS_KEY="ask in mattermost, teams or office" 
export S3_SECRET_KEY="ask in mattermost, teams or office" 
mc config host add S3 https://dtn01.sdcc.bnl.gov:9001 $S3_ACCESS_KEY $S3_SECRET_KEY 
mc ls S3/eictest/EPIC/Tutorials 
```

#TBD
```diff
-SimpleAna.sh written and working
-EIC-Recon added to farm scripts
```

