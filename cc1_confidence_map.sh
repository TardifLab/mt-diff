#!/bin/bash
path_analysis='/data_/tardiflab/mwc'
#
cd $path_analysis
#
start_all=`date +%s`
rootDIR=$(pwd)
for patient_folder in `find $path_data -maxdepth 1 -type d -name $1 | sort -g`; do
#
echo "====Running ${0}" 
echo -e "\n\n ${REDbg} Working in Folder  $RES \n $patient_folder"
#
cd $patient_folder/Diffusion/preprocessing
#
#
# IRL Aug 9 2022
# have to make sure we don't have Nan, otherwise the confidence map is empty!
#echo mrcalc ../dwi_preproc_B1corr_upsampl.nii.gz ../dwi_preproc_B1corr_upsampl_MT_on.nii.gz -sub ../Tractography/T1_on_DTI/WM_mask_to_b0.nii.gz -mult 1 -gt ../dwi_preproc_B1corr_upsampl.nii.gz ../dwi_preproc_B1corr_upsampl_MT_on.nii.gz -sub ../Tractography/T1_on_DTI/WM_mask_to_b0.nii.gz -mult 0 -lt -5 -mult -add - | mrmath - mean -axis 3 ../confidence_map_3D.nii.gz

#mrcalc ../dwi_preproc_B1corr_upsampl.nii.gz ../dwi_preproc_B1corr_upsampl_MT_on.nii.gz -sub ../Tractography/T1_on_DTI/WM_mask_to_b0.nii.gz -mult 1 -gt ../dwi_preproc_B1corr_upsampl.nii.gz ../dwi_preproc_B1corr_upsampl_MT_on.nii.gz -sub ../Tractography/T1_on_DTI/WM_mask_to_b0.nii.gz -mult 0 -lt -5 -mult -add - | mrmath - mean -axis 3 ../confidence_map_3D.nii.gz

fslmaths ../dwi_preproc_B1corr_upsampl_MT_on.nii.gz -nan tmp-mton
fslmaths ../dwi_preproc_B1corr_upsampl.nii.gz -sub tmp-mton -mul ../Tractography/T1_on_DTI/WM_mask_to_b0.nii.gz tmp
echo fslmaths ../dwi_preproc_B1corr_upsampl.nii.gz -sub tmp-mton -mul ../Tractography/T1_on_DTI/WM_mask_to_b0.nii.gz tmp
fslmaths tmp -thr 0 -bin tmp_bin_pos
fslmaths tmp -uthr 0 -abs -bin -mul -5 tmp_bin_neg
fslmaths tmp_bin_pos -add tmp_bin_neg -Tmean tmp_bin_avg
fslmaths tmp_bin_avg -thr 0 ../confidence_map_3D
rm tmp*.nii.gz
#fsleyes ../confidence_map_3D
#
done
