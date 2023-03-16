#!/bin/bash
#
# Script written by Simona Schiavi
# If you need further assistance, to report any bug or for suggestions
# please contact: simona.schiavi@polytechnique.edu
# (do not hesitate to cite the authors anywhere if you use this script :-p )
#
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# !!!!! ATTENZIONE MODIFICA ALLA RIGA 231 !!!!!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
#
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
#
path_data='/data_/tardiflab/mwc'
path_fs_subj='/data_/tardiflab/mwc'
path_fs_file='/data_/tardiflab/01_programs/mrtrix3/share/mrtrix3/labelconvert'
path_analysis='/data_/tardiflab/mwc'
#
cd $path_analysis #
#
echo "====Running ${0}" 
start_all=`date +%s`
rootDIR=$(pwd)
for patient_folder in `find $path_data -maxdepth 1 -type d -name $1 | sort -g`; do
#
echo -e "\n\n ${REDbg} Working in Folder  $RES \n $patient_folder"
#
cd $patient_folder
patient_folder_name=$(basename $patient_folder)

#-----------------------------------------------------------------------------------------------------------------
# Creo cartelle dove fare trattografia
mkdir $path_analysis'/'$patient_folder_name
cd $path_analysis'/'$patient_folder_name
cd Diffusion
mkdir Tractography
#
# Upsampling diffusion images
# !!! UNTIL WE DO NOT FIND AN OPTIMAL SOLUTION FOR BIAS REMOVAL WE USE THE NOT BIAS CORRECTED IMAGES, I.E.: dwi_MT_off_dn_dw.nii.gz AND dwi_MT_on_dn_dw.nii.gz. FOR THE UPSAMPLED IMAGES WE LEAVE THE "B1corr" SUFFIX EVEN IF NOT REALLY B1 CORRECTED (OTHERWISE SEVERAL SCRIPTS SHOULD BE MODIFIED ACCORDINGLY) !!!
mrgrid -voxel 1 -interp linear $path_data'/'$patient_folder_name'/Diffusion/preprocessing/dwi_MT_off_dn_dw_db.nii.gz' regrid dwi_preproc_B1corr_upsampl.nii.gz
#
mrgrid -voxel 1 -interp linear $path_data'/'$patient_folder_name'/Diffusion/preprocessing/dwi_MT_on_dn_dw_db.nii.gz' regrid dwi_preproc_B1corr_upsampl_MT_on.nii.gz
#
# Upsampling MT on images and b0 substitution with b0 MT off: comment for other processing
# IRL 2023-02-02
# Don't replace the b=0 for MTon, use the original b=0 and pre-normalize both acquisitions 
# with the b=0 of the MToff
mrconvert -coord 3 0:0 dwi_preproc_B1corr_upsampl.nii.gz b0_MT_off.nii.gz
mrcalc dwi_preproc_B1corr_upsampl.nii.gz b0_MT_off.nii.gz -div dwi_preproc_B1corr_upsampl_norm.nii.gz
#mrconvert -coord 3 1:30 dwi_preproc_B1corr_upsampl_MT_on.nii.gz - | mrcat  -axis 3 b0_MT_off.nii.gz - dwi_preproc_B1corr_upsampl_MT_on_b0_MT_off.nii.gz
mrcalc dwi_preproc_B1corr_upsampl_MT_on.nii.gz b0_MT_off.nii.gz -div dwi_preproc_B1corr_upsampl_MT_on_norm.nii.gz
#fslroi dwi_preproc_B1corr_upsampl_MT_on b1500_MT_on 1 30
#fslmerge -t dwi_preproc_B1corr_upsampl_MT_on_b0_MT_off b0_MT_off b1500_MT_on
# # rm dwi_preproc_B1corr_upsampl_MT_on.nii.gz
#rm b0_MT_off.nii.gz
#rm b1500_MT_on.nii.gz
#
#-----------------------------------------------------------------------------------------------------------------
# Eseguo correzione la bet
#bet <input> <output> [options] (smaller -f vals give larger brain boundaries, -R more robust bet)
echo -e "${BLU}Inizio creazione maschera bet ${RES}"
if [ ! -f "dwi_preproc_upsaml_bet.nii.gz" ]; then 
	start_bet=`date +%s`
	bet dwi_preproc_B1corr_upsampl.nii.gz dwi_preproc_upsaml_bet -f 0.2 -m -R -v
	end_bet=`date +%s`
	runtime_bet=$((end_bet-start_bet))
	echo -e "${GRN}Finished at " && date
	echo -e "The running time was $(($runtime_bet / 3600))hrs $((($runtime_bet / 60) % 60))min $(($runtime_bet % 60))sec ${RES}"
