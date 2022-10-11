#!/bin/bash
program_path='/data_/tardiflab/01_programs/'
#
cd $program_path
#
mkdir COMMIT_MTR_env
python3 -m venv COMMIT_MTR_env
source /data_/tardiflab/01_programs/COMMIT_MTR_env/bin/activate
cd COMMIT_MTR_env
pip install wheel
pip install packaging
pip install numpy==1.19.5
pip install dmri-commit
