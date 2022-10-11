#!/bin/bash

path_analysis='/data_/tardiflab/mwc'
#
cd $path_analysis/hc27/COMMIT_BZ/tracking/Results_StickZeppelinBall

#PRCG-MEDULLA; PRCG-SUBCORTICAL NUCLEI
mrview ../../../Diffusion/Tractography/T1_on_DTI/T1_to_b0mean_FSLbbr.nii.gz -tractography.load connect2tck_COMMIT/bundle23-36.tck -tractography.tsf_load connect2tck_COMMIT/bundles_23-36.csv -tractography.tsf_range 0,0.5 -tractography.load connect2tck_COMMIT/bundle23-38.tck -tractography.tsf_load connect2tck_COMMIT/bundles_23-38.csv -tractography.tsf_range 0,0.5 -tractography.load connect2tck_COMMIT/bundle23-85.tck -tractography.tsf_load connect2tck_COMMIT/bundles_23-85.csv -tractography.tsf_range 0,0.5 