fi

echo -e "${BLU}Fine creazione maschera bet ${RES} \n"
#
#-----------------------------------------------------------------------------------------------------------------------------
#   Creating mean b=0 image
echo -e "${BLU}Creating upsampled b0mean image ${RES}"
dwiextract -bzero dwi_preproc_B1corr_upsampl.nii.gz b0_upsaml.nii.gz -fslgrad dwi_preproc.bvecs dwi_preproc.bvals 
fslmaths b0_upsaml.nii.gz -Tmean b0mean_upsaml.nii.gz
fslmaths b0mean_upsaml.nii.gz -mul dwi_preproc_upsaml_bet_mask.nii.gz b0mean_upsaml.nii.gz
echo -e "${BLU}Fineshed upsampled b0mean image ${RES}"
echo -e "${GRN}Finished at " && date
#
#-----------------------------------------------------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------------------------------------------------
# Generate 5tt image suitable for Anatomically-Constrained Tractography (ACT)
echo -e "${BLU} \n Starting 5ttgen with T1 brain of FreeSurfer ${RES}"
mkdir Tractography/5TT
#
# Converting the T1 brain found with FreeSurfer in nifty and creating the brain mask
echo -e "${BLU}Converting the T1 brain found with FreeSurfer in nifty and creating the brain mask ${RES}"
mkdir T1

#Use the anatomical from the 1st scan as the target
if [ ${patient_folder_name:0-1} = "r" ]; then
	anat_folder=${patient_folder_name::-1} #remove the 'r' last character to use the 1st scan anatomical
	echo "--Using $anat_folder as target anatomical---\n"

else
	anat_folder=$patient_folder_name
fi


#mri_convert $path_fs_subj/$patient_folder_name/anat/freeSurfer/mri/brain.mgz T1/T1_brain_mask_FS.nii.gz --out_orientation LAS
#mri_convert $path_fs_subj/$patient_folder_name/anat/freeSurfer/mri/orig_nu.mgz T1/T1_nucorr_FS.nii.gz --out_orientation LAS
#mri_convert $path_fs_subj/$patient_folder_name/anat/freeSurfer/mri/aparc+aseg.mgz T1/aparc+aseg.nii.gz --out_orientation LAS
echo "mri_convert $path_fs_subj/$anat_folder/anat/freeSurfer/mri/brain.mgz T1/T1_brain_mask_FS.nii.gz --out_orientation LAS\n"
mri_convert $path_fs_subj/$anat_folder/anat/freeSurfer/mri/brain.mgz T1/T1_brain_mask_FS.nii.gz --out_orientation LAS
mri_convert $path_fs_subj/$anat_folder/anat/freeSurfer/mri/orig_nu.mgz T1/T1_nucorr_FS.nii.gz --out_orientation LAS
mri_convert $path_fs_subj/$anat_folder/anat/freeSurfer/mri/aparc+aseg.mgz T1/aparc+aseg.nii.gz --out_orientation LAS

