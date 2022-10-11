#!/bin/sh
#
#$ -cwd
#$ -o logs/out-hc18r.txt
#$ -e logs/err-hc18r.txt
#$ -m e
#$ -pe all.pe 8
#$ -l h_vmem=10G
#$ -V

#source /data_/tardiflab/pbontempi/scripts/init.sh
aa2_preprocessing_samebias.sh hc18r

bb1_Script_05_iFOD_ss3t_tractography_upsampling_as_ISMRM.sh hc18r
cc1_confidence_map.sh hc18r

source /data_/tardiflab/pbontempi/scripts/dd1_enable_python_venv.sh
python3 dd2_COMMIT_MToff_as_ISMRM.py hc18r
python3 dd3_COMMIT_MTon_as_ISMRM.py hc18r

python3 ee1_connectomes_MToff.py hc18r
python3 ee2_connectomes_MTon.py hc18r

python3 ff1_MTRconnectome.py hc18r

## These can be run in parallel
python3 gg1_MTR_bundle.py hc18r
python3 gg2_MTRdw_bundle.py hc18r

