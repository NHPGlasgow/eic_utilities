# eic_utilities

eic_utilities is a collection of example and template scripts to help Glasgow users quickly integrate into the EIC workflow. \
For a more comprehensive set of tutorials see: \
[BNL Indico](https://indico.bnl.gov/category/443/)

## farm_scripts
Example batch and farm submission wrapper scripts \
wrapper.sh - top level wrapper for jobs. user env variables set at this point \
jobexec.sh - enters eic-shell on farm and submits simulation \
ddsim.sh - afterburn, simulation and reconstruction shell script \

## analysis_scripts:
SimpleAna.sh - 

## XRootD File Access
Example usage:
```bash
xrdfs dtn-eic.jlab.org ls /work/eic2/
```

#TBD
```diff
-Analysis macros retired / deleted in favour of RAD analysis style
```