fslmaths T1/T1_brain_mask_FS.nii.gz -bin T1/T1_brain_mask_FS.nii.gz
fslmaths T1/T1_nucorr_FS.nii.gz -mul T1/T1_brain_mask_FS.nii.gz T1/T1_brain_FS.nii.gz
#
cp T1/T1_brain_FS.nii.gz Tractography/5TT/T1_brain_FS.nii.gz
cp T1/aparc+aseg.nii.gz Tractography/5TT/aparc+aseg.nii.gz
#
cd Tractography
#
# 5tt generation
# IF 5TTGEN STUCKS, SWITCH BETWEEN FSL AND FREESURFER ALGORITHM
echo -e "${YEL} 5ttgen ${RES}"
SGE_ROOT= 
5ttgen fsl 5TT/T1_brain_FS.nii.gz 5TT/5TT.nii.gz -premasked -nocrop -sgm_amyg_hipp -nocleanup
#5ttgen freesurfer 5TT/aparc+aseg.nii.gz 5TT/5TT.nii.gz -nocrop -sgm_amyg_hipp -nocleanup
SGE_ROOT=/opt/sge
#
# File for visualizing the 3 segmented tissues
echo -e "${YEL} 5tt2vis ${RES}"
5tt2vis 5TT/5TT.nii.gz 5TT/vis.mif
echo -e "${BLU}Fineshed 5ttgen ${RES}"
echo -e "${GRN}Finished at " && date
#
# visual inspection
# mrview 5TT/vis.mif
#
# Generate WM-GM interface if needed (not necessary if we use -seed_dinamic in tckgen)
echo -e "${YEL} 5tt2gmwmi ${RES}"
5tt2gmwmi 5TT/5TT.nii.gz 5TT/5TT_mask.mif
#
#-----------------------------------------------------------------------------------------------------------------------------
# Registering T1 brain of FreeSurfer with b0
echo -e "${BLU}Starting registration of T1 brain of FreeSurfer on b0 ${RES}"
#
mkdir T1_on_DTI
#
echo -e "${YEL} Converting WM found with 5TT to FSL format ${RES}"
#
mrconvert 5ttgen*/wm.mif 5TT/T1_wm.nii.gz
#
echo -e "${YEL} Preliminary FLIRT to find the approximate transformation dMRI to T1 ${RES}"
if [ ! -f "T1_on_DTI/tmp.mat" ]; then
	flirt -v -in ../b0mean_upsaml.nii.gz -ref 5TT/T1_brain_FS.nii.gz -dof 6 -omat T1_on_DTI/tmp.mat
fi
echo -e "${YEL} FLIRT to find the approximate transformation dMRI to T1 ${RES}"
if [ ! -f "T1_on_DTI/diff_to_structural_bbr.nii.gz" ]; then
	flirt -v -in ../b0mean_upsaml.nii.gz -ref 5TT/T1_brain_FS.nii.gz -dof 6 -cost bbr -wmseg 5TT/T1_wm.nii.gz -init T1_on_DTI/tmp.mat -omat T1_on_DTI/diff_to_structural_bbr.mat -out T1_on_DTI/diff_to_structural_bbr.nii.gz -schedule $FSLDIR/etc/flirtsch/bbr.sch
