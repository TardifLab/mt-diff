#!/bin/bash

# LINES 72, 90, 91, 96: EDIT IF NUMBER OF VOLUMES IS DIFFERENT FROM 31

#VARS 4 COLOURED TEXT OUTPUT
RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[1;33m'
BLU='\033[0;34m'
VIO='\033[0;35m'
#
# VARS 4 COLURED BACKGROUNDS
REDbg='\033[41m'
GRNbg='\033[42m'
YELbg='\033[43m'
BLUbg='\033[44m'
VIObg='\033[45m'
#
#
RES='\033[0m' # RESETS ALL ATTRIBUTES
#
path_data='/data_/tardiflab/mwc' #'/media/diffusion/Volume/Pietro/COMMIT/for-simona/validation_BIAS_no_norm_zeppelin'
path_fs_subj='/data_/tardiflab/mwc' #'/media/diffusion/Volume/Pietro/COMMIT/for-simona/validation_BIAS_no_norm_zeppelin'
path_analysis='/data_/tardiflab/mwc' # '/media/diffusion/Volume/Pietro/COMMIT/for-simona/validation_BIAS_no_norm_zeppelin'

cd $path_data

# mkdir $path_fs_subj

#
start_all=`date +%s`
rootDIR=$(pwd)
for patient_folder in `find $path_data -maxdepth 1 -type d -name $1 | sort -g`; do
#
echo -e "\n\n ${REDbg} Working in Folder  $RES \n $patient_folder"
#
cd $patient_folder

patient_folder_name=$(basename $patient_folder)

# # FREESURFER
cd ${patient_folder}/anat
work_dir=$(pwd)
echo segmentBS.sh freeSurfer $work_dir
if [ ! -f "freeSurfer/mri/brainstemSsLabels.v12.mgz" ]; then
	segmentBS.sh freeSurfer $work_dir
fi
echo -e "--is done\n"

# # COPY DIFFUSION FILES
cd $patient_folder
mkdir Diffusion
cd Diffusion
mkdir preprocessing
cd preprocessing
pwd

if [ ! -f "dwi_MT_off.nii.gz" ]; then
	cp ../../mt-diff/irl_ep2d_nomt_diff_PL_irl*.nii dwi_MT_off.nii
	cp ../../mt-diff/irl_ep2d_nomt_diff_PL_b0PA*.nii dwi_MT_off_PA.nii
	cp ../../mt-diff/irl_ep2d_mt_diff_PL_irl*.nii dwi_MT_on.nii
	cp ../../mt-diff/irl_ep2d_nomt_diff_PL_irl_ep2d_nomt_diff_PL_*.bvec dwi.bvecs
	cp ../../mt-diff/irl_ep2d_nomt_diff_PL_irl_ep2d_nomt_diff_PL_*.bval dwi.bvals
	gzip *.nii
fi

# # CONCATENATE BVECS AND BVALS FILE FOR TOPUP
paste -d " " dwi.bvecs dwi.bvecs > dwi_merge.bvecs
paste -d " " dwi.bvals dwi.bvals > dwi_merge.bvals

# # CREATE NECESSARY FILES FOR TOPUP AND EDDY
cat > dwi_acq_par.txt << ENDOFFILE
0 1 0 0.05
0 -1 0 0.05
ENDOFFILE

# MODIFY IF NUMBER OF VOLUMES DIFFERS FROM 31
cat > dwi_index.txt << ENDOFFILE
1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1
ENDOFFILE

paste -d " " dwi_index.txt dwi_index.txt > dwi_index_merge.txt

# # TOPUP
#fslroi dwi_MT_off dwi_AP 0 1
mrconvert -coord 3 0:0 dwi_MT_off.nii.gz dwi_AP.nii.gz
#fslroi dwi_MT_off_PA dwi_PA 0 1
#mrconvert -coord 3 0:0 dwi_MT_off_PA.nii.gz dwi_PA.nii.gz
#fslmerge -t dwi_AP_PA dwi_AP dwi_PA
mrcat dwi_AP.nii.gz dwi_MT_off_PA.nii.gz dwi_AP_PA.nii.gz

echo topup --imain=dwi_AP_PA.nii.gz --datain=dwi_acq_par.txt --out=dwi_AP_PA_topup --config=b02b0.cnf -v
if [ ! -f "dwi_AP_PA_topup_fieldcoef.nii.gz" ]; then
	topup --imain=dwi_AP_PA.nii.gz --datain=dwi_acq_par.txt --out=dwi_AP_PA_topup --config=b02b0.cnf -v
fi

# # EDDY
#fslmerge -t dwi_merge dwi_MT_off dwi_MT_on
mrcat -axis 3 dwi_MT_off.nii.gz dwi_MT_on.nii.gz dwi_merge.nii.gz
dwidenoise dwi_merge.nii.gz dwi_merge_dn.nii.gz
bet dwi_AP dwi_AP_brain -m

echo eddy_openmp --imain=dwi_merge_dn.nii.gz --mask=dwi_AP_brain_mask --acqp=dwi_acq_par.txt --index=dwi_index_merge.txt --bvecs=dwi_merge.bvecs --bvals=dwi_merge.bvals --out=dwi_merge_dn_dw.nii.gz --topup=dwi_AP_PA_topup -v
if [ ! -f "dwi_merge_dn_dw.nii.gz" ]; then
	eddy_openmp --imain=dwi_merge_dn.nii.gz --mask=dwi_AP_brain_mask --acqp=dwi_acq_par.txt --index=dwi_index_merge.txt --bvecs=dwi_merge.bvecs --bvals=dwi_merge.bvals --out=dwi_merge_dn_dw.nii.gz --topup=dwi_AP_PA_topup -v
fi

# MODIFY IF NUMBER OF VOLUMES DIFFERS FROM 31
#fslroi dwi_merge_dn_dw dwi_MT_off_dn_dw 0 31
mrconvert -coord 3 0:30 dwi_merge_dn_dw.nii.gz dwi_MT_off_dn_dw.nii.gz
#fslroi dwi_merge_dn_dw dwi_MT_on_dn_dw 31 31
mrconvert -coord 3 31:end dwi_merge_dn_dw.nii.gz dwi_MT_on_dn_dw.nii.gz

bet dwi_MT_off_dn_dw dwi_MT_off_dn_dw_brain -m

cp dwi.bvals ../dwi_preproc.bvals
# MODIFY IF NUMBER OF VOLUMES DIFFERS FROM 31
awk '{for(i=1;i<=31;i++) printf $i" "; print ""}' dwi_merge_dn_dw.nii.gz.eddy_rotated_bvecs > ../dwi_preproc.bvecs

# # B1 CORRECTION
dwibiascorrect ants -fslgrad ../dwi_preproc.bvecs ../dwi_preproc.bvals dwi_MT_off_dn_dw.nii.gz dwi_MT_off_dn_dw_db.nii.gz -mask dwi_MT_off_dn_dw_brain_mask.nii.gz
dwibiascorrect ants -fslgrad ../dwi_preproc.bvecs ../dwi_preproc.bvals dwi_MT_on_dn_dw.nii.gz dwi_MT_on_dn_dw_db.nii.gz -mask dwi_MT_off_dn_dw_brain_mask.nii.gz

# fslview_deprecated dwi_MT_off_dn_dw.nii.gz dwi_MT_on_dn_dw.nii.gz &
echo "done"
done

