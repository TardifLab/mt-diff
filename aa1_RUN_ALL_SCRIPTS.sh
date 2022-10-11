#!/bin/bash

# FreeSurfer segmentation of brainstem structures, denoise, topup, eddy and eventually debias
# The FreeSurfer script /data_/tardiflab/01_programs/freesurfer_v7/bin/run_SegmentSubject.sh has been modified to overcome MCR random error, MCR_CAHCE_ROOT variable has been set in $HOME/MCR_${RANDOMNUMBER}/ folder
sh aa2_preprocessing.sh

# dwi upsampling, registrations, diffusion model fitting and tractography
sh bb1_Script_05_iFOD_ss3t_tractography_upsampling.sh

# confidence map creation (for COMMIT)
sh cc1_confidence_map.sh

# enable python 3 virtual environment with COMMIT 1.6 installed
source /data_/tardiflab/pbontempi/scripts/dd1_enable_python_venv.sh

# run COMMIT on MT off data
python3 dd2_COMMIT_MToff.py

# run COMMIT on MT on data
python3 dd3_COMMIT_MTon.py

# build COMMIT connectomes on MToff data
python3 ee1_connectomes_MToff.py

# build COMMIT connectomes on MTon data
python3 ee2_connectomes_MTon.py

# calculate MTR connectome
matlab -nodisplay -nosplash -nodesktop -r "run('ff1_MTRconnectome.m');exit;"

# perform tractometry and prepare files to color bundles according MTR values evaluated with COMMIT or tractometry
python3 gg1_MTR_bundle.py

# perform tractometry and prepare files to color bundles according MTR values evaluated with COMMIT or tractometry
python3 gg2_MTRdw_bundle.py

#disable python 3 virtual environment
source /data_/tardiflab/pbontempi/scripts/hh1_disable_python_venv.sh