fi
echo -e "${YEL} Inverting the transformation ${RES}"
convert_xfm -omat T1_on_DTI/diff_to_structural_bbr_inverse.mat -inverse T1_on_DTI/diff_to_structural_bbr.mat
echo -e "${YEL} Applying the inverse transformation to T1 ${RES}"
flirt -v -applyxfm -init T1_on_DTI/diff_to_structural_bbr_inverse.mat -in 5TT/T1_brain_FS.nii.gz -ref ../b0mean_upsaml.nii.gz -out T1_on_DTI/T1_to_b0mean_FSLbbr.nii.gz
echo -e "${YEL} Applying the inverse transformation to T1 WM ${RES}"
flirt -v -applyxfm -init T1_on_DTI/diff_to_structural_bbr_inverse.mat -in 5TT/T1_wm.nii.gz -ref ../b0mean_upsaml.nii.gz -out T1_on_DTI/WM_to_b0.nii.gz
echo -e "${YEL} Masking T1 WM on b0 ${RES}"
fslmaths T1_on_DTI/WM_to_b0.nii.gz -bin T1_on_DTI/WM_mask_to_b0.nii.gz
fslmaths T1_on_DTI/WM_mask_to_b0.nii.gz -mul ../dwi_preproc_upsaml_bet_mask.nii.gz T1_on_DTI/WM_mask_to_b0.nii.gz
fslmaths T1_on_DTI/WM_to_b0.nii.gz -bin T1_on_DTI/WM_to_b0_bin.nii.gz
#
# visual inspection
#fsleyes 5TT/T1_brain_FS.nii.gz T1_on_DTI/diff_to_structural_bbr.nii.gz
#fsleyes ../b0mean_upsaml.nii.gz T1_on_DTI/T1_to_b0mean_FSLbbr.nii.gz T1_on_DTI/WM_mask_to_b0.nii.gz
#
echo -e "${YEL} Converting transformations in MRtrix format ${RES}"
transformconvert T1_on_DTI/diff_to_structural_bbr.mat ../b0mean_upsaml.nii.gz 5TT/T1_brain_FS.nii.gz flirt_import 5TT/diff_to_structural_bbr-mrtrixformat.txt
echo -e "${YEL} Applying transformations in MRtrix format to 5TT file ${RES}"
mrtransform 5TT/5TT.nii.gz 5TT/r5TT.nii.gz -linear 5TT/diff_to_structural_bbr-mrtrixformat.txt -inverse
echo -e "${YEL} Applying transformations in MRtrix format to 5TT_mask file ${RES}"
mrtransform 5TT/5TT_mask.mif 5TT/r5TT_mask.nii.gz -linear 5TT/diff_to_structural_bbr-mrtrixformat.txt -inverse
#
echo -e "${BLU}Fineshed T1 registration on b0 ${RES}"
echo -e "${GRN}Finished at " && date
#
#-----------------------------------------------------------------------------------------------------------------------------
# 
# Computing the response functions with multi shell multi tissue 
echo -e "${BLU}Starting computation of response functions with multi shell multi tissue ${RES}"
#
mkdir CSD
#
dwi2response dhollander ../dwi_preproc_B1corr_upsampl.nii.gz CSD/response_wm.txt CSD/response_gm.txt CSD/response_csf.txt -fslgrad ../dwi_preproc.bvecs ../dwi_preproc.bvals -mask ../dwi_preproc_upsaml_bet_mask.nii.gz -voxels CSD/RF_voxels.mif
echo -e "${BLU}Fineshed computation of response functions ${RES}"
echo -e "${GRN}Finished at " && date
#
#-----------------------------------------------------------------------------------------------------------------------------
# Computing the FOD with multi shells multi tissue 
echo -e "${BLU}Starting FOD computation with multi shells multi tissue ${RES}"
# 
mkdir FOD
mrconvert ../dwi_preproc_B1corr_upsampl.nii.gz ../dwi.mif -fslgrad ../dwi_preproc.bvecs ../dwi_preproc.bvals
ss3t_csd_beta1 ../dwi.mif CSD/response_wm.txt FOD/WM_FODs.nii.gz CSD/response_gm.txt FOD/GM.nii.gz CSD/response_csf.txt FOD/CSF.nii.gz -mask ../dwi_preproc_upsaml_bet_mask.nii.gz
mtnormalise FOD/WM_FODs.nii.gz FOD/WM_FODs_norm.nii.gz FOD/GM.nii.gz FOD/GM_norm.nii.gz FOD/CSF.nii.gz FOD/CSF_norm.nii.gz -mask ../dwi_preproc_upsaml_bet_mask.nii.gz -check_norm FOD/mtnormalise_norm.nii.gz -check_mask FOD/mtnormalise_mask.nii.gz
#
# visual inspection
# mrview ../b0mean_upsaml.nii.gz -odf.load_sh FOD/WM_FODs.mif
#
echo -e "${BLU}Fineshed FOD computation ${RES}"
echo -e "${GRN}Finished at " && date
#
#-----------------------------------------------------------------------------------------------------------------------------
# Generating tractography
echo -e "${BLU}Starting tractography generation with ACT, iFOD2 algorithm and 3M streamlines ${RES}"
tckgen FOD/WM_FODs_norm.nii.gz iFOD2_ACT_3M_hcp.tck -act 5TT/r5TT.nii.gz -backtrack -crop_at_gmwmi -seed_gmwmi 5TT/r5TT_mask.nii.gz -select 3M -maxlength 250 -minlength 5 -cutoff 0.06
# deterministic
#tckgen -algorithm SD_Stream FOD/WM_FODs.mif SD_STREAM_ACT_3M.tck -seed_image T1_on_DTI/WM_to_b0_bin.nii.gz -mask T1_on_DTI/WM_to_b0_bin.nii.gz -select 3M -maxlength 250 -minlength 20 -angle 60 -step 0.25
#
echo -e "${YEL} Extracting only 500k streamlines to be able to visualize them ${RES}"
# tckedit iFOD2_ACT_3M_hcp.tck iFOD2_ACT_500k.tck -number 500k
#
# visual inspection
# mrview ../b0mean_upsaml.nii.gz -tractography.load iFOD2_ACT_500k.tck
#
echo -e "${BLU}Fineshed tractography generation ${RES}"
echo -e "${GRN}Finished at " && date
#
cd ..
#
#-----------------------------------------------------------------------------------------------------------------------------
# Creating the connectome with the number of streamlines 
#
#
echo -e "\n ${BLU} Converting aparc+aseg.mgz in .nii ${RES}"
#mri_convert $path_fs_subj/$patient_folder_name/anat/freeSurfer/mri/aparc+aseg.mgz T1/aparc+aseg.nii.gz --out_orientation LAS
#mri_convert $path_fs_subj/$patient_folder_name/anat/freeSurfer/mri/aparc.a2009s+aseg.mgz T1/aparc.a2009s+aseg.nii.gz --out_orientation LAS
#mri_convert $path_fs_subj/$patient_folder_name/anat/freeSurfer/mri/brainstemSsLabels.v12.FSvoxelSpace.mgz T1/T1_brain_FS_bstem.nii.gz --out_orientation LAS
mri_convert $path_fs_subj/$anat_folder/anat/freeSurfer/mri/aparc+aseg.mgz T1/aparc+aseg.nii.gz --out_orientation LAS
mri_convert $path_fs_subj/$anat_folder/anat/freeSurfer/mri/aparc.a2009s+aseg.mgz T1/aparc.a2009s+aseg.nii.gz --out_orientation LAS
mri_convert $path_fs_subj/$anat_folder/anat/freeSurfer/mri/brainstemSsLabels.v12.FSvoxelSpace.mgz T1/T1_brain_FS_bstem.nii.gz --out_orientation LAS

#
echo -e "\n ${BLU} Replacing the bstem with medulla in the segmentation aparc+aseg \n ${RES}"
fslmaths T1/aparc+aseg.nii.gz -uthr 16 -thr 16 -add T1/T1_brain_FS_bstem.nii.gz -binv T1/T1_brain_FS_bstem_binv.nii.gz
fslmaths T1/aparc+aseg.nii.gz -mul T1/T1_brain_FS_bstem_binv.nii.gz T1/aparc+aseg_FS_nobstem.nii.gz
fslmaths T1/T1_brain_FS_bstem.nii.gz -uthr 175 -thr 175 -bin T1/T1_brain_FS_medulla.nii.gz
fslmaths T1/T1_brain_FS_medulla.nii.gz -mul 16 T1/T1_brain_FS_medulla.nii.gz
fslmaths T1/aparc+aseg_FS_nobstem.nii.gz -add T1/T1_brain_FS_medulla.nii.gz T1/aparc+aseg_medulla.nii.gz
#
echo -e "\n ${BLU} Replacing the bstem with medulla in the segmentation aparc.a2009s+aseg \n ${RES}"
fslmaths T1/aparc.a2009s+aseg.nii.gz -uthr 16 -thr 16 -add T1/T1_brain_FS_bstem.nii.gz  -binv T1/T1_brain_FS_bstem_binv.nii.gz
fslmaths T1/aparc.a2009s+aseg.nii.gz -mul T1/T1_brain_FS_bstem_binv.nii.gz T1/aparc.a2009s+aseg_FS_nobstem.nii.gz
fslmaths T1/aparc.a2009s+aseg_FS_nobstem.nii.gz -add T1/T1_brain_FS_medulla.nii.gz T1/aparc.a2009s+aseg_medulla.nii.gz
#
#
echo -e "${BLU}Starting standard connectome creation ${RES}"
#
mkdir Connectome
#
echo -e "${YEL} Converting parcellation using MRtrix lookup table ${RES}"

# ENABLE FOLLOWING LINE IF BRAINSTEM SEGMENTATION HAS BEEN RUN
labelconvert T1/aparc+aseg_medulla.nii.gz $FREESURFER_HOME/FreeSurferColorLUT.txt $path_fs_file/fs_default_Bstem.txt T1/nodes.nii.gz
echo labelconvert T1/aparc+aseg_medulla.nii.gz $FREESURFER_HOME/FreeSurferColorLUT.txt $path_fs_file/fs_default_Bstem.txt T1/nodes.nii.gz


# ENABLE FOLLOWING LINE IF BRAINSTEM SEGMENTATION HAS NOT BEEN RUN
# labelconvert T1/aparc+aseg.nii.gz $FREESURFER_HOME/FreeSurferColorLUT.txt $path_fs_file/fs_default_Bstem.txt T1/nodes.nii.gz

labelconvert T1/aparc.a2009s+aseg_medulla.nii.gz $FREESURFER_HOME/FreeSurferColorLUT.txt $path_fs_file/fs_a2009s_Bstem.txt T1/nodes_2009.nii.gz
#
echo -e "${YEL} Improve subcortical GM parcellation using FIRST ${RES}"
# TEMPORARILY SET SUN GRID ENGINE (SGE_ROOT) ENV VARIABLE EMPTY TO OVERCOME LEBLSGMFIX HANGING
SGE_ROOT= 
labelsgmfix T1/nodes.nii.gz T1/T1_brain_FS.nii.gz $path_fs_file/fs_default_Bstem.txt T1/nodes_fixSGM.nii.gz -sgm_amyg_hipp -premasked -nocleanup
labelsgmfix T1/nodes_2009.nii.gz T1/T1_brain_FS.nii.gz $path_fs_file/fs_a2009s_Bstem.txt T1/nodes_2009_fixSGM.nii.gz -sgm_amyg_hipp -premasked -nocleanup
# RESTORE SGE_ROOT TO CURRENT VALUE
SGE_ROOT=/opt/sge
#
#
echo -e "${YEL} Registering segmentation using the previous matrix ${RES}"
flirt -v -interp nearestneighbour -applyxfm -init Tractography/T1_on_DTI/diff_to_structural_bbr_inverse.mat -in T1/nodes_fixSGM.nii.gz -ref b0mean_upsaml.nii.gz -out Connectome/nodes_fixSGM_tob0.nii.gz
flirt -v -interp nearestneighbour -applyxfm -init Tractography/T1_on_DTI/diff_to_structural_bbr_inverse.mat -in T1/nodes_2009_fixSGM.nii.gz -ref b0mean_upsaml.nii.gz -out Connectome/nodes_2009_fixSGM_tob0.nii.gz
flirt -v -interp nearestneighbour -applyxfm -init Tractography/T1_on_DTI/diff_to_structural_bbr_inverse.mat -in T1/aparc+aseg_medulla.nii.gz -ref b0mean_upsaml.nii.gz -out Connectome/aparc+aseg_medulla_tob0.nii.gz
flirt -v -interp nearestneighbour -applyxfm -init Tractography/T1_on_DTI/diff_to_structural_bbr_inverse.mat -in T1/aparc.a2009s+aseg_medulla.nii.gz -ref b0mean_upsaml.nii.gz -out Connectome/aparc.a2009s+aseg_medulla_tob0.nii.gz
#
echo -e "${YEL} Creating connectome ${RES}"
tck2connectome -assignment_radial_search 2 Tractography/iFOD2_ACT_3M_hcp.tck -out_assignments Connectome/3M_iFOD2_ACT_assignment.txt Connectome/nodes_fixSGM_tob0.nii.gz Connectome/iFOD2_ACT_3M_connectome.csv -symmetric
tck2connectome -assignment_radial_search 2 Tractography/iFOD2_ACT_3M_hcp.tck -out_assignments Connectome/3M_iFOD2_ACT_assignment_2009.txt Connectome/nodes_2009_fixSGM_tob0.nii.gz Connectome/iFOD2_ACT_3M_connectome_2009.csv -symmetric
#
# Filterining non-connecting
connectome2tck Tractography/iFOD2_ACT_3M_hcp.tck Connectome/3M_iFOD2_ACT_assignment.txt Tractography/iFOD2_ACT_3M_hcp_connecting.tck -files single -keep_self -nodes 1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83,84,85 -exclusive
#
echo -e "${BLU}Fineshed standard connectome creation ${RES}"
echo -e "${GRN}Finished at " && date
#
#
#-----------------------------------------------------------------------------------------------------------------------------
#
#
cd $rootDIR
#
#
#
done
#
#
end_all=`date +%s`
runtime=$((end_all-start_all))
echo -e "${VIO}Finished at " && date
echo -e "TOTAL running time was $(($runtime / 3600))hrs $((($runtime / 60) % 60))min $(($runtime % 60))sec ${RES}"
#
echo -e "\n\n ${REDbg} Fine dello script. Ora e' possibile chiudere il terminale. Grazie! ${RES} \n"
